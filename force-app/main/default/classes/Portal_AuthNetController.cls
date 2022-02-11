public without sharing class Portal_AuthNetController {
  
  /**** 
    DONATION PAGE AND SAVED PAYMENT METHOD COMPONENTS 
   ****/

  // GetAuthorizeNetService
  // Initialize the AuthNetService class so those methods can be used in this class to make callouts to Authorize.net
  private static AuthorizeNetService getAuthorizeNetService(){
    Organization org = [SELECT IsSandbox FROM Organization LIMIT 1];
    Donation_Page_Auth_net_Settings__c authNetSettings;
    Boolean testModeSubmission = true;

    if (!org.isSandbox) {
      authNetSettings = Donation_Page_Auth_net_Settings__c.getInstance('Production');
      testModeSubmission = false;
    } else {
      authNetSettings = Donation_Page_Auth_net_Settings__c.getInstance('Sandbox');
      testModeSubmission = true;
    }

    AuthorizeNetService authNetService = !Test.isRunningTest()
      ? new AuthorizeNetService(authNetSettings.API_Login_Id__c,authNetSettings.Transaction_Key__c,testModeSubmission)
      : new AuthorizeNetService('12345','12345',testModeSubmission);

    return authNetService;
  }

  // FetchPaymentMethods
  // Used in Portal_DonationPage and Portal_SavedPaymentMethods to return a list of  the donor's payment methods that are stored in auth.net 
  @AuraEnabled
  public static List<Portal_Models.PaymentMethodInfo> fetchPaymentMethods(Id contactId){
    List<Portal_Models.PaymentMethodInfo> paymentMethods = new List<Portal_Models.PaymentMethodInfo>();
    
    List<Customer_Profile__c> cpList = [
      SELECT Id, Customer_Profile_Id__c, Payment_Profile_Id__c
      FROM Customer_Profile__c 
      WHERE Contact__c = :contactId
    ];

    for (Customer_Profile__c cp : cpList){
      AuthorizeNetService authNetService = getAuthorizeNetService();
      AuthorizeNetModels.getCustomerPaymentProfileResponse res = !Test.isRunningTest()
        ? authNetService.getCustomerPaymentProfile(
          null, cp.Customer_Profile_Id__c, cp.Payment_Profile_Id__c, true, true)
        : Portal_Models.returnGetCustomerPaymentProfileResponse();

      if (res != null && res.paymentProfile != null && res.paymentProfile.payment != null){
        Portal_Models.PaymentMethodInfo pmi = new Portal_Models.PaymentMethodInfo();
        pmi.id = cp.Payment_Profile_Id__c;
        pmi.customerId = cp.Customer_Profile_Id__c;
        
        if (res.paymentProfile != null && res.paymentProfile.subscriptionIds != null){
          pmi.subscriptionIds = res.paymentProfile.subscriptionIds;
          pmi.hasActiveSubscription = true;
        } else {
          pmi.hasActiveSubscription = false;
        }

        if (res.paymentProfile.payment.creditCard != null){
          pmi.paymentMethod = 'Credit Card';
          pmi.cardType = res.paymentProfile.payment.creditCard.cardType;
          pmi.cardLastFour = res.paymentProfile.payment.creditCard.cardNumber;
          pmi.expirationDate = 
            res.paymentProfile.payment.creditCard.expirationDate.substringAfter('-') + '/' +
            res.paymentProfile.payment.creditCard.expirationDate.substringBetween('20', '-');
        } 
        else if (res.paymentProfile.payment.bankAccount != null){
          pmi.paymentMethod = 'EFT';
          pmi.bankName = res.paymentProfile.payment.bankAccount.bankName;
          pmi.accountNumber = res.paymentProfile.payment.bankAccount.accountNumber;
          pmi.routingNumber = res.paymentProfile.payment.bankAccount.routingNumber;
        }

        if (pmi.paymentMethod != null){
          paymentMethods.add(pmi);
        }
      } else if (res != null && res.messages != null && res.messages.message != null) {
        System.debug('Error Code: ' + res.messages.message.code);
        System.debug('Error Message: ' + res.messages.message.text);
      }
    }
    
    return paymentMethods;
  }

  /**** 
    DONATION PAGE COMPONENT METHODS
   ****/

  // BuildDonationFormSubmission
  // Builds a DonationFormSubmission record when a donation is made by a donor in the community
  @AuraEnabled
  public static Donation_Form_Submission__c buildDonationFormSubmission(
    Portal_Models.SubmissionInfo si, Campaign c
  ) {
    // Populate Contact/Billing Information
    Donation_Form_Submission__c dfs = new Donation_Form_Submission__c();
    dfs.Billing_First_Name__c = si.contact.FirstName;
    dfs.Billing_Last_Name__c = si.contact.LastName;
    dfs.Billing_Email__c = si.contact.Email;
    dfs.Billing_Phone__c = si.contact.Phone;
    dfs.Billing_Street_Address__c = si.contact.MailingStreet;
    dfs.Billing_City__c = si.contact.MailingCity;
    dfs.Billing_State__c = si.contact.MailingCountry == 'United States' ? si.contact.MailingState : null;
    dfs.Billing_State_Province__c = si.contact.MailingState;
    dfs.Billing_Postal_Code__c = si.contact.MailingPostalCode;
    dfs.Billing_Country__c = si.contact.MailingCountry;
    dfs.First_Name__c = si.contact.FirstName;
    dfs.Last_Name__c = si.contact.LastName;
    dfs.Email__c = si.contact.Email;
    dfs.Phone__c = si.contact.Phone;
    dfs.Street_Address__c = si.contact.MailingStreet;
    dfs.City__c = si.contact.MailingCity;
    dfs.State__c = si.contact.MailingCountry == 'United States' ? si.contact.MailingState : null;
    dfs.State_Province__c = si.contact.MailingState;
    dfs.Postal_Code__c = si.contact.MailingPostalCode;
    dfs.Country__c = si.contact.MailingCountry;
    dfs.Language_Preference__c = si.contact.Account.Language_Preference__c != null 
      ? si.contact.Account.Language_Preference__c : 'English';

    // Set Original Amounts on DFS
    dfs.Original_Currency__c = si.currencyType;
    dfs.Original_Amount__c = si.subtotal;
    dfs.Original_Amount_with_Fees__c = si.total;
    dfs.Will_Cover_Processing_Fees__c = si.coverFees;
    
    // Convert Currency to USD if Foreign
    if (si.currencyType != 'USD') {
      CurrencyExchangeRateCalculator exchangeCalculator = new CurrencyExchangeRateCalculator();
      // Convert SubTotal to USD
      dfs.Donation_Amount__c = exchangeCalculator.convert(
        dfs.Original_Currency__c, 'USD', dfs.Original_Amount__c
      );
      // Calculate Fees in USD if CoverFees = true
      Double subtotal = dfs.Donation_Amount__c * 100;
      Double total = si.coverFees
        ? ((subtotal + ((subtotal * .029)/.971)+30.9)) / 100
        : (subtotal) / 100;
      dfs.Total_Amount__c = total;
    } 
    // Set Amounts if CurrencyType is USD
    else {
      dfs.Donation_Amount__c = si.subtotal;
      dfs.Total_Amount__c = si.total;
    }
        
    // Set the Submission Date    
    dfs.Submission_Date__c = Date.today();
    dfs.Submission_JSON__c = JSON.serialize(si);

    // Set Send Receipt
    dfs.Send_Email_Receipt__c = true;

    // Set Recurring Gift Information Start Date
    dfs.Recurring_Start_Date_String__c = si.startDate; //yyyy-mm-dd
    dfs.Recurring_Start_Date__c = Date.valueOf(si.startDate);
    dfs.Frequency__c = si.frequency;
    dfs.Number_of_Recurring_Payments__c = si.frequency == 'One-time' ? 1 : 9999;
    dfs.Frequency_Interval__c = 1;

    // Set Campaign
    dfs.Campaign__c = c != null ? c.Id : null;
    dfs.Donation_Page_Source__c = 'Donor Portal';

    // Set Payment Method Info
    dfs.Payment_Method__c = si.paymentMethod.paymentMethod;
    if (dfs.Payment_Method__c == 'Credit Card'){
      dfs.Credit_Card_Type__c = si.paymentMethod.cardType;
      dfs.Credit_Card_Last_Four__c = si.paymentMethod.cardLastFour.substringAfter('XXXX');
      dfs.Credit_Card_Exp_Date__c = si.paymentMethod.expirationDate;
    }

    // Set Payment Profile Id and Customer Profile Id
    dfs.Payment_Processor_Customer_Id__c = si.paymentMethod.customerId;
    dfs.Payment_Profile_Id__c = si.paymentMethod.id;
    dfs.Test_Mode_Submission__c = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    
    return dfs;
  }

  // CreateAuthNetTransaction
  // Builds out the transaction record to send to auth, charges the card, and stores the results on the DFS record
  public static Donation_Form_Submission__c createAuthNetTransaction(Donation_Form_Submission__c dfs){
    AuthorizeNetModels.createTransactionResponse authNetCharge;

    AuthorizeNetService authNetService = getAuthorizeNetService();
    
    // Build out the transaction to send to Auth.net
    AuthorizeNetModels.transactionRequestType tr = new AuthorizeNetModels.transactionRequestType();
    tr.transactionType = 'authCaptureTransaction';
    tr.amount = dfs.Total_Amount__c.setScale(2, RoundingMode.HALF_UP);
    tr.currencyCode = 'USD';

    // Set the profile to the Current Customer Payment Profile   
    tr.profile = new AuthorizeNetModels.customerProfilePaymentType();
    tr.profile.createProfile = false;
    tr.profile.customerProfileId = dfs.Payment_Processor_Customer_Id__c;
    tr.profile.paymentProfile = new AuthorizeNetModels.paymentProfile();
    tr.profile.paymentProfile.paymentProfileId = dfs.Payment_Profile_Id__c;

    // Create the transaction in auth.net
    authNetCharge = authNetService.createTransaction(tr, null);
    
    // Error: Store the error messages in the Errors__c field on DFS
    if (
      authNetCharge != null &&
      authNetCharge.transactionResponse != null &&
      authNetCharge.transactionResponse.errors != null
    ) {
      dfs.Errors__c = authNetCharge.transactionResponse.errors[0].errorText;
      System.debug(authNetCharge.transactionResponse.errors);
    } 
    // Success: Set Transaction Id and put timestamp in the comments field on DFS
    else if (
      authNetCharge != null &&
      authNetCharge.transactionResponse != null &&
      authNetCharge.transactionResponse.responseCode == '1'
    ) {
      dfs.Payment_Processor_Transaction_Id__c = authNetCharge.transactionResponse.transId;
      dfs.Comments__c = 'Approved: ' + String.valueOf(Datetime.now());
    } 
    // Error: If the authNetCharge response is null - something went wrong
    else {
      dfs.Errors__c = 'Error processing credit card';
    }
  
    return dfs;
  }

  // CreateRecurringAuthNetSubscription
  // Builds out the subscription record to send to auth and stores the results on the DFS record
  public static Donation_Form_Submission__c createRecurringAuthNetSubscription(Donation_Form_Submission__c dfs){
    AuthorizeNetModels.ARBCreateSubscriptionResponse subscriptionResponse;

    AuthorizeNetService authNetService = getAuthorizeNetService();

    // Build out the subscription to send to Auth.net
    AuthorizeNetModels.ARBSubscriptionType subscription = new AuthorizeNetModels.ARBSubscriptionType();
    subscription.name = dfs.Id + '_' + dfs.Total_Amount__c.setScale(2, RoundingMode.HALF_UP) + '_' + dfs.Frequency__c;
    subscription.amount = dfs.Total_Amount__c.setScale(2, RoundingMode.HALF_UP);
    subscription.trialAmount = 0;

    // Set the Payment Schedule for the Subscription
    subscription.paymentSchedule = new AuthorizeNetModels.paymentScheduleType();
    subscription.paymentSchedule.interval = new AuthorizeNetModels.paymentScheduleTypeInterval();
    subscription.paymentSchedule.interval.length = dfs.Frequency__c == 'Monthly' ? 1 : 12;
    subscription.paymentSchedule.interval.unit = 'months';
    subscription.paymentSchedule.startDate = dfs.Recurring_Start_Date_String__c;
    subscription.paymentSchedule.trialOccurrences = 0;
    subscription.paymentSchedule.totalOccurrences = 9999;

    // Set the Profile to the Selected Payment Method
    subscription.profile = new AuthorizeNetModels.customerProfileIdType();
    subscription.profile.customerProfileId = dfs.Payment_Processor_Customer_Id__c;
    subscription.profile.customerPaymentProfileId = dfs.Payment_Profile_Id__c;

    // Create Subscription in Auth.net
    subscriptionResponse = authNetService.createSubscription(subscription, null);

    // Error: Store the error messages in the Errors__c field on DFS
    if (
      subscriptionResponse != null && subscriptionResponse.messages != null &&
      subscriptionResponse.messages.resultCode == 'Error' ||
      String.isBlank(subscriptionResponse.subscriptionId)
    ) {
      dfs.Errors__c = 'Failed to create customer subscription. ';
      if (subscriptionResponse.messages.message != null) {
        dfs.Errors__c += subscriptionResponse.messages.message.text;
        System.debug(subscriptionResponse.messages.message.text);
      }
    } 
    // Success: Set Subscription Id and put the timestamp in the comments field
    else if (
      subscriptionResponse != null &&
      String.isNotBlank(subscriptionResponse.subscriptionId)
    ) {
      System.debug(subscriptionResponse);
      System.debug(subscriptionResponse.subscriptionId);
      System.debug(subscriptionResponse.profile);
  
      dfs.Payment_Processor_Subscription_Id__c = subscriptionResponse.subscriptionId;
      dfs.Comments__c = 'Subscription Created: ' + String.valueOf(Datetime.now());
    } 
    // Error: If subscriptionResponse is null - something went wrong
    else {
      dfs.Errors__c = 'Error creating subscription.';
    }

    return dfs;
  }

  /**** 
    SAVED PAYMENT METHOD COMPONENT METHODS
   ****/

  // ValidatePaymentMethodInformation
  // Validates that the appropriate card numbers and dates were entered  when a donor is creating or updating a payment method
  public static Boolean validatePaymentMethodInformation(Map<String, String> pi){
    if (pi.get('cardNumber') != null || pi.get('accountNumber') != null){
      return true;
    } else {
      throw new ManageAuthNetService.AuthNetServiceException(
        'Invalid payment type. Must have a Credit Card or Bank Account number.'
      );
    }
  }

  // BuildProfile
  // Builds and creates a CustomerProfile for the donor in Auth.net and returns the CustomerProfileId
  public static String buildProfile(Contact con){

    AuthorizeNetModels.customerProfileType profile = new AuthorizeNetModels.customerProfileType();
    AuthorizeNetModels.addressType address = new AuthorizeNetModels.addressType();
    if (con != null){
      profile.email = String.isNotBlank(con.Email) ? con.Email : null;
    }

    // Initialize AuthorizeNetService class
    AuthorizeNetService authNetService = getAuthorizeNetService();

    // Create Customer Profile in Auth.net
    AuthorizeNetModels.createCustomerProfileResponse cp_res = !Test.isRunningTest()
      ? authNetService.createCustomerProfile(null, profile, null)
      : Portal_Models.returnCreateCustomerProfileResponse();

    // Success: Create Customer Payment Profile in Auth.net
    if (ManageAuthNetService.isResponseValid(cp_res)){
      return cp_res.customerProfileId;
    }
    // Error: Customer Profile could not be created.
    else {
      throw new ManageAuthNetService.AuthNetServiceException(
        cp_res.messages.message.text
      );
    }
  }

  // GetProfile
  // Returns the most recent existing CustomerProfileId stored in Salesforce
  public static String getProfile(String customerProfileId, Contact con){

    AuthorizeNetService authNetService = getAuthorizeNetService();
          
    AuthorizeNetModels.getCustomerProfileResponse res = !Test.isRunningTest()
      ? authNetService.getCustomerProfile(null, customerProfileId, null)
      : Portal_Models.returnGetCustomerProfileResponse();
    
    if (res != null && res.profile != null && res.profile.customerProfileId != null){
      return res.profile.customerProfileId;
    } else {
      return buildProfile(con);
    }
  }

  // BuildOrGetProfile
  // Looks to see if the donor already has a customer profile created in auth.net.
  // If true: Calls GetProfile to retrieve the existing profile information.
  // If false: Calls BuildProfile and inserts a new customer profile for the donor if none exist.
  public static String buildOrGetProfile(Contact con){
    List<Customer_Profile__c> cpList = [
      SELECT Customer_Profile_Id__c 
      FROM Customer_Profile__c 
      WHERE Contact__c = :con.Id
      ORDER BY CreatedDate DESC NULLS LAST
    ];
    
    if (cpList.isEmpty()){
      return buildProfile(con);
    } else {
      return getProfile(cpList[0].Customer_Profile_Id__c, con);
    }
  }

  //  BuildPaymentProfile
  // Builds out the PaymentProfile object to be sent to Auth.net with all the information entered via the Saved Payment Method component
  public static AuthorizeNetModels.customerPaymentProfileType buildPaymentProfile(
    Map<String, String> pi, Portal_Models.PaymentMethodInfo pmi, Contact con
  ){
    AuthorizeNetModels.customerPaymentProfileType paymentProfile = new AuthorizeNetModels.customerPaymentProfileType();
    // PREPARE PAYMENT PROFILE OBJECTS

    // if payment profile is being updated pull the existing payment profile
    if (pmi != null){
      AuthorizeNetService authNetService = getAuthorizeNetService();       
      AuthorizeNetModels.getCustomerPaymentProfileResponse res = !Test.isRunningTest()
        ? authNetService.getCustomerPaymentProfile(null, pmi.customerId, pmi.id, false, true)
        : Portal_Models.returnGetCustomerPaymentProfileResponse();
      paymentProfile = res.paymentProfile;
      paymentProfile.customerProfileId = null;
    }
    paymentProfile.payment = new AuthorizeNetModels.paymentType();
    
    if (pi.get('selectedMonth') == '0'){
      pi.put('selectedMonth', '1');
    }

    // Set Credit Card Fields
    if (pi.get('paymentMethod') == 'Credit Card') {
      paymentProfile.payment.creditCard = new AuthorizeNetModels.creditCardType();
      paymentProfile.payment.creditCard.cardNumber = pi.get('cardNumber');
      paymentProfile.payment.creditCard.cardCode = pi.get('cvv');
      paymentProfile.payment.creditCard.expirationDate =
        pi.get('selectedMonth').leftPad(2, '0') + '/' + pi.get('selectedYear').substring(2, 4);
    } 
    // Set Bank Account Fields
    else {
      paymentProfile.payment.bankAccount = new AuthorizeNetModels.bankAccountType();
      paymentProfile.payment.bankAccount.nameOnAccount = pi.get('accountHolder');
      paymentProfile.payment.bankAccount.routingNumber = pi.get('routingNumber');
      paymentProfile.payment.bankAccount.accountNumber = pi.get('accountNumber');
    }

    // Payment Profile Bill To
    paymentProfile.billTo = new AuthorizeNetModels.addressType();
    paymentProfile.billTo.firstName = String.isNotBlank(con.FirstName) ? con.FirstName : null;
    paymentProfile.billTo.lastName = String.isNotBlank(con.LastName) ? con.LastName : null;
    paymentProfile.billTo.company = String.isNotBlank(con.Title) ? con.Title : null;
    paymentProfile.billTo.address = String.isNotBlank(con.MailingStreet) ? con.MailingStreet : null;
    paymentProfile.billTo.city = String.isNotBlank(con.MailingCity) ? con.MailingCity : null;
    paymentProfile.billTo.state = String.isNotBlank(con.MailingState) ? con.MailingState : null;
    paymentProfile.billTo.zip = String.isNotBlank(con.MailingPostalCode) ? con.MailingPostalCode : null;
    paymentProfile.billTo.country = String.isNotBlank(con.MailingCountry) ? con.MailingCountry : null;
    paymentProfile.billTo.phoneNumber = String.isNotBlank(con.Phone) ? con.Phone : null;
    paymentProfile.billTo.email = String.isNotBlank(con.Email) ? con.Email : null;

    return paymentProfile;
  }

  // UpdatePaymentProfile
  // Updates an existing PaymentProfile in Auth.net using the information entered in the  Portal_SavedPaymentMethods component
  public static Boolean updatePaymentProfile(
    AuthorizeNetModels.customerPaymentProfileType paymentProfile, String customerProfileId
  ){
    AuthorizeNetService authNetService = getAuthorizeNetService();
    // TODO
    AuthorizeNetModels.createCustomerPaymentProfileResponse res = !Test.isRunningTest()
      ? authNetService.updateCustomerPaymentProfile(null, customerProfileId, paymentProfile, null)
      : Portal_Models.returnCreateCustomerPaymentProfileResponse();

    if (ManageAuthNetService.isResponseValid(res)){
      return true;
    } else {
      throw new ManageAuthNetService.AuthNetServiceException(
        res.messages.message.text
      );
    }
  }
  
  // CreatePaymentProfile
  // Creates a new payment profile using the information entered in the Portal_SavedPaymentMethod aura component in the donor community
  public static Boolean createPaymentProfile(
    Id contactId, String customerProfileId,
    AuthorizeNetModels.customerPaymentProfileType paymentProfile
  ){
    // Initialize AuthorizeNetService class
    AuthorizeNetService authNetService = getAuthorizeNetService();
    
    // Create Customer Payment Profile in Auth.net
    AuthorizeNetModels.createCustomerPaymentProfileResponse pp_res = !Test.isRunningTest()
      ? authNetService.createCustomerPaymentProfile(null, customerProfileId, paymentProfile, null)
      : Portal_Models.returnCreateCustomerPaymentProfileResponse();
    
    // Success: Create Customer Profile Record in SF
    if (ManageAuthNetService.isResponseValid(pp_res)){
      String paymentProfileId = pp_res.customerPaymentProfileId;

      Customer_Profile__c cp = new Customer_Profile__c(
        Contact__c = contactId,
        Customer_Profile_Id__c = customerProfileId, 
        Payment_Profile_Id__c = paymentProfileId
      );
      try {
        insert cp;
        return true;
      } catch (System.DmlException e) {
        for (Integer i = 0; i < e.getNumDml(); i++) {
          System.debug(e.getDmlMessage(i)); 
        }
        return false;
      }
    }

    // Error: Customer Payment Profile could not be created.
    else {
      throw new ManageAuthNetService.AuthNetServiceException(
        pp_res.messages.message.text
      );
    }
  }

  // VerifyDeleteCustomerProfile
  // Checks if there are additional payment profiles related to the parent customer profile. If yes, returns false (don't delete). If no, returns true (delete).
  public static Boolean verifyDeleteCustomerProfile(String customerProfileId, String paymentProfileId){
    List<Customer_Profile__c> cpList = [
      SELECT Id, Customer_Profile_Id__c, Payment_Profile_Id__c
      FROM Customer_Profile__c
      WHERE Customer_Profile_Id__c = :customerProfileId 
        AND Payment_Profile_Id__c != :paymentProfileId
    ];
    return cpList.isEmpty();
  }

  // DeleteCustomerProfile
  // Deletes the Customer Profile and Payment Profile in Auth.net
  public static Boolean deleteCustomerProfile(String customerProfileId, String paymentProfileId){
    // Initialize AuthorizeNetService class
    AuthorizeNetService authNetService = getAuthorizeNetService();
    
    AuthorizeNetModels.ANetApiResponse res = authNetService.deleteCustomerProfile(null, customerProfileId);
    
    if (ManageAuthNetService.isResponseValid(res) || Test.isRunningTest()){
      return deleteSalesforceCustomerProfile(customerProfileId, paymentProfileId);
    } else {
      throw new ManageAuthNetService.AuthNetServiceException(
        res.messages.message.text
      );
    }
  }
  
  // DeleteSalesforceCustomerProfile
  // Deletes the Payment Profile from Auth.net, keeps the Customer Profile since there are multiple Payment Profiles associated with the Customer Profile
  public static Boolean deleteCustomerPaymentProfile(String customerProfileId, String paymentProfileId){
    // Initialize AuthorizeNetService class
    AuthorizeNetService authNetService = getAuthorizeNetService();

    AuthorizeNetModels.ANetApiResponse res = authNetService.deleteCustomerPaymentProfile(
      null, customerProfileId, paymentProfileId);
    
    if (ManageAuthNetService.isResponseValid(res) || Test.isRunningTest()){
      return deleteSalesforceCustomerProfile(customerProfileId, paymentProfileId);
    } else {
      throw new ManageAuthNetService.AuthNetServiceException(
        res.messages.message.text
      );
    }
  }

  // DeleteSalesforceCustomerProfile
  // Deletes the Customer Profile record in Salesforce after the  Customer/Payment Profile have been deleted in auth.net
  public static Boolean deleteSalesforceCustomerProfile(String customerProfileId, String paymentProfileId){
    try {
      delete [
        SELECT Id 
        FROM Customer_Profile__c 
        WHERE Customer_Profile_Id__c = :customerProfileId 
          AND Payment_Profile_Id__c = :paymentProfileId
      ];
      return true;
    } catch (System.DmlException e){
      for (Integer i = 0; i < e.getNumDml(); i++) {
        System.debug(e.getDmlMessage(i)); 
      }
      return false;
    }
  }

  /**** 
    RECURRING DONATION METHODS
   ****/
  public static String updateSubscriptionPaymentMethod(
    String recordId, Portal_Models.SubscriptionInfo subscriptionInfo, Portal_Models.PaymentMethodInfo pmi
  ){
    // Get Recurring Donation
    npe03__Recurring_Donation__c rd = [
      SELECT Id, Subscription_Id__c, Customer_Profile__c, Customer_Profile__r.Customer_Profile_Id__c, Customer_Profile__r.Payment_Profile_Id__c
      FROM npe03__Recurring_Donation__c Id
      WHERE id = :recordId
    ];

    List<Customer_Profile__c> cpList = [
      SELECT Id
      FROM Customer_Profile__c
      WHERE Payment_Profile_Id__c = :pmi.id
      LIMIT 1
    ];

    Customer_Profile__c cp = !cpList.isEmpty() ? cpList[0] : null;

    if (cp == null){
      cp = new Customer_Profile__c();
      cp.Contact__c = Portal_Controller.getContactId();
      cp.Customer_Profile_Id__c = rd.Customer_Profile__r.Customer_Profile_Id__c;
      cp.Payment_Profile_Id__c = pmi.id;
      insert cp;
    } 

    AuthorizeNetService authNetService = getAuthorizeNetService();
    
    // Get subscription from auth.net
    AuthorizeNetModels.ARBGetSubscriptionResponse resSubscription = !Test.isRunningTest()
    ? authNetService.getSubscription(rd.Subscription_Id__c, null)
    : Portal_Models.returnGetSubscriptionResponse();
    
    AuthorizeNetModels.ARBSubscriptionType sub = new AuthorizeNetModels.ARBSubscriptionType();
    sub.name = resSubscription.subscription.name;
    sub.amount = resSubscription.subscription.amount;
    sub.trialAmount = resSubscription.subscription.trialAmount;
    sub.profile = new AuthorizeNetModels.customerProfileIdType();
    sub.profile.customerProfileId = rd.Customer_Profile__r.Customer_Profile_Id__c;
    sub.profile.customerPaymentProfileId = pmi.id;

    // Update payment method on subscription
    AuthorizeNetModels.ARBUpdateSubscriptionResponse res = !Test.isRunningTest()  
      ? authNetService.updateSubscription(sub, rd.Subscription_Id__c, null)
      : Portal_Models.returnUpdateSubscriptionResponse();
    
    if (res != null && res.messages != null && res.messages.message != null){
      if (res.messages.message.code == 'I00001'){
        rd.Customer_Profile__c = cp != null ? cp.Id : rd.Customer_Profile__c;
        update rd;
      }
      return res.messages.message.text;
    } else {
      return 'Oops. Something went wrong.';
    }
  }
}