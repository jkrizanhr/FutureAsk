public class DonationPageAuthNetPaymentService implements DonationPagePaymentService {
  private Boolean isTestMode;
  private Donation_Page_Auth_net_Settings__c authNetSettings;

  public DonationPageAuthNetPaymentService() {
    this.isTestMode = false;
    this.authNetSettings = Donation_Page_Auth_net_Settings__c.getInstance(
      'Production'
    );
    if (this.authNetSettings == null) {
      throw new DonationPagePaymentServiceException('No Auth.net Settings');
    }
  }

  public void setPublicKey(DonationPageModels.FormData fd) {
    System.debug('setPublicKey');
    fd.authNetClientKey = this.authNetSettings.Client_Key__c;
    fd.authNetAPILoginId = this.authNetSettings.API_Login_Id__c;
  }

  public DonationPageModels.PaymentResponse createOneTimePayment(
    DonationPageModels.FormSubmission submission,
    DonationPageModels.PaymentResponse res
  ) {
    System.debug('createOneTimePayment');
    res.type = 'One-time';

    AuthorizeNetModels.createTransactionResponse authNetCharge;

    AuthorizeNetService authNetService = new AuthorizeNetService(
      this.authNetSettings.API_Login_Id__c,
      this.authNetSettings.Transaction_Key__c,
      this.isTestMode
    );
    AuthorizeNetModels.transactionRequestType tr = new AuthorizeNetModels.transactionRequestType();
    tr.transactionType = 'authCaptureTransaction';
    // if (
    //   submission.dfs.Original_Currency__c == 'INR' ||
    //   submission.dfs.Original_Currency__c == 'KES'
    // ) {
    //   CurrencyExchangeRateCalculator exchangeCalculator = new CurrencyExchangeRateCalculator();
    //   tr.amount = exchangeCalculator.convert(
    //     submission.dfs.Original_Currency__c,
    //     'USD',
    //     submission.dfs.Total_Amount__c
    //   );
    //   tr.currencyCode = 'USD';
    // } else {
    tr.amount = submission.dfs.Total_Amount__c;
    tr.currencyCode = 'USD';
    // tr.currencyCode = submission.dfs.Original_Currency__c;
    // }

    tr.payment = new AuthorizeNetModels.paymentType();
    tr.payment.opaqueData = new AuthorizeNetModels.opaqueDataType();
    tr.payment.opaqueData.dataDescriptor = submission.authNetOpaqueDataDescriptor;
    tr.payment.opaqueData.dataValue = submission.authNetOpaqueDataDataValue;

    tr.billTo = new AuthorizeNetModels.addressType();
    tr.billTo.firstName = submission.dfs.Billing_First_Name__c;
    tr.billTo.lastName = submission.dfs.Billing_Last_Name__c;
    tr.billTo.address = submission.dfs.Billing_Street_Address__c;
    tr.billTo.city = submission.dfs.Billing_City__c;
    tr.billTo.state = submission.dfs.Billing_State__c;
    tr.billTo.zip = submission.dfs.Billing_Postal_Code__c;
    tr.billTo.email = submission.dfs.Billing_Email__c;
    tr.billTo.phoneNumber = submission.dfs.Billing_Phone__c;
    tr.billTo.country = submission.dfs.Billing_Country__c;

    authNetCharge = authNetService.createTransaction(tr, null);
    if (
      authNetCharge != null &&
      authNetCharge.transactionResponse != null &&
      authNetCharge.transactionResponse.errors != null
    ) {
      res.success = false;
      res.error = authNetCharge.transactionResponse.errors[0].errorText;
    } else if (
      authNetCharge != null &&
      authNetCharge.transactionResponse != null &&
      authNetCharge.transactionResponse.responseCode == '1'
    ) {
      System.debug(authNetCharge);
      res.transactionId = authNetCharge.transactionResponse.transId;
      res.createTime = Datetime.now();
      res.status = 'Approved';
      res.success = true;
    } else {
      res.success = false;
      res.error = 'Error processing credit card';
    }

    return res;
  }

  public DonationPageModels.PaymentResponse createRecurringPayment(
    DonationPageModels.FormSubmission submission,
    DonationPageModels.PaymentResponse res
  ) {
    System.debug('createRecurringPayment');
    res.type = 'Standard Recurring';

    AuthorizeNetModels.createCustomerProfileResponse profileResponse;

    AuthorizeNetService authNetService = new AuthorizeNetService(
      this.authNetSettings.API_Login_Id__c,
      this.authNetSettings.Transaction_Key__c,
      this.isTestMode
    );
    AuthorizeNetModels.customerProfileType cp = new AuthorizeNetModels.customerProfileType();
    cp.merchantCustomerId = submission.dfs.Id;
    cp.description = 'Customer Profile created through SF Donation Page';
    cp.email = submission.dfs.Billing_Email__c;
    cp.paymentProfiles = new List<AuthorizeNetModels.customerPaymentProfileType>();

    AuthorizeNetModels.customerPaymentProfileType pp = new AuthorizeNetModels.customerPaymentProfileType();
    pp.customerType = 'individual';
    pp.payment = new AuthorizeNetModels.paymentType();
    pp.payment.opaqueData = new AuthorizeNetModels.opaqueDataType();
    pp.payment.opaqueData.dataDescriptor = submission.authNetOpaqueDataDescriptor;
    pp.payment.opaqueData.dataValue = submission.authNetOpaqueDataDataValue;

    pp.billTo = new AuthorizeNetModels.addressType();
    pp.billTo.firstName = submission.dfs.Billing_First_Name__c;
    pp.billTo.lastName = submission.dfs.Billing_Last_Name__c;
    pp.billTo.address = submission.dfs.Billing_Street_Address__c;
    pp.billTo.city = submission.dfs.Billing_City__c;
    pp.billTo.state = submission.dfs.Billing_State__c;
    pp.billTo.zip = submission.dfs.Billing_Postal_Code__c;
    pp.billTo.email = submission.dfs.Billing_Email__c;
    pp.billTo.phoneNumber = submission.dfs.Billing_Phone__c;
    pp.billTo.country = submission.dfs.Billing_Country__c;

    cp.paymentProfiles.add(pp);
    profileResponse = authNetService.createCustomerProfile(
      null,
      cp,
      'liveMode'
    );

    if (
      profileResponse != null && profileResponse.messages != null &&
      profileResponse.messages.resultCode == 'Error' ||
      String.isBlank(profileResponse.customerProfileId) ||
      profileResponse.customerPaymentProfileIdList.isEmpty()
    ) {
      res.success = false;
      res.error = 'Failed to create customer profile or payment method. ';
      if (profileResponse.messages.message != null) {
        res.error += profileResponse.messages.message.text;
      }
      return res;
    }
    System.debug(profileResponse);
    System.debug(profileResponse.customerProfileId);
    System.debug(profileResponse.customerPaymentProfileIdList[0]);

    res.success = true;
    res.customerId = profileResponse.customerProfileId;
    res.paymentProfileId = profileResponse.customerPaymentProfileIdList[0];
    return res;
  }

  public DonationPageModels.PaymentResponse createMultiFrequencyRecurringPayment(
    DonationPageModels.FormSubmission submission,
    DonationPageModels.PaymentResponse res
  ) {
    // This will be implemented at a later time, not ready for go-live

    // System.debug('createMultiFrequencyRecurringPayment');
    // res.optionResponses = new List<DonationPageModels.OptionResponse>();
    // res.type = 'Per Option Recurring';

    // AuthorizeNetModels.createCustomerProfileResponse profileResponse;

    // AuthorizeNetService authNetService = new AuthorizeNetService(
    //   this.authNetSettings.API_Login_Id__c,
    //   this.authNetSettings.Transaction_Key__c,
    //   this.isTestMode
    // );

    // // create customer profile
    // AuthorizeNetModels.customerProfileType cp = new AuthorizeNetModels.customerProfileType();
    // cp.merchantCustomerId = submission.dfs.Id;
    // cp.description = 'Customer Profile created through SF Donation Page';
    // cp.email = submission.dfs.Billing_Email__c;
    // cp.paymentProfiles = new List<AuthorizeNetModels.customerPaymentProfileType>();

    // AuthorizeNetModels.customerPaymentProfileType pp = new AuthorizeNetModels.customerPaymentProfileType();
    // pp.customerType = 'individual';
    // pp.payment = new AuthorizeNetModels.paymentType();
    // pp.payment.opaqueData = new AuthorizeNetModels.opaqueDataType();
    // pp.payment.opaqueData.dataDescriptor = submission.authNetOpaqueDataDescriptor;
    // pp.payment.opaqueData.dataValue = submission.authNetOpaqueDataDataValue;

    // pp.billTo = new AuthorizeNetModels.addressType();
    // pp.billTo.firstName = submission.dfs.Billing_First_Name__c;
    // pp.billTo.lastName = submission.dfs.Billing_Last_Name__c;
    // pp.billTo.address = submission.dfs.Billing_Street_Address__c;
    // pp.billTo.city = submission.dfs.Billing_City__c;
    // pp.billTo.state = submission.dfs.Billing_State__c;
    // pp.billTo.zip = submission.dfs.Billing_Postal_Code__c;
    // pp.billTo.email = submission.dfs.Billing_Email__c;
    // pp.billTo.phoneNumber = submission.dfs.Billing_Phone__c;
    // pp.billTo.country = submission.dfs.Billing_Country__c;

    // cp.paymentProfiles.add(pp);
    // profileResponse = authNetService.createCustomerProfile(
    //   null,
    //   cp,
    //   'liveMode'
    // );
    // System.debug(profileResponse);

    // if (
    //   profileResponse != null && profileResponse.messages != null &&
    //   profileResponse.messages.resultCode == 'Error' ||
    //   String.isBlank(profileResponse.customerProfileId) ||
    //   profileResponse.customerPaymentProfileIdList.isEmpty()
    // ) {
    //   res.success = false;
    //   res.error = 'Failed to create customer profile or payment method. ';
    //   if (profileResponse.messages.message != null) {
    //     res.error += profileResponse.messages.message.text;
    //   }
    //   return res;
    // }

    // // make first transaction
    // AuthorizeNetModels.createTransactionResponse authNetCharge;
    // AuthorizeNetModels.transactionRequestType tr = new AuthorizeNetModels.transactionRequestType();
    // tr.transactionType = 'authCaptureTransaction';
    // if (
    //   submission.dfs.Original_Currency__c == 'INR' ||
    //   submission.dfs.Original_Currency__c == 'KES'
    // ) {
    //   CurrencyExchangeRateCalculator exchangeCalculator = new CurrencyExchangeRateCalculator();
    //   tr.amount = exchangeCalculator.convert(
    //     submission.dfs.Original_Currency__c,
    //     'USD',
    //     submission.dfs.Total_Amount__c
    //   );
    //   tr.currencyCode = 'USD';
    // } else {
    //   tr.amount = submission.dfs.Total_Amount__c;
    //   tr.currencyCode = submission.dfs.Original_Currency__c;
    // }

    // tr.profile = new AuthorizeNetModels.customerProfilePaymentType();
    // tr.profile.customerProfileId = profileResponse.customerProfileId;
    // tr.profile.paymentProfile = new AuthorizeNetModels.paymentProfile();
    // tr.profile.paymentProfile.paymentProfileId = profileResponse.customerPaymentProfileIdList[0];

    // authNetCharge = authNetService.createTransaction(tr, null);
    // if (
    //   authNetCharge != null &&
    //   authNetCharge.transactionResponse != null &&
    //   authNetCharge.transactionResponse.errors != null
    // ) {
    //   res.success = false;
    //   res.error = authNetCharge.transactionResponse.errors[0].errorText;
    // } else if (
    //   authNetCharge != null &&
    //   authNetCharge.transactionResponse != null &&
    //   authNetCharge.transactionResponse.responseCode == '1'
    // ) {
    //   System.debug(authNetCharge);
    //   res.transactionId = authNetCharge.transactionResponse.transId;
    //   res.createTime = Datetime.now();
    //   res.status = 'Approved';
    //   res.success = true;
    // } else {
    //   res.success = false;
    //   res.error = 'Error processing credit card';
    // }

    // // set up recurring donations for all options
    // for (DonationPageModels.DonationOption option : submission.chosenOptions) {
    //   DonationPageModels.OptionResponse optRes = new DonationPageModels.OptionResponse();
    //   optRes.donOptId = option.option.Id;
    //   if (option.frequency == 'One-time') {
    //     optRes.success = true;
    //   }

    //   String authNetFrequency;
    //   Integer authNetFrequencyInterval;
    //   switch on option.frequency {
    //     when 'Weekly' {
    //       authNetFrequency = 'days';
    //       authNetFrequencyInterval = 7;
    //     }
    //     when 'Monthly' {
    //       authNetFrequency = 'months';
    //       authNetFrequencyInterval = 1;
    //     }
    //     when 'Quarterly' {
    //       authNetFrequency = 'months';
    //       authNetFrequencyInterval = 3;
    //     }
    //     when 'Yearly' {
    //       authNetFrequency = 'months';
    //       authNetFrequencyInterval = 12;
    //     }
    //   }

    //   Date today = Date.today();
    //   Date firstPaymentDate;
    //   switch on option.frequency {
    //     when 'Weekly' {
    //       firstPaymentDate = today.addDays(7);
    //     }
    //     when 'Monthly' {
    //       firstPaymentDate = today.addMonths(1);
    //     }
    //     when 'Quarterly' {
    //       firstPaymentDate = today.addMonths(3);
    //     }
    //     when 'Yearly' {
    //       firstPaymentDate = today.addYears(1);
    //     }
    //   }
    //   String firstPaymentDateString = Datetime.newInstance(
    //       firstPaymentDate,
    //       Time.newInstance(0, 0, 0, 0)
    //     )
    //     .format('yyyy-MM-dd');

    //   AuthorizeNetModels.ARBCreateSubscriptionResponse subscriptionResponse;
    //   AuthorizeNetModels.ARBSubscriptionType sub = new AuthorizeNetModels.ARBSubscriptionType();
    //   sub.name =
    //     option.option.Id +
    //     '_' +
    //     option.amount +
    //     '_' +
    //     authNetFrequency +
    //     '_' +
    //     authNetFrequencyInterval;
    //   sub.amount = option.amount;

    //   sub.paymentSchedule = new AuthorizeNetModels.paymentScheduleType();
    //   sub.paymentSchedule.interval = new AuthorizeNetModels.paymentScheduleTypeInterval();
    //   sub.paymentSchedule.interval.unit = authNetFrequency;
    //   sub.paymentSchedule.interval.length = authNetFrequencyInterval;
    //   sub.paymentSchedule.startDate = firstPaymentDateString;
    //   sub.paymentSchedule.totalOccurrences = option.numPayments != null
    //     ? option.numPayments
    //     : 9999; //9999 indicates open-ended recurring donation in Auth.net

    //   sub.profile = new AuthorizeNetModels.customerProfileIdType();
    //   sub.profile.customerProfileId = profileResponse.customerProfileId;
    //   sub.profile.customerPaymentProfileId = profileResponse.customerPaymentProfileIdList[0];

    //   subscriptionResponse = authNetService.createSubscription(sub, null);

    //   if (
    //     subscriptionResponse != null &&
    //     subscriptionResponse.messages != null &&
    //     subscriptionResponse.messages.message != null &&
    //     subscriptionResponse.messages.message.code == 'I00001'
    //   ) {
    //     //success
    //     optRes.success = true;
    //     optRes.subscriptionId = subscriptionResponse.subscriptionId;
    //   } else {
    //     optRes.success = false;
    //     optRes.error = 'Failed to create subscription';
    //     optRes.error += ' ' + subscriptionResponse.messages.message.text;
    //     System.debug(optRes.error);
    //   }
    //   res.optionResponses.add(optRes);
    // }
    // System.debug(res);

    return res;
  }

  public void enableTestMode() {
    System.debug('enableTestMode');
    this.isTestMode = true;
  }

  public void setPaymentSettings(String settingsName) {
    System.debug('setPaymentSettings');
    this.authNetSettings = Donation_Page_Auth_net_Settings__c.getInstance(
      settingsName
    );
    if (this.authNetSettings == null) {
      throw new DonationPagePaymentServiceException(
        'No Auth.net Settings for ' + settingsName
      );
    }
  }
}