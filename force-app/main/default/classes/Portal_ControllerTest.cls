@isTest
private class Portal_ControllerTest {
  
  // Test Setup: Currency Exchange Rate Record
  @testSetup 
  static void insertData() {
    System.debug('insertData');
    Fixer_Settings__c fixerSettings = new Fixer_Settings__c();
    fixerSettings.API_Key__c = '123';
    insert fixerSettings;

    Decimal usdRate = 1.10385;
    Decimal gbpRate = 0.855313;

    Currency_Exchange_Rate__c rate = new Currency_Exchange_Rate__c();
    rate.API_Response__c = CurrencyExchangeRateTestHelper.getResponseString(
      'EUR',
      usdRate,
      gbpRate
    );
    rate.Base__c = 'EUR';
    rate.Exchange_Rate_Collected_Date__c = Date.today();
    insert rate;

    Account acct = new Account();
    acct.Name = 'Test Account';
    insert acct;

    Contact c = new Contact();
    c.FirstName = 'First';
    c.LastName = 'Last';
    c.Email = 'test@candoris.com';
    c.AccountId = acct.Id;
    insert c;

    Requested_Profile_Update__c rpu = new Requested_Profile_Update__c();
    rpu.First_Name__c = 'First';
    rpu.Last_Name__c = 'Last';
    rpu.Preferred_Phone__c = 'Home';
    rpu.Home_Phone__c = '1234567890';
    rpu.Work_Phone__c = '6549873210';
    rpu.Mobile_Phone__c = '3214569870';
    rpu.Country__c = 'United States';
    rpu.Street__c = '123 Test Street';
    rpu.City__c = 'Annville';
    rpu.State__c = 'PA';
    rpu.Postal_Code__c = '17003';
    rpu.Contact__c = c.Id;
    rpu.Update_Status__c = 'Pending';
    insert rpu;

    Profile p = [SELECT Id FROM Profile WHERE Name = 'Donor Portal User']; 
    User u = new User(
      Alias = 'user', 
      Email='portalTest@candoris.com.biblica', 
      EmailEncodingKey='UTF-8', 
      LastName='User', 
      LanguageLocaleKey='en_US', 
      LocaleSidKey='en_US', 
      ProfileId = p.Id, 
      TimeZoneSidKey='America/New_York', 
      UserName='portalTest@candoris.com.biblica',
      ContactId = c.Id
    );
    insert u;

    Opportunity opp1 = new Opportunity(
      Name = 'Test Opportunity',
      AccountId = acct.Id,
      npsp__Primary_Contact__c = c.Id,
      Original_Amount__c = 100,
      Original_Currency__c = 'USD',
      StageName = 'Posted',
      CloseDate = Date.today()
    );
    Opportunity opp2 = new Opportunity(
      Name = 'Test Opportunity',
      AccountId = acct.Id,
      npsp__Primary_Contact__c = c.Id,
      Original_Amount__c = 50,
      Original_Currency__c = 'USD',
      StageName = 'Posted',
      CloseDate = Date.today()
    );
    insert new List<Opportunity>{opp1, opp2};
    
    npsp__General_Accounting_Unit__c gau1 = new npsp__General_Accounting_Unit__c(
      Name = '317-Where Needed Most',
      Purpose_Code__c = '317'
    );    
    npsp__General_Accounting_Unit__c gau2 = new npsp__General_Accounting_Unit__c(
      Name = '2417-Project GAU',
      Purpose_Code__c = '2417'
    );
    insert new List<npsp__General_Accounting_Unit__c>{gau1, gau2};

    npsp__Allocation__c alloc1 = new npsp__Allocation__c(
      npsp__General_Accounting_Unit__c = gau1.Id,
      npsp__Opportunity__c = opp1.Id,
      Original_Currency__c = 'USD',
      Original_Amount__c = 50,
      Tax_Deductible__c = true
    );
    npsp__Allocation__c alloc2 = new npsp__Allocation__c(
      npsp__General_Accounting_Unit__c = gau2.Id,
      npsp__Opportunity__c = opp1.Id,
      Original_Currency__c = 'USD',
      Original_Amount__c = 50,
      Tax_Deductible__c = true
    );
    npsp__Allocation__c alloc3 = new npsp__Allocation__c(
      npsp__General_Accounting_Unit__c = gau1.Id,
      npsp__Opportunity__c = opp2.Id,
      Original_Currency__c = 'USD',
      Original_Amount__c = 50,
      Tax_Deductible__c = true
    );
    insert new List<npsp__Allocation__c>{alloc1, alloc2, alloc3};
  
    npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
      Name = 'Test Recurring Donation',
      npe03__Contact__c = c.Id,
      npe03__Amount__c = 100,
      Original_Amount__c = 100,
      Original_Currency__c = 'USD',
      npe03__Date_Established__c = Date.today(),
      npe03__Installment_Period__c = 'Monthly',
      npsp__Status__c = 'Active'
    );
    insert rd;
  }



  // Home Page Components

  // FEATURED PROJECTS COMPONENT TESTS
  @isTest
  static void testFetchFeaturedProjects() {
    System.debug('testFetchFeaturedProjects');
    Project__c p1 = new Project__c(
      Name = 'Test Project',
      Status__c = 'In Progress',
      Public_Description__c = 'Description',
      Featured_Project__c = true,
      RecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Language Ministry Project').getRecordTypeId()
    );
    Project__c p2 = new Project__c(
      Name = 'Test Project',
      Status__c = 'In Progress',
      Public_Description__c = 'Description',
      Featured_Project__c = true,
      RecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Language Ministry Project').getRecordTypeId()
    );
    Project__c p3 = new Project__c(
      Name = 'Test Project',
      Status__c = 'In Progress',
      Public_Description__c = 'Description',
      Featured_Project__c = true,
      RecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Language Ministry Project').getRecordTypeId()
    );
    Project__c p4 = new Project__c(
      Name = 'Test Project',
      Status__c = 'In Progress',
      Public_Description__c = 'Description',
      Featured_Project__c = true,
      RecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Language Ministry Project').getRecordTypeId()
    );
    Project__c p5 = new Project__c(
      Name = 'Test Project',
      Status__c = 'In Progress',
      Public_Description__c = 'Description',
      Featured_Project__c = true,
      RecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Language Ministry Project').getRecordTypeId()
    );
    Project__c p6 = new Project__c(
      Name = 'Test Project',
      Status__c = 'In Progress',
      Public_Description__c = 'Description',
      Featured_Project__c = true,
      RecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Language Ministry Project').getRecordTypeId()
    );
    insert new List<Project__c>{p1, p2, p3, p4, p5, p6};

    Test.startTest();
      List<Project__c> res = Portal_Controller.fetchFeaturedProjects();
    Test.stopTest();

    System.assertNotEquals(null, res);
    System.assertEquals(5, res.size());
    System.assertEquals('Test Project', res[0].Name);
  }

  // MY GIVING IMPACT COMPONENT TESTS
  @isTest
  static void testFetchDonorTotals(){
    System.debug('testFetchDonorTotals');
    User u = [SELECT Id, ContactId FROM User WHERE Username = 'portalTest@candoris.com.biblica' LIMIT 1];

    System.runAs(u){
      Test.startTest();
        Contact res = Portal_Controller.fetchDonorTotals();
      Test.stopTest();

      System.assertNotEquals(null, res);
      System.assertEquals(u.ContactId, res.Id);
    }
  }

  // MY QUARTERLY REPORTS TESTS 
  @isTest 
  static void testFetchQuarterlyReports(){
    System.debug('testFetchQuarterlyReports');
    User u = [SELECT Id, Contact_Id__c FROM User WHERE Username = 'portalTest@candoris.com.biblica' LIMIT 1];
    Quarterly_Report__c qr = new Quarterly_Report__c(
      Quarter__c = '1st Quarter',
      Year__c = '2020'
    );
    insert qr;
    
    System.runAs(u){
      Test.startTest();
        List<Quarterly_Report__c> res = Portal_Controller.fetchQuarterlyReports();
      Test.stopTest();

      System.assertNotEquals(null, res);
      System.assertEquals(qr.Id, res[0].Id);
    }
  }



  // Giving History Components

  // MY GIVING HISTORY COMPONENT TESTS
  @isTest
  static void testFetchAllocations(){
    System.debug('testFetchAllocations');
    User u = [SELECT Id FROM User WHERE Username = 'portalTest@candoris.com.biblica' LIMIT 1];

    System.runAs(u){
      Test.startTest();
        List<Portal_Models.Gift> res = Portal_Controller.fetchAllocations();
      Test.stopTest();

      System.assertEquals(2, res.size());
      System.assertEquals(50, res[0].amount);
      System.assertEquals('USD', res[0].currencyType);
    }
  }
  @isTest
  static void testFetchStandardReceiptTemplate(){
    System.debug('testFetchStandardReceiptTemplate');
    List<Document_Template__c> dtList = [
      SELECT Id FROM Document_Template__c WHERE Name = 'Biblica Standard Receipt' LIMIT 1
    ];
    Id expectedResult = !dtList.isEmpty() ? dtList[0].Id : null;

    Test.startTest();
      Id res = Portal_Controller.fetchStandardReceiptTemplate();
    Test.stopTest();

    System.assertEquals(expectedResult, res);
  }
  @isTest
  static void testFetchReceiptTemplate(){
    System.debug('testFetchReceiptTemplate');
    User u = [SELECT Id FROM User WHERE Username = 'portalTest@candoris.com.biblica' LIMIT 1];

    System.runAs(u){
      Test.startTest();
        Portal_Models.ReceiptInfo res = Portal_Controller.fetchReceiptTemplate();
      Test.stopTest();

      System.assertNotEquals(null, res);
    }
  }



  // My Profile Page Components

  // MY PROFILE COMPONENT TESTS
  @isTest
  static void testFetchProfileInformation(){
    System.debug('testFetchProfileInformation');
    User u = [SELECT Id FROM User WHERE Username = 'portalTest@candoris.com.biblica' LIMIT 1];

    System.runAs(u){
      Test.startTest();
        Portal_Models.ProfileInfo res = Portal_Controller.fetchProfileInformation();
      Test.stopTest();

      System.assertNotEquals(null, res);
    }
  }
  @isTest
  static void testGetPicklistInfo(){
    System.debug('testGetPicklistInfo');
    Test.startTest();
      Map<String, Portal_Models.PicklistInfo> res = Portal_Controller.getPicklistValues();
    Test.stopTest();

    System.assertEquals(5, res.size());
    System.assertNotEquals(null, res.get('npe01__PreferredPhone__c'));
    System.assertNotEquals(null, res.get('Language_Preference__c'));
  }
  @isTest
  static void testUpdateAccount(){
    System.debug('testUpdateAccount');
    Account acct = new Account();
    acct.Name = 'Test Account';
    insert acct;

    acct.Name = 'New Name';

    Test.startTest();
      Portal_Controller.updateAccount(acct);
    Test.stopTest();

    Account res = [SELECT Id, Name FROM Account WHERE Id = :acct.Id LIMIT 1];
    System.assertEquals('New Name', res.Name);
  }

  // MY ACTIVE RECURRING DONATIONS COMPONENT TESTS
  // The fetchSubscription and updateSubscriptionPaymentMethod tests are covered in the ManageAuthNetSubscriptionControllerTest class.
  @isTest
  static void testFetchActiveRecurringDonations(){
    System.debug('testFetchActiveRecurringDonations');
    User u = [SELECT Id FROM User WHERE Username = 'portalTest@candoris.com.biblica' LIMIT 1];

    System.runAs(u){
      Test.startTest();
        List<npe03__Recurring_Donation__c> rdList = Portal_Controller.fetchActiveRecurringDonations();
      Test.stopTest();
    
      System.assertEquals(1, rdList.size());
    }
  }
  @isTest
  static void testPaymentMethodUpdate(){
    System.debug('testPaymentMethodUpdate');
    User u = [SELECT Id FROM User WHERE Username = 'portalTest@candoris.com.biblica' LIMIT 1];
    npe03__Recurring_Donation__c rd = [SELECT Id FROM npe03__Recurring_Donation__c LIMIT 1];
    Portal_Models.PaymentMethodInfo pmi = new Portal_Models.PaymentMethodInfo();
    pmi.id = 'PP456';

    System.runAs(u){
      Test.startTest();
        String res = Portal_AuthNetController.updateSubscriptionPaymentMethod(rd.Id, null, pmi);
      Test.stopTest();
    
      System.assertEquals('Successful.', res);
    }
  }
  

  // MY SAVED PAYMENT METHODS COMPONENT METHODS
  @isTest
  static void testFetchSavedPaymentMethods(){
    System.debug('testFetchSavedPaymentMethods');
    User u = [SELECT Id, ContactId FROM User WHERE Username = 'portalTest@candoris.com.biblica' LIMIT 1];
    Customer_Profile__c cp = new Customer_Profile__c();
    cp.Payment_Profile_Id__c = '34561675';
    cp.Customer_Profile_Id__c = '38010035';
    cp.Contact__c = u.ContactId;
    insert cp;

    System.runAs(u){
      Test.startTest();
        List<Portal_Models.PaymentMethodInfo> res = Portal_Controller.fetchSavedPaymentMethods();
      Test.stopTest();
    
      System.assertNotEquals(null, res);
    }
  }
  @isTest
  static void testNewPaymentMethodGetProfile(){
    System.debug('testNewPaymentMethod');
    User u = [SELECT Id, ContactId FROM User WHERE Username = 'portalTest@candoris.com.biblica' LIMIT 1];
    
    Customer_Profile__c cp = new Customer_Profile__c();
    cp.Payment_Profile_Id__c = '34561675';
    cp.Customer_Profile_Id__c = '38010035';
    cp.Contact__c = u.ContactId;
    insert cp;

    Map<String, String> pmi = new Map<String, String>();
    pmi.put('paymentMethod', 'Credit Card');
    pmi.put('cardNumber', '1111222233334444');
    pmi.put('cvv', '123');
    pmi.put('selectedMonth', '11');
    pmi.put('selectedYear', '2023');
    pmi.put('accountHolder', null);
    pmi.put('routingNumber', null);
    pmi.put('accountNumber', null);

    System.runAs(u){
      Test.startTest();
        Boolean res = Portal_Controller.newPaymentMethod(pmi);
      Test.stopTest();

      System.assertNotEquals(null, res);
    }
  }
  @isTest
  static void testNewPaymentMethodBuildProfile(){
    System.debug('testNewPaymentMethod');
    User u = [SELECT Id, Contact_Id__c FROM User WHERE Username = 'portalTest@candoris.com.biblica' LIMIT 1];

    Map<String, String> pmi = new Map<String, String>();
    pmi.put('paymentMethod', 'Credit Card');
    pmi.put('cardNumber', '1111222233334444');
    pmi.put('cvv', '123');
    pmi.put('selectedMonth', '11');
    pmi.put('selectedYear', '2023');
    pmi.put('accountHolder', null);
    pmi.put('routingNumber', null);
    pmi.put('accountNumber', null);

    System.runAs(u){
      Test.startTest();
        Boolean res = Portal_Controller.newPaymentMethod(pmi);
      Test.stopTest();

      System.assertNotEquals(null, res);
    }
  }
  @isTest
  static void testUpdatePaymentMethod(){
    System.debug('testUpdatePaymentMethod');
    User u = [SELECT Id, Contact_Id__c FROM User WHERE Username = 'portalTest@candoris.com.biblica' LIMIT 1];
    
    String paymentMethod = '{"cardLastFour":"XXXX7946","cardType":"MasterCard","customerId":"1516004967","expirationDate":"03/22","hasActiveSubscription":false,"id":"1514119579","paymentMethod":"Credit Card","subscriptionIds":[]}';

    Map<String, String> pmi = new Map<String, String>();
    pmi.put('paymentMethod', 'Credit Card');
    pmi.put('cardNumber', '1111222233334444');
    pmi.put('cvv', '123');
    pmi.put('selectedMonth', '11');
    pmi.put('selectedYear', '2023');
    pmi.put('accountHolder', null);
    pmi.put('routingNumber', null);
    pmi.put('accountNumber', null);

    System.runAs(u){
      Test.startTest();
        Boolean res = Portal_Controller.updatePaymentMethod(pmi, paymentMethod);
      Test.stopTest();

      System.assertNotEquals(null, res);
    }
  }
  @isTest
  static void testDeletePaymentMethod(){
    System.debug('testDeletePaymentMethod');
    User u = [SELECT Id, Contact_Id__c FROM User WHERE Username = 'portalTest@candoris.com.biblica' LIMIT 1];

    String paymentMethod = '{"cardLastFour":"XXXX7946","cardType":"MasterCard","customerId":"1516004967","expirationDate":"03/22","hasActiveSubscription":false,"id":"1514119579","paymentMethod":"Credit Card","subscriptionIds":[]}';

    System.runAs(u){
      Test.startTest();
        Boolean res = Portal_Controller.deletePaymentMethod(paymentMethod);
      Test.stopTest();
    }
  }
  @isTest
  static void testDeleteCustomerProfile(){
    System.debug('testDeleteCustomerProfile');
    Contact c = [SELECT Id FROM Contact LIMIT 1];
    Customer_Profile__c cp = new Customer_Profile__c();
    cp.Contact__c = c.Id;
    cp.Customer_Profile_Id__c = '54321';
    cp.Payment_Profile_Id__c = '12345';
    insert cp;
    
    // This test is for code coverage.
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new AuthorizeNetServiceMock());
      Boolean res = Portal_AuthNetController.deleteCustomerPaymentProfile('12345', '54321');
    Test.stopTest();
  }
  @isTest
  static void testDeleteSalesforceCustomerProfile(){
    System.debug('testDeleteSalesforceCustomerProfile');
    Contact c = [SELECT Id FROM Contact LIMIT 1];
    Customer_Profile__c cp = new Customer_Profile__c();
    cp.Contact__c = c.Id;
    cp.Customer_Profile_Id__c = '54321';
    cp.Payment_Profile_Id__c = '12345';
    insert cp;

    Test.startTest();
      Boolean res = Portal_AuthNetController.deleteSalesforceCustomerProfile('54321', '12345');
    Test.stopTest();

    System.assertEquals(true, res);
  }



  // Give Page

  // PORTAL DONATION PAGE COMPONENT METHODS
  // The createSelectedDonationOptions, getPortalDonationPageCampaign, and createRecurringDonation methods are all tested within the testCreateOneTimeDonationFormSubmission and testCreateRecurringDonationFormSubmission methods.
  @isTest
  static void testFetchDonationPageInformationOppId(){
    System.debug('testFetchDonationPageInformationOppId');
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    User u = [SELECT Id, ContactId FROM User WHERE Username = 'portalTest@candoris.com.biblica' LIMIT 1];

    System.runAs(u){
      Test.startTest();
        Portal_Models.DonationPageInfo res = Portal_Controller.fetchDonationPageInformation(opp.Id);
      Test.stopTest();
  
      System.assertNotEquals(null, res);
      System.assertEquals(u.ContactId, res.contact.Id);
      // System.assertNotEquals(0, res.selectedFunds.size());
      // System.assertEquals(0, res.paymentMethods.size());
      System.assertNotEquals(null, res.exchangeRates);
      System.assertEquals(opp.Id, res.previousOpp.Id);
    }
  }
  @isTest
  static void testFetchDonationPageInformationGauId(){
    System.debug('testFetchDonationPageInformationGauId');
    npsp__General_Accounting_Unit__c gau = [SELECT Id FROM npsp__General_Accounting_Unit__c LIMIT 1];
    User u = [SELECT Id, ContactId FROM User WHERE Username = 'portalTest@candoris.com.biblica' LIMIT 1];

    System.runAs(u){
      Test.startTest();
        Portal_Models.DonationPageInfo res = Portal_Controller.fetchDonationPageInformation(gau.Id);
      Test.stopTest();
  
      System.assertNotEquals(null, res);
      System.assertEquals(u.ContactId, res.contact.Id);
    }
  }
  @isTest
  static void testCreateOneTimeDonationFormSubmission(){
    System.debug('testCreateDonationFormSubmission');
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    User u = [SELECT Id, Contact_Id__c FROM User WHERE Username = 'portalTest@candoris.com.biblica' LIMIT 1];
    Id conId = u.Contact_Id__c;
    Id gauId = [SELECT Id FROM npsp__General_Accounting_Unit__c LIMIT 1].Id;
    Id acctId = [SELECT Id FROM Account LIMIT 1].Id;
    
    String submission = '{"total":51.8,"subtotal":50.0,"startDate":"2020-10-20","selectedFunds":[{"percent":100,"name":"317-Where Needed Most","id":"' + gauId + '","amount":50.0}],"selectedFund":null,"paymentMethod":{"subscriptionIds":["6993300"],"routingNumber":null,"paymentMethod":"Credit Card","label":"Visa XXXX1111","id":"9876543210","hasActiveSubscription":true,"expirationDate":"04/23","customerId":"1234567890","cardType":"Visa","cardLastFour":"XXXX1111","bankName":null,"accountNumber":null},"frequency":"One-Time","currencyType":"USD","coverFees":true,"contact":{"attributes":{"type":"Contact","url":"/services/data/v50.0/sobjects/Contact/' + conId + '"},"Account":{"attributes":{"type":"Account","url":"/services/data/v50.0/sobjects/Account/' + acctId + '"},"Language_Preference__c":"English","Id":"' + acctId + '"},"Email":"test@candoris.com","AccountId":"' + acctId + '","FirstName":"First","Phone":"9875643210","MailingPostalCode":"12345","MailingCountry":"Chile","MailingCity":"Vina del Mar","Id":"' + conId + '","LastName":"Last","MailingStreet":"Calle Oller 330","MailingState":"Lugar"}}';


    System.runAs(u){

      Test.startTest();
        Donation_Form_Submission__c res = Portal_Controller.createDonationFormSubmission(submission);
      Test.stopTest();

      System.assertNotEquals(null, res);
    }
  }
  @isTest
  static void testCreateRecurringDonationFormSubmission(){
    System.debug('testCreateDonationFormSubmission');
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    User u = [SELECT Id, Contact_Id__c FROM User WHERE Username = 'portalTest@candoris.com.biblica' LIMIT 1];
    Id conId = u.Contact_Id__c;
    Id gauId = [SELECT Id FROM npsp__General_Accounting_Unit__c LIMIT 1].Id;
    Id acctId = [SELECT Id FROM Account LIMIT 1].Id;
    
    String submission = '{"total":15.0,"subtotal":15.0,"startDate":"2020-10-20","selectedFunds":[{"percent":100,"name":"317-Where Needed Most","id":"' + gauId + '","amount":15.0}],"selectedFund":null,"paymentMethod":{"subscriptionIds":["1234567"],"routingNumber":null,"paymentMethod":"Credit Card","label":"Visa XXXX1111","id":"1514043171","hasActiveSubscription":true,"expirationDate":"04/23","customerId":"1516004967","cardType":"Visa","cardLastFour":"XXXX1111","bankName":null,"accountNumber":null},"frequency":"Monthly","currencyType":"EUR","coverFees":false,"contact":{"attributes":{"type":"Contact","url":"/services/data/v50.0/sobjects/Contact/' + conId + '"},"Account":{"attributes":{"type":"Account","url":"/services/data/v50.0/sobjects/Account/' + acctId + '"},"Language_Preference__c":"English","Id":"' + acctId + '"},"Email":"test@candoris.com","AccountId":"' + acctId + '","FirstName":"First","Phone":"9875643210","MailingPostalCode":"12345","MailingCountry":"Chile","MailingCity":"Vina del Mar","Id":"' + conId + '","LastName":"Last","MailingStreet":"Calle Oller 330","MailingState":"Lugar"}}';

    System.runAs(u){
      Test.startTest();
        Donation_Form_Submission__c res = Portal_Controller.createDonationFormSubmission(submission);
      Test.stopTest();

      System.assertNotEquals(null, res);
    }
  }
}