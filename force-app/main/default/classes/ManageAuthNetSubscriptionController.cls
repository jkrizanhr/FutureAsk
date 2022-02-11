public without sharing class ManageAuthNetSubscriptionController {
  static final String RECORD_TYPE = 'npe03__Recurring_Donation__c';
  public enum PaymentType {
    CREDIT_CARD,
    BANK_ACCOUNT
  }

  public class AuthNetSubscriptionCancelledException extends Exception {
  }

  /* Kyle - ManageAuthNetSubscription is the main aura component. This is what displays on the RD page in the UI. ManageAuthNetSubscriptionModals controls all the actions and the Apex methods are called from the helper of this component. When a user clicks on a button in the main component it passes a value which is how the child modal component knows which modal to display. */

  @AuraEnabled
  public static SubscriptionInfo fetchData(Id recordId) {
    npe03__Recurring_Donation__c rd = [
      SELECT Id, Subscription_Id__c
      FROM npe03__Recurring_Donation__c Id
      WHERE id = :recordId
    ];
    AuthorizeNetModels.ARBGetSubscriptionResponse subscriptionResponse = getSubscription(rd, null);
    return new SubscriptionInfo(recordId, subscriptionResponse);
  }

  /**
   * This is a helper function that makes an API call to Authorize.net to get subscription details.
   *
   * @param recordId the Id of the Recurring Donation
   * @param existingAuthNetService existing authNetService -- if null, a new one will be created
   *
   * @return the response object defined by AuthorizeNetModels
   */
  public static AuthorizeNetModels.ARBGetSubscriptionResponse getSubscription(
    npe03__Recurring_Donation__c rd,
    AuthorizeNetService existingAuthNetService
  ) {
    AuthorizeNetService authNetService = existingAuthNetService != null
      ? existingAuthNetService
      : ManageAuthNetService.getAuthorizeNetService(rd.Id, RECORD_TYPE);
    AuthorizeNetModels.ARBGetSubscriptionResponse subscriptionResponse = authNetService.getSubscription(
      rd.Subscription_Id__c,
      null
    );
    if (
      !ManageAuthNetService.isResponseValid(
        (AuthorizeNetModels.ANetApiResponse) subscriptionResponse
      )
    ) {
      throw new ManageAuthNetService.AuthNetServiceException(
        subscriptionResponse.messages.message.text
      );
    }
    return subscriptionResponse;
  }

  public static AuthorizeNetModels.ARBCancelSubscriptionResponse cancelSubscription(
    npe03__Recurring_Donation__c rd,
    AuthorizeNetService existingAuthNetService
  ) {
    AuthorizeNetService authNetService = existingAuthNetService != null
      ? existingAuthNetService
      : ManageAuthNetService.getAuthorizeNetService(rd.Id, RECORD_TYPE);
    AuthorizeNetModels.ARBCancelSubscriptionResponse cancelSubscriptionResponse = authNetService.cancelSubscription(
      rd.Subscription_Id__c,
      null
    );
    if (
      cancelSubscriptionResponse != null &&
      cancelSubscriptionResponse.messages != null &&
      cancelSubscriptionResponse.messages.message != null &&
      cancelSubscriptionResponse.messages.message.code == 'I00002'
    ) {
      throw new AuthNetSubscriptionCancelledException(
        cancelSubscriptionResponse.messages.message.text
      );
    } else if (
      !ManageAuthNetService.isResponseValid(
        (AuthorizeNetModels.ANetApiResponse) cancelSubscriptionResponse
      )
    ) {
      throw new ManageAuthNetService.AuthNetServiceException(
        cancelSubscriptionResponse.messages.message.text
      );
    }
    return cancelSubscriptionResponse;
  }

  @AuraEnabled
  public static SubscriptionInfo updateAuthNetSubscription(Id recordId, String subscription) {
    // Setup - requery. Do not trust client-provided info.
    npe03__Recurring_Donation__c rd = [
      SELECT Id, Subscription_Id__c
      FROM npe03__Recurring_Donation__c Id
      WHERE id = :recordId
    ];
    SubscriptionInfo subscriptionInfo = (SubscriptionInfo) JSON.deserialize(
      subscription,
      SubscriptionInfo.class
    );
    AuthorizeNetService authNetService = ManageAuthNetService.getAuthorizeNetService(
      recordId,
      RECORD_TYPE
    );

    // Get previous subscription info.
    AuthorizeNetModels.ARBGetSubscriptionResponse subscriptionResponse = getSubscription(
      rd,
      authNetService
    );

    // Cancel previous subscription. Returns a response, but we don't need it.
    try {
      cancelSubscription(rd, authNetService);
    } catch (AuthNetSubscriptionCancelledException e) {
      // Only swallow the specific "already cancelled" exception. All others should get raised.
      System.debug('Subscription already canceled: ' + rd.Subscription_Id__c);
    }

    // Prepare subscription objects
    AuthorizeNetModels.ARBSubscriptionType sub = new AuthorizeNetModels.ARBSubscriptionType();
    sub.profile = new AuthorizeNetModels.customerProfileIdType();
    sub.paymentSchedule = new AuthorizeNetModels.paymentScheduleType();
    sub.paymentSchedule.interval = new AuthorizeNetModels.paymentScheduleTypeInterval();
    ManageAuthNetService.Installment installment = new ManageAuthNetService.Installment();

    // General info - perform currency conversion
    CurrencyExchangeRateCalculator calculator = new CurrencyExchangeRateCalculator();
    sub.amount = calculator.convert(
      subscriptionInfo.selectedCurrency,
      'USD',
      subscriptionInfo.amount
    );

    // Handle Auth.net interval
    installment.period = subscriptionInfo.installmentPeriod;
    installment.frequency = subscriptionInfo.installmentFrequency;
    sub.paymentSchedule.interval = ManageAuthNetService.resolveInterval(installment);

    // Resolve Total Occurences
    ManageAuthNetService.SubscriptionDates dates = new ManageAuthNetService.SubscriptionDates();
    dates.startDate = subscriptionInfo.startDate;
    dates.endDate = subscriptionInfo.endDate;
    sub.paymentSchedule.startDate = ((Datetime) dates.startDate).formatGMT('yyyy-MM-dd');
    sub.paymentSchedule.totalOccurrences = ManageAuthNetService.resolveTotalOccurrences(
      dates,
      sub.paymentSchedule.interval
    );

    // Get payment info from previous subscription
    sub.profile.customerProfileId = subscriptionResponse.subscription.profile.customerProfileId;
    sub.profile.customerPaymentProfileId = subscriptionResponse.subscription.profile.paymentProfiles[0]
      .customerPaymentProfileId;
    sub.name = subscriptionResponse.subscription.name;

    // Create new subscription
    AuthorizeNetModels.ARBCreateSubscriptionResponse createSubscriptionResponse = authNetService.createSubscription(
      sub,
      null
    );

    // Handle results
    if (
      ManageAuthNetService.isResponseValid(
        (AuthorizeNetModels.ANetApiResponse) createSubscriptionResponse
      )
    ) {
      updateRecurringDonationOnUpdate(
        rd,
        subscriptionInfo,
        createSubscriptionResponse.subscriptionId,
        sub.amount
      );
      update rd;
      return subscriptionInfo;
    } else {
      throw new ManageAuthNetService.AuthNetServiceException(
        createSubscriptionResponse.messages.message.text
      );
    }
  }

  private static void updateRecurringDonationOnUpdate(
    npe03__Recurring_Donation__c rd,
    SubscriptionInfo subscriptionInfo,
    String subscriptionId,
    Decimal authAmount
  ) {
    rd.npe03__Amount__c = authAmount;
    rd.Original_Amount__c = subscriptionInfo.amount;
    rd.Original_Currency__c = subscriptionInfo.selectedCurrency;
    rd.npsp__EndDate__c = subscriptionInfo.endDate;
    rd.npsp__StartDate__c = subscriptionInfo.startDate;
    rd.npe03__Installment_Period__c = subscriptionInfo.installmentPeriod;
    rd.npsp__InstallmentFrequency__c = subscriptionInfo.installmentFrequency;
    rd.Subscription_Id__c = subscriptionId;
    rd.npsp__Status__c = 'Active';
  }

  @AuraEnabled
  public static SubscriptionInfo updateAuthNetPaymentMethod(
    Id recordId,
    String subscription,
    Map<String, String> paymentInfo
  ) {
    /* Kyle - PaymentInfo is a map storing all the updated information. It has these fields:
    - paymentMethod
    - cardNumber (set when paymentMethod = Credit Card)
    - cvv (set when paymentMethod = Credit Card)
    - selectedMonth (set when paymentMethod = Credit Card)
    - selectedYear (set when paymentMethod = Credit Card)
    - accountHolder (set when paymentMethod = Bank Account)
    - routingNumber (set when paymentMethod = Bank Account)
    - accountNumber (set when paymentMethod = Bank Account)
    */
    // Validate
    PaymentType pt;
    if (paymentInfo.get('cardNumber') != null) {
      pt = PaymentType.CREDIT_CARD;
    } else if (paymentInfo.get('accountNumber') != null) {
      pt = PaymentType.BANK_ACCOUNT;
    } else {
      throw new ManageAuthNetService.AuthNetServiceException(
        'Invalid payment type. Must have a Credit Card or Bank Account number.'
      );
    }

    // Setup - requery. Do not trust client-provided info.
    npe03__Recurring_Donation__c rd = [
      SELECT Id, Subscription_Id__c, Customer_Profile__r.Payment_Profile_Id__c
      FROM npe03__Recurring_Donation__c Id
      WHERE id = :recordId
    ];
    SubscriptionInfo subscriptionInfo = (SubscriptionInfo) JSON.deserialize(
      subscription,
      SubscriptionInfo.class
    );
    AuthorizeNetService authNetService = ManageAuthNetService.getAuthorizeNetService(
      recordId,
      RECORD_TYPE
    );

    // Get previous subscription info.
    AuthorizeNetModels.ARBGetSubscriptionResponse subscriptionResponse = getSubscription(
      rd,
      authNetService
    );

    // Prepare payment profile objects
    AuthorizeNetModels.customerPaymentProfileType paymentProfile = new AuthorizeNetModels.customerPaymentProfileType();
    Boolean foundProfile = false;
    for (AuthorizeNetModels.customerPaymentProfileType pp : subscriptionResponse.subscription.profile.paymentProfiles){
      if (pp.customerPaymentProfileId == rd.Customer_Profile__r.Payment_Profile_Id__c){
        paymentProfile = pp;
        foundProfile = true;
        break;
      }
    }
    if (!foundProfile){
      paymentProfile = subscriptionResponse.subscription.profile.paymentProfiles[0];
    }
    
    paymentProfile.payment = new AuthorizeNetModels.paymentType();
    if (pt == PaymentType.CREDIT_CARD) {
      paymentProfile.payment.creditCard = new AuthorizeNetModels.creditCardType();
      paymentProfile.payment.creditCard.cardNumber = paymentInfo.get('cardNumber');
      paymentProfile.payment.creditCard.cardCode = paymentInfo.get('cvv');
      paymentProfile.payment.creditCard.expirationDate =
        paymentInfo.get('selectedMonth').leftPad(2, '0') +
        '/' +
        paymentInfo.get('selectedYear').substring(2, 4);
      rd.Credit_Card_Expiration_Month__c = paymentInfo.get('selectedMonth');
      rd.Credit_Card_Expiration_Year__c = paymentInfo.get('selectedYear').substring(2, 4);
      rd.Credit_Card_Last_4__c = paymentInfo.get('cardNumber').right(4);
    } else {
      paymentProfile.payment.bankAccount = new AuthorizeNetModels.bankAccountType();
      paymentProfile.payment.bankAccount.nameOnAccount = paymentInfo.get('accountHolder');
      paymentProfile.payment.bankAccount.routingNumber = paymentInfo.get('routingNumber');
      paymentProfile.payment.bankAccount.accountNumber = paymentInfo.get('accountNumber');
      rd.Credit_Card_Expiration_Month__c = null;
      rd.Credit_Card_Expiration_Year__c = null;
      rd.Credit_Card_Last_4__c = paymentInfo.get('routingNumber').right(4);
    }

    // Update the payment profile
    AuthorizeNetModels.createCustomerPaymentProfileResponse updateCustomerPaymentProfileResponse = authNetService.updateCustomerPaymentProfile(
      null,
      subscriptionResponse.subscription.profile.customerProfileId,
      paymentProfile,
      null
    );
    if (
      ManageAuthNetService.isResponseValid(
        (AuthorizeNetModels.ANetApiResponse) updateCustomerPaymentProfileResponse
      )
    ) {
      update rd;
    } else {
      throw new ManageAuthNetService.AuthNetServiceException(
        updateCustomerPaymentProfileResponse.messages.message.text
      );
    }

    return (SubscriptionInfo) JSON.deserialize(subscription, SubscriptionInfo.class);
  }

  /**
   * See updateAuthNetSubscription for more info, since it is a superset of this method.
   *
   * @param recordId Id of the Recurring Donation
   * @param subscription serialized SubscriptionInfo from the UI
   *
   * @return SubscriptionInfo
   */
  @AuraEnabled
  public static SubscriptionInfo cancelAuthNetSubscription(Id recordId, String subscription) {
    npe03__Recurring_Donation__c rd = [
      SELECT Id, Subscription_Id__c
      FROM npe03__Recurring_Donation__c Id
      WHERE id = :recordId
    ];
    SubscriptionInfo subscriptionInfo = (SubscriptionInfo) JSON.deserialize(
      subscription,
      SubscriptionInfo.class
    );

    cancelSubscription(rd, null);

    rd.npsp__Status__c = 'Closed';
    update rd;

    return subscriptionInfo;
  }

  public class SubscriptionInfo {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String paymentMethod;
    @AuraEnabled
    public String cardNumber;
    @AuraEnabled
    public String expirationMonth;
    @AuraEnabled
    public String expirationYear;
    @AuraEnabled
    public String accountNumber;
    @AuraEnabled
    public String routingNumber;
    @AuraEnabled
    public Double amount;
    @AuraEnabled
    public String selectedCurrency;
    @AuraEnabled
    public Date startDate;
    @AuraEnabled
    public Date endDate;
    @AuraEnabled
    public String installmentPeriod; //i.e. Weekly, Monthly, Yearly
    @AuraEnabled
    public Integer installmentFrequency; //i.e. 1, 2, 3 (ex Every 1 Month)

    public SubscriptionInfo(
      Id recordId,
      AuthorizeNetModels.ARBGetSubscriptionResponse subscriptionResponse
    ) {
      this.id = subscriptionResponse.refId;
      this.status = subscriptionResponse.subscription.status;
      // Recurring Donation from the donation page should only have one payment profile
      if (subscriptionResponse.subscription.profile.paymentProfiles.size() > 0) {
        if (
          subscriptionResponse.subscription.profile.paymentProfiles[0].payment.creditCard != null
        ) {
          this.paymentMethod = 'Credit Card';
          this.cardNumber = subscriptionResponse.subscription.profile.paymentProfiles[0]
            .payment.creditCard.cardNumber;
          this.expirationMonth = subscriptionResponse.subscription.profile.paymentProfiles[0]
            .payment.creditCard.expirationDate.substring(0, 2);
          this.expirationYear = subscriptionResponse.subscription.profile.paymentProfiles[0]
            .payment.creditCard.expirationDate.substring(2, 4);
        } else if (
          subscriptionResponse.subscription.profile.paymentProfiles[0].payment.bankAccount != null
        ) {
          this.paymentMethod = 'Bank Account';
          this.accountNumber = subscriptionResponse.subscription.profile.paymentProfiles[0]
            .payment.bankAccount.accountNumber;
          this.routingNumber = subscriptionResponse.subscription.profile.paymentProfiles[0]
            .payment.bankAccount.routingNumber;
        }
      }

      this.amount = subscriptionResponse.subscription.amount;
      // Transform information from Auth.net into information relevant to the Aura component
      ManageAuthNetService.SubscriptionDates dates = ManageAuthNetService.resolveSubscriptionDates(
        subscriptionResponse.subscription.paymentSchedule
      );
      this.startDate = dates.startDate;
      this.endDate = dates.endDate;
      ManageAuthNetService.Installment installment = ManageAuthNetService.resolveInstallment(
        subscriptionResponse.subscription.paymentSchedule.interval
      );
      this.installmentPeriod = installment.period;
      this.installmentFrequency = installment.frequency;
    }
  }
}