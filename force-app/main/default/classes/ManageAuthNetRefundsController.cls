public without sharing class ManageAuthNetRefundsController {
  static final String RECORD_TYPE = 'Opportunity';

  /* Kyle - ManageAuthNetRefunds is the main aura component. This is what displays on the Opp page in the UI. Note: The component will not show up if the transaction Id is null on the opp. ManageAuthNetRefundModals controls all the actions and the Apex methods are called from the helper of this component. When a user clicks on a button in the main component it passes a value which is how the child modal component knows which modal to display. Currently there's only one option for full refund but I think Greg said something about partial refunds eventually? */
  @AuraEnabled
  public static TransactionInfo fetchData(Id recordId) {
    Opportunity opp = [
      SELECT Id, Transaction_Id__c
      FROM Opportunity
      WHERE Id = :recordId
    ];
    AuthorizeNetModels.getTransactionDetailsResponse transactionDetailsResponse = getTransactionDetails(
      opp
    );
    return new TransactionInfo(recordId, transactionDetailsResponse);
  }

  /**
   * This is a helper function that makes an API call to Authorize.net to get transaction details.
   *
   * @param recordId the Id of the SObject
   *
   * @return the response object defined by AuthorizeNetModels
   */
  public static AuthorizeNetModels.getTransactionDetailsResponse getTransactionDetails(
    Opportunity opp
  ) {
    AuthorizeNetService authNetService = ManageAuthNetService.getAuthorizeNetService(
      opp.Id,
      RECORD_TYPE
    );
    AuthorizeNetModels.getTransactionDetailsResponse transactionDetailsResponse = authNetService.getTransactionDetails(
      opp.Transaction_Id__c,
      null
    );
    if (
      !ManageAuthNetService.isResponseValid(
        (AuthorizeNetModels.ANetApiResponse) transactionDetailsResponse
      )
    ) {
      throw new ManageAuthNetService.AuthNetServiceException(
        transactionDetailsResponse.messages.message.text
      );
    }
    return transactionDetailsResponse;
  }

  /**
   * For Credit Card payments, refund information is sufficiently stored on the Opportunity, but for Bank Account transactions, we must requery the transaction for additional info.
   *
   * @param opp Opportunity to refund
   * @param authNetService this helper method is called from within a refund method, so the authNetService should already exist
   *
   * @return payment AuthorizeNetModels.paymentType object
   */
  public static AuthorizeNetModels.paymentType getPaymentType(
    Opportunity opp,
    AuthorizeNetService authNetService
  ) {
    AuthorizeNetModels.paymentType payment = new AuthorizeNetModels.paymentType();
    if (opp.Payment_Method__c == 'Credit Card') {
      /**
       * From the authorize.net docs:
       *
       * When issuing a credit card refund, the request must include either a full card number and expiration date, or the original transaction ID (transId) and last 4 digits of the card number. If you don't have the last 4 digits, you can use getTransactionDetails to retrieve the payment information needed to issue a refund.
       *
       */
      payment.creditCard = new AuthorizeNetModels.creditCardType();
      payment.creditCard.cardNumber = opp.Credit_Card_Full_Last_4__c;
      payment.creditCard.expirationDate = opp.Credit_Card_Exp_Date__c != null
        ? opp.Credit_Card_Exp_Date__c
        : 'XXXX';
    } else if (opp.Payment_Method__c == 'Bank Account') {
      AuthorizeNetModels.getTransactionDetailsResponse transactionDetailsResponse = getTransactionDetails(
        opp
      );
      payment.bankAccount = new AuthorizeNetModels.bankAccountType();
      payment.bankAccount = transactionDetailsResponse.trans.payment.bankAccount;
      // PPD is required for refunds. See https://developer.authorize.net/api/reference/features/echeck.html
      payment.bankAccount.echeckType = 'PPD';
      payment.bankAccount.accountType = opp.Bank_Account_Type__c;
    } else {
      throw new ManageAuthNetService.AuthNetServiceException(
        'Invalid payment type on opportunity: ' + opp.Payment_Method__c
      );
    }
    return payment;
  }

  /**
   * This is the main method that issues a refund against the Authorize API.
   *
   * @param recordId Opportunity Id from the UI
   * @param transInfo metadata retrieved from the UI with fetchData. Serialized String.
   *
   * @return the Id, as a String, of new Opportunity
   */
  @AuraEnabled
  public static String issueFullRefund(Id recordId, String transInfo) {
    /* Kyle - This transaction needs to be refunded. And I'll need the new opp Id passed back.
     Greg's Notes: Refund the transaction in Auth.net. Mark current opp as adjustment and create new opp that reverses out old opp. Connect via adjustment opportunity. Redirect user to new adjustment opp after success. */
    TransactionInfo ti = (TransactionInfo) JSON.deserialize(
      transInfo,
      TransactionInfo.class
    );
    AuthorizeNetService authNetService = ManageAuthNetService.getAuthorizeNetService(
      recordId,
      RECORD_TYPE
    );

    //Get payment information off of the opportunity
    Opportunity opp = [
      SELECT
        Id,
        Transaction_Id__c,
        Payment_Method__c,
        Credit_Card_Last_Four__c,
        Credit_Card_Full_Last_4__c,
        Credit_Card_Exp_Date__c,
        Bank_Account_Type__c,
        Original_Amount__c
      FROM Opportunity
      WHERE Id = :recordId
    ];

    if (opp.Original_Amount__c != ti.amount) {
      throw new ManageAuthNetService.AuthNetServiceException(
        'Original amount does not match settled amount in Authorize.net. Please contact an administrator.'
      );
    }
    AuthorizeNetModels.transactionRequestType refundRequest = new AuthorizeNetModels.transactionRequestType();
    refundRequest.transactionType = 'refundTransaction';
    refundRequest.payment = getPaymentType(opp, authNetService);
    refundRequest.refTransId = opp.Transaction_Id__c;
    refundRequest.refTransId = ti.id;
    refundRequest.amount = opp.Original_Amount__c;
    AuthorizeNetModels.createTransactionResponse refundResponse = authNetService.createTransaction(
      refundRequest,
      null
    );
    if (
      ManageAuthNetService.isResponseValid(
        (AuthorizeNetModels.ANetApiResponse) refundResponse
      )
    ) {
      //We unit test this, so if running a test, return
      if (Test.isRunningTest()) {
        return null;
      } else {
        return createAdjustmentOpportunity(
          recordId,
          ti,
          refundResponse.transactionResponse.transId
        );
      }
    } else {
      throw new ManageAuthNetService.AuthNetServiceException(
        refundResponse.messages.message.text
      );
    }
  }

  /**
   * Handle the SF object side of the refund. Copies Opportunity and Allocations, reverses the amounts, and saves.
   *
   * @param recordId Id of the Opportunity
   * @param ti the TransactionInfo object
   * @param newTransId the transaction from the refund response to set on the new Opportunity
   *
   * @return new Opportunity Id as an Id
   */
  @TestVisible
  private static Id createAdjustmentOpportunity(
    Id recordId,
    TransactionInfo ti,
    String newTransId
  ) {
    Opportunity opp = [
      SELECT
        AccountId,
        Name,
        RecordTypeId,
        npsp__Primary_Contact__c,
        Amount,
        CloseDate,
        Transaction_Id__c,
        Payment_Method__c,
        Credit_Card_Type__c,
        Credit_Card_Exp_Date__c,
        Credit_Card_Last_Four__c,
        Credit_Card_No_Hash__c,
        Bank_Account_Type__c,
        CampaignId,
        Original_Amount__c,
        Original_Currency__c,
        Language_Preference__c,
        Receipt_Type__c,
        Utm_Campaign__c,
        npe03__Recurring_Donation__c,
        (
          SELECT
            npsp__General_Accounting_Unit__c,
            npsp__Amount__c,
            Original_Amount__c,
            Original_Currency__c,
            Campaign__c,
            Fund_GL_Account__c
          FROM npsp__Allocations__r
        )
      FROM Opportunity
      WHERE Id = :recordId
    ];
    Opportunity adjustmentOpp = opp.clone(false, true, false, false);

    //Make changes to new opp
    adjustmentOpp.StageName = 'Adjustment';
    adjustmentOpp.Amount = -1 * adjustmentOpp.Amount;
    adjustmentOpp.Original_Amount__c = -1 * adjustmentOpp.Original_Amount__c;
    adjustmentOpp.Adjusted_Opportunity__c = opp.Id;
    adjustmentOpp.Transaction_Id__c = newTransId;
    insert adjustmentOpp;

    delete [
      SELECT Id
      FROM npsp__Allocation__c
      WHERE npsp__Opportunity__c = :adjustmentOpp.Id
    ];

    //Take care of allocations
    for (npsp__Allocation__c allocation : adjustmentOpp.npsp__Allocations__r) {
      allocation.npsp__Amount__c = -1 * allocation.npsp__Amount__c;
      allocation.Original_Amount__c = -1 * allocation.Original_Amount__c;
      allocation.Id = null;
      allocation.npsp__Opportunity__c = adjustmentOpp.Id;
    }
    insert adjustmentOpp.npsp__Allocations__r;

    //Update original opp
    opp.StageName = 'Adjustment';
    update opp;

    return adjustmentOpp.Id;
  }

  public class TransactionInfo {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public Double amount;
    @AuraEnabled
    public Id originalOpp;
    @AuraEnabled
    public Id adjustedOpp;

    public TransactionInfo(
      Id recordId,
      AuthorizeNetModels.getTransactionDetailsResponse transactionDetailsResponse
    ) {
      Opportunity opp = [
        SELECT Id, Adjusted_Opportunity__c, (SELECT Id FROM Opportunities__r)
        FROM Opportunity
        WHERE Id = :recordId
      ];
      this.id = transactionDetailsResponse.trans.transId;
      this.status = transactionDetailsResponse.trans.transactionStatus;
      this.amount = transactionDetailsResponse.trans.settleAmount;
      if (opp.Opportunities__r.size() > 0) {
        this.adjustedOpp = opp.Opportunities__r[0].Id;
      }
      this.originalOpp = opp.Adjusted_Opportunity__c;
    }
  }
}