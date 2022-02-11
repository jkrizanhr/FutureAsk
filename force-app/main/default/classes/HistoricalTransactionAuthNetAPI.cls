public class HistoricalTransactionAuthNetAPI implements HistoricalTransactionAPI {
  private String mode;
  private HT_Auth_Net_Setting__mdt authNetSettings = [
    SELECT Login_ID__c, Transaction_Key__c, Account_Name__c, Region_Category__c
    FROM HT_Auth_Net_Setting__mdt
    WHERE DeveloperName = 'Sandbox'
  ];
  private AuthorizeNetService authNetService;

  public HistoricalTransactionAuthNetApi() {
    this.authNetService = new AuthorizeNetService(
      this.authNetSettings.Login_ID__c,
      this.authNetSettings.Transaction_Key__c,
      this.mode == 'Sandbox'
    );
  }

  public void setMode(String mode) {
    this.mode = mode;
    authNetSettings = [
      SELECT
        Login_ID__c,
        Transaction_Key__c,
        Account_Name__c,
        Region_Category__c
      FROM HT_Auth_Net_Setting__mdt
      WHERE DeveloperName = :mode
    ];
    this.authNetService = new AuthorizeNetService(
      this.authNetSettings.Login_ID__c,
      this.authNetSettings.Transaction_Key__c,
      this.mode == 'Sandbox'
    );
  }

  public Boolean authenticate() {
    return true;
  }

  public HistoricalTransactionModel.TransactionsResponse getTransactions(
    Datetime startTime,
    Datetime endTime,
    String nextId,
    Integer count
  ) {
    AuthorizeNetModels.getSettledBatchListResponse batchListRes = this
      .authNetService.getSettledBatchList(startTime, endTime, false, null);
    if (batchListRes.messages.resultCode == 'Error') {
      return new HistoricalTransactionModel.TransactionsResponse(
        null,
        null,
        true,
        batchListRes.messages.message.text
      );
    }

    List<Historical_Transaction__c> transactions = new List<Historical_Transaction__c>();
    try {
      if (batchListRes.batchList != null) {
        for (
          AuthorizeNetModels.batchDetailsType batch : batchListRes.batchList
        ) {
          List<Historical_Transaction__c> batchTransactions = getTransactionList(
            batch.batchId
          );
          for (Historical_Transaction__c ht : batchTransactions) {
            ht.Settlement_Date__c = (Datetime) JSON.deserialize(
              '"' +
              batch.settlementTimeUTC +
              '"',
              Datetime.class
            );
            ht.Payment_Processor_Account__c = this
              .authNetSettings.Account_Name__c;
          }
          transactions.addAll(batchTransactions);
        }
      }
    } catch (Exception ex) {
      return new HistoricalTransactionModel.TransactionsResponse(
        null,
        null,
        true,
        ex.getMessage()
      );
    }
    return new HistoricalTransactionModel.TransactionsResponse(
      transactions,
      null
    );
  }

  @TestVisible
  private List<Historical_Transaction__c> getTransactionList(String batchId) {
    AuthorizeNetModels.getTransactionListResponse res = this
      .authNetService.getTransactionList(batchId, null);
    if (res.messages.resultCode == 'Error') {
      throw new HistoricalTransactionException(res.messages.message.text);
    }

    List<Historical_Transaction__c> transactions = new List<Historical_Transaction__c>();
    if (res.transactions != null) {
      for (AuthorizeNetModels.transactionSummaryType ts : res.transactions) {
        Historical_Transaction__c ht = new Historical_Transaction__c();
        ht.Transaction_Id__c = ts.transId;
        ht.Amount__c = ts.settleAmount;
        ht.First_Name__c = ts.firstName;
        ht.Last_Name__c = ts.lastName;
        ht.Status__c = ts.transactionStatus;
        ht.Payment_Type__c = ts.accountType;
        ht.Credit_Card_Last_4__c = String.isNotBlank(ts.accountNumber)
          ? ts.accountNumber.right(4)
          : null;
        ht.Create_Time__c = (Datetime) JSON.deserialize(
          '"' +
          ts.submitTimeUTC +
          '"',
          Datetime.class
        );
        ht.Transaction_Type__c = 'Payment';
        ht.Type__c = 'Authorize.net';

        if (ts.subscription != null) {
          ht.Transaction_Type__c = 'Recurring Payment';
          ht.Subscription_Id__c = ts.subscription.id;
          ht.Payment_Number__c = ts.subscription.payNum;
        }

        if (ts.profile != null) {
          ht.Customer_Id__c = ts.profile.customerProfileId;
          ht.Payment_Profile_Id__c = ts.profile.customerPaymentProfileId;
        }
        ht.Region_Category__c = this.authNetSettings.Region_Category__c;

        transactions.add(ht);
      }
    }
    return transactions;
  }

  public Historical_Transaction__c completeTransactionDetails(
    Historical_Transaction__c ht
  ) {
    AuthorizeNetModels.getTransactionDetailsResponse res = this
      .authNetService.getTransactionDetails(ht.Transaction_ID__c, null);
    if (res.messages.resultCode == 'Error') {
      throw new HistoricalTransactionException(res.messages.message.text);
    }

    if (res.trans.billTo != null) {
      if (String.isNotEmpty(res.trans.billTo.address))
        ht.Billing_Street__c = res.trans.billTo.address;
      if (String.isNotEmpty(res.trans.billTo.city))
        ht.Billing_City__c = res.trans.billTo.city;
      if (String.isNotEmpty(res.trans.billTo.state))
        ht.Billing_State_Province__c = res.trans.billTo.state;
      if (String.isNotEmpty(res.trans.billTo.zip))
        ht.Billing_Postal_Code__c = res.trans.billTo.zip;
      if (String.isNotEmpty(res.trans.billTo.country))
        ht.Billing_Country__c = res.trans.billTo.country;
      if (String.isNotEmpty(res.trans.billTo.email))
        ht.Email__c = res.trans.billTo.email;
      if (String.isNotEmpty(res.trans.billTo.phoneNumber))
        ht.Phone__c = res.trans.billTo.phoneNumber;
    }

    if (res.trans.customer != null && ht.Email__c == null) {
      if (String.isNotEmpty(res.trans.customer.email))
        ht.Email__c = res.trans.customer.email;
    }

    if (res.trans.transactionStatus != null) {
      ht.Status__c = res.trans.transactionStatus;
    }

    if (res.trans.payment != null) {
      if (res.trans.payment.creditCard != null) {
        if (res.trans.payment.creditCard.cardType != null) {
          ht.Credit_Card_Type__c = res.trans.payment.creditCard.cardType;
        }
      }
    }

    return ht;
  }
}