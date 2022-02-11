@isTest
private class HistoricalTransactionProcessingJobTest {
  @testSetup
  static void createData() {
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
  }

  @isTest
  static void testNewContactTransaction() {
    Historical_Transaction__c ht = new Historical_Transaction__c();
    ht.Transaction_Id__c = '12345';
    ht.Subscription_Id__c = '54321';
    ht.Type__c = 'Authorize.net';
    ht.Status__c = 'settledSuccessfully';
    ht.Amount__c = 50;
    ht.Email__c = 'test@test.test';
    ht.First_Name__c = 'test';
    ht.Last_Name__c = 'test';
    ht.Phone__c = '5555555555';
    ht.Billing_Street__c = '123 Test Street';
    ht.Billing_Street_2__c = 'Apt. 2';
    ht.Billing_City__c = 'Harrisburg';
    ht.Billing_State_Province__c = 'PA';
    ht.Billing_Postal_Code__c = '17101';
    ht.Billing_Country__c = 'USA';
    ht.Create_Time__c = Datetime.newInstance(2021, 3, 1);
    ht.Settlement_Date__c = Datetime.newInstance(2021, 3, 2);
    ht.Retrieved_Details__c = true;
    insert ht;

    Test.startTest();
    HistoricalTransactionProcessingJob.schedule('HT Processing Job Test', null);
    HistoricalTransactionProcessingJob.run();
    Test.stopTest();

    List<Contact> contactResult = [SELECT Id, Email FROM Contact];
    System.assertEquals(ht.Email__c, contactResult[0].Email);

    List<npe03__Recurring_Donation__c> rdResult = [
      SELECT Id, npe03__Contact__c, npe03__Amount__c
      FROM npe03__Recurring_Donation__c
    ];
    System.assertEquals(contactResult[0].Id, rdResult[0].npe03__Contact__c);
    System.assertEquals(ht.Amount__c, rdResult[0].npe03__Amount__c);

    List<Opportunity> oppResult = [
      SELECT Id, Amount, npsp__Primary_Contact__c, npe03__Recurring_Donation__c
      FROM Opportunity
      WHERE IsWon = true
    ];
    System.assertEquals(
      contactResult[0].Id,
      oppResult[0].npsp__Primary_Contact__c
    );
    System.assertEquals(ht.Amount__c, oppResult[0].Amount);
    System.assertEquals(
      rdResult[0].Id,
      oppResult[0].npe03__Recurring_Donation__c
    );
  }

  @isTest
  static void testNoLastNameTransaction() {
    Historical_Transaction__c ht = new Historical_Transaction__c();
    ht.Transaction_Id__c = '12345';
    ht.Subscription_Id__c = '54321';
    ht.Type__c = 'Authorize.net';
    ht.Status__c = 'settledSuccessfully';
    ht.Amount__c = 50;
    ht.Email__c = 'test@test.test';
    ht.First_Name__c = 'test';
    ht.Last_Name__c = null;
    ht.Phone__c = '5555555555';
    ht.Billing_Street__c = '123 Test Street';
    ht.Billing_Street_2__c = 'Apt. 2';
    ht.Billing_City__c = 'Harrisburg';
    ht.Billing_State_Province__c = 'PA';
    ht.Billing_Postal_Code__c = '17101';
    ht.Billing_Country__c = 'USA';
    ht.Create_Time__c = Datetime.newInstance(2021, 3, 1);
    ht.Settlement_Date__c = Datetime.newInstance(2021, 3, 2);
    ht.Retrieved_Details__c = true;
    insert ht;

    try {
      Test.startTest();
      HistoricalTransactionProcessingJob.run();
      Test.stopTest();
      System.assert(false, 'Expecting an error');
    } catch (Exception e) {
      String errMsg = e.getMessage();
      System.assert(errMsg.contains('No contact found'));
    }

    List<Contact> contactResult = [SELECT Id, Email FROM Contact];
    System.assertEquals(0, contactResult.size());
  }

  @isTest
  static void testExistingContactRecurringDonation() {
    Account acct = new Account();
    acct.Name = 'Test Household';
    acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('HH_Account')
      .getRecordTypeId();
    insert acct;

    Contact c = new Contact();
    c.FirstName = 'Test';
    c.LastName = 'Test';
    c.Email = 'test@test.test';
    c.AccountId = acct.Id;
    insert c;

    npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
    rd.Name = 'Recurring Donation';
    rd.Subscription_Id__c = '54321';
    rd.npe03__Contact__c = c.Id;
    rd.npsp__RecurringType__c = 'Open';
    rd.npsp__InstallmentFrequency__c = 1;
    rd.npe03__Date_Established__c = Date.today();
    rd.npe03__Installment_Period__c = 'Monthly';
    rd.npsp__Day_of_Month__c = '1';
    rd.npe03__Amount__c = 50;
    rd.Original_Amount__c = 50;
    rd.Original_Currency__c = 'USD';
    rd.Region_Category__c = 'United States';
    insert rd;
    delete [
      SELECT Id
      FROM Opportunity
      WHERE npe03__Recurring_Donation__c = :rd.Id
    ];

    Historical_Transaction__c ht = new Historical_Transaction__c();
    ht.Transaction_Id__c = '12345';
    ht.Subscription_Id__c = '54321';
    ht.Customer_Id__c = '67890';
    ht.Payment_Profile_Id__c = '09876';
    ht.Type__c = 'Authorize.net';
    ht.Status__c = 'settledSuccessfully';
    ht.Amount__c = 50;
    ht.Email__c = 'test@test.test';
    ht.First_Name__c = 'test';
    ht.Last_Name__c = 'test';
    ht.Phone__c = '5555555555';
    ht.Billing_Street__c = '123 Test Street';
    ht.Billing_Street_2__c = 'Apt. 2';
    ht.Billing_City__c = 'Harrisburg';
    ht.Billing_State_Province__c = 'PA';
    ht.Billing_Postal_Code__c = '17101';
    ht.Billing_Country__c = 'USA';
    ht.Create_Time__c = Datetime.newInstance(2021, 3, 1);
    ht.Settlement_Date__c = Datetime.newInstance(2021, 3, 2);
    ht.Retrieved_Details__c = true;
    insert ht;

    Test.startTest();
    HistoricalTransactionProcessingJob.schedule('HT Processing Job Test', null);
    HistoricalTransactionProcessingJob.run();
    Test.stopTest();

    List<Contact> contactResult = [SELECT Id, Email FROM Contact];
    System.assertEquals(ht.Email__c, contactResult[0].Email);

    List<npe03__Recurring_Donation__c> rdResult = [
      SELECT Id, npe03__Contact__c, npe03__Amount__c
      FROM npe03__Recurring_Donation__c
    ];
    System.assertEquals(1, rdResult.size());
    System.assertEquals(contactResult[0].Id, rdResult[0].npe03__Contact__c);
    System.assertEquals(ht.Amount__c, rdResult[0].npe03__Amount__c);

    List<Opportunity> oppResult = [
      SELECT Id, Amount, npsp__Primary_Contact__c, npe03__Recurring_Donation__c
      FROM Opportunity
      WHERE IsWon = true
    ];
    System.assertEquals(
      contactResult[0].Id,
      oppResult[0].npsp__Primary_Contact__c
    );
    System.assertEquals(ht.Amount__c, oppResult[0].Amount);
    System.assertEquals(
      rdResult[0].Id,
      oppResult[0].npe03__Recurring_Donation__c
    );
  }

  @isTest
  static void testExistingContactOnDfsOpp() {
    Account acct = new Account();
    acct.Name = 'Test Household';
    acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('HH_Account')
      .getRecordTypeId();
    insert acct;

    Contact c = new Contact();
    c.FirstName = 'Test';
    c.LastName = 'Test';
    c.Email = 'test@test.test';
    c.AccountId = acct.Id;
    insert c;

    Opportunity opp = new Opportunity();
    opp.AccountId = acct.Id;
    opp.npsp__Primary_Contact__c = c.Id;
    opp.Amount = 50;
    opp.StageName = 'Posted';
    opp.CloseDate = Date.today();
    opp.Name = 'Test Opp';
    opp.Payment_Method__c = 'Credit Card';
    opp.Credit_Card_Type__c = 'Visa';
    insert opp;

    Donation_Form_Submission__c dfs = new Donation_Form_Submission__c();
    dfs.Opportunity__c = opp.Id;
    insert dfs;

    Historical_Transaction__c ht = new Historical_Transaction__c();
    ht.Transaction_Id__c = '12345';
    ht.Type__c = 'Authorize.net';
    ht.Status__c = 'settledSuccessfully';
    ht.Amount__c = 50;
    ht.Create_Time__c = Datetime.newInstance(2021, 3, 1);
    ht.Settlement_Date__c = Datetime.newInstance(2021, 3, 2);
    ht.Retrieved_Details__c = true;
    ht.Donation_Form_Submission__c = dfs.Id;
    insert ht;

    Test.startTest();
    HistoricalTransactionProcessingJob.schedule('HT Processing Job Test', null);
    HistoricalTransactionProcessingJob.run();
    Test.stopTest();

    List<Contact> contactResult = [SELECT Id FROM Contact];
    System.assertEquals(c.Id, contactResult[0].Id);

    List<Opportunity> oppResult = [
      SELECT Id, Amount, npsp__Primary_Contact__c, npe03__Recurring_Donation__c
      FROM Opportunity
      WHERE IsWon = true
    ];
    System.assertEquals(
      contactResult[0].Id,
      oppResult[0].npsp__Primary_Contact__c
    );
  }

  @isTest
  static void testExistingRecurringDonationFailedTransaction() {
    Account acct = new Account();
    acct.Name = 'Test Household';
    acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('HH_Account')
      .getRecordTypeId();
    insert acct;

    Contact c = new Contact();
    c.FirstName = 'Test';
    c.LastName = 'Test';
    c.Email = 'test@test.test';
    c.AccountId = acct.Id;
    insert c;

    npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
    rd.Name = 'Recurring Donation';
    rd.Subscription_Id__c = '54321';
    rd.npe03__Contact__c = c.Id;
    rd.npsp__RecurringType__c = 'Open';
    rd.npsp__InstallmentFrequency__c = 1;
    rd.npe03__Date_Established__c = Date.today();
    rd.npe03__Installment_Period__c = 'Monthly';
    rd.npsp__Day_of_Month__c = '1';
    rd.npe03__Amount__c = 50;
    rd.Original_Amount__c = 50;
    rd.Original_Currency__c = 'USD';
    insert rd;
    delete [
      SELECT Id
      FROM Opportunity
      WHERE npe03__Recurring_Donation__c = :rd.Id
    ];

    Historical_Transaction__c ht = new Historical_Transaction__c();
    ht.Transaction_Id__c = '12345';
    ht.Subscription_Id__c = '54321';
    ht.Customer_Id__c = '67890';
    ht.Payment_Profile_Id__c = '09876';
    ht.Type__c = 'Authorize.net';
    ht.Status__c = 'declined';
    ht.Amount__c = 50;
    ht.Email__c = 'test@test.test';
    ht.First_Name__c = 'test';
    ht.Last_Name__c = 'test';
    ht.Phone__c = '5555555555';
    ht.Billing_Street__c = '123 Test Street';
    ht.Billing_Street_2__c = 'Apt. 2';
    ht.Billing_City__c = 'Harrisburg';
    ht.Billing_State_Province__c = 'PA';
    ht.Billing_Postal_Code__c = '17101';
    ht.Billing_Country__c = 'USA';
    ht.Create_Time__c = Datetime.newInstance(2021, 3, 1);
    ht.Settlement_Date__c = Datetime.newInstance(2021, 3, 2);
    ht.Retrieved_Details__c = true;
    insert ht;

    Test.startTest();
    HistoricalTransactionProcessingJob.schedule('HT Processing Job Test', null);
    HistoricalTransactionProcessingJob.run();
    Test.stopTest();

    List<Contact> contactResult = [SELECT Id, Email FROM Contact];
    System.assertEquals(ht.Email__c, contactResult[0].Email);

    List<npe03__Recurring_Donation__c> rdResult = [
      SELECT Id, npe03__Contact__c, npe03__Amount__c
      FROM npe03__Recurring_Donation__c
    ];
    System.assertEquals(1, rdResult.size());
    System.assertEquals(contactResult[0].Id, rdResult[0].npe03__Contact__c);
    System.assertEquals(ht.Amount__c, rdResult[0].npe03__Amount__c);

    List<Opportunity> oppResult = [
      SELECT
        Id,
        Amount,
        npsp__Primary_Contact__c,
        npe03__Recurring_Donation__c,
        StageName
      FROM Opportunity
      WHERE StageName = 'Declined'
    ];
    System.assertEquals(
      contactResult[0].Id,
      oppResult[0].npsp__Primary_Contact__c
    );
    System.assertEquals(ht.Amount__c, oppResult[0].Amount);
    System.assertEquals(
      rdResult[0].Id,
      oppResult[0].npe03__Recurring_Donation__c
    );
  }

  @isTest
  static void testExistingOrganizationRecurringDonation() {
    Account acct = new Account();
    acct.Name = 'Test Company';
    acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('Organization')
      .getRecordTypeId();
    insert acct;

    Contact c = new Contact();
    c.FirstName = 'Test';
    c.LastName = 'Test';
    c.Email = 'test@test.test';
    insert c;

    npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
    rd.Name = 'Recurring Donation';
    rd.Subscription_Id__c = '54321';
    rd.npe03__Organization__c = acct.Id;
    rd.npe03__Date_Established__c = Date.today();
    rd.npsp__RecurringType__c = 'Open';
    rd.npsp__InstallmentFrequency__c = 1;
    rd.npe03__Installment_Period__c = 'Monthly';
    rd.npsp__Day_of_Month__c = '1';
    rd.npe03__Amount__c = 50;
    rd.Original_Amount__c = 50;
    rd.Original_Currency__c = 'USD';
    insert rd;
    delete [
      SELECT Id
      FROM Opportunity
      WHERE npe03__Recurring_Donation__c = :rd.Id
    ];

    Historical_Transaction__c ht = new Historical_Transaction__c();
    ht.Transaction_Id__c = '12345';
    ht.Subscription_Id__c = '54321';
    ht.Customer_Id__c = '67890';
    ht.Payment_Profile_Id__c = '09876';
    ht.Type__c = 'Authorize.net';
    ht.Status__c = 'settledSuccessfully';
    ht.Amount__c = 50;
    ht.Email__c = 'test@test.test';
    ht.First_Name__c = 'test';
    ht.Last_Name__c = 'test';
    ht.Phone__c = '5555555555';
    ht.Billing_Street__c = '123 Test Street';
    ht.Billing_Street_2__c = 'Apt. 2';
    ht.Billing_City__c = 'Harrisburg';
    ht.Billing_State_Province__c = 'PA';
    ht.Billing_Postal_Code__c = '17101';
    ht.Billing_Country__c = 'USA';
    ht.Create_Time__c = Datetime.newInstance(2021, 3, 1);
    ht.Settlement_Date__c = Datetime.newInstance(2021, 3, 2);
    ht.Retrieved_Details__c = true;
    insert ht;

    Test.startTest();
    HistoricalTransactionProcessingJob.schedule('HT Processing Job Test', null);
    HistoricalTransactionProcessingJob.run();
    Test.stopTest();

    List<npe03__Recurring_Donation__c> rdResult = [
      SELECT Id, npe03__Organization__c, npe03__Amount__c
      FROM npe03__Recurring_Donation__c
    ];
    System.assertEquals(1, rdResult.size());
    System.assertEquals(acct.Id, rdResult[0].npe03__Organization__c);
    System.assertEquals(ht.Amount__c, rdResult[0].npe03__Amount__c);

    List<Opportunity> oppResult = [
      SELECT Id, Amount, AccountId, npe03__Recurring_Donation__c
      FROM Opportunity
      WHERE IsWon = true
    ];
    System.assertEquals(acct.Id, oppResult[0].AccountId);
    System.assertEquals(ht.Amount__c, oppResult[0].Amount);
    System.assertEquals(
      rdResult[0].Id,
      oppResult[0].npe03__Recurring_Donation__c
    );
  }

  @isTest
  static void testSchedulingJobWithName() {
    Account acct = new Account();
    acct.Name = 'Test Company';
    insert acct;

    Contact c = new Contact();
    c.FirstName = 'Test';
    c.LastName = 'Test';
    c.Email = 'test@test.test';
    c.AccountId = acct.Id;
    insert c;

    Historical_Transaction__c ht = new Historical_Transaction__c();
    ht.Transaction_Id__c = '12345';
    ht.Type__c = 'Authorize.net';
    ht.Status__c = 'settledSuccessfully';
    ht.Amount__c = 50;
    ht.Email__c = 'test@test.test';
    ht.First_Name__c = 'test';
    ht.Last_Name__c = 'test';
    ht.Phone__c = '5555555555';
    ht.Billing_Street__c = '123 Test Street';
    ht.Billing_Street_2__c = 'Apt. 2';
    ht.Billing_City__c = 'Harrisburg';
    ht.Billing_State_Province__c = 'PA';
    ht.Billing_Postal_Code__c = '17101';
    ht.Billing_Country__c = 'USA';
    ht.Create_Time__c = Datetime.newInstance(2021, 3, 1);
    ht.Settlement_Date__c = Datetime.newInstance(2021, 3, 2);
    ht.Retrieved_Details__c = true;
    insert ht;

    Test.startTest();
    HistoricalTransactionProcessingJob.schedule('HT Processing Job Test', null);
    HistoricalTransactionProcessingJob.run();
    Test.stopTest();
  }

  @isTest
  static void testScheduleJobWithNoJobName() {
    Account acct = new Account();
    acct.Name = 'Test Company';
    insert acct;

    Contact c = new Contact();
    c.FirstName = 'Test';
    c.LastName = 'Test';
    c.MailingStreet = '123 Test Street';
    c.Email = 'test@test.test';
    c.Phone = '5555555555';
    c.HomePhone = '5555555555';
    c.OtherPhone = '3333333333';
    c.AccountId = acct.Id;
    insert c;

    Historical_Transaction__c ht = new Historical_Transaction__c();
    ht.Transaction_Id__c = '12345';
    ht.Type__c = 'Authorize.net';
    ht.Status__c = 'settledSuccessfully';
    ht.Amount__c = 50;
    ht.Email__c = 'test@test.test';
    ht.First_Name__c = 'test';
    ht.Last_Name__c = 'test';
    ht.Phone__c = '5555555555';
    ht.Billing_Street__c = '123 Test Street';
    ht.Billing_Street_2__c = 'Apt. 2';
    ht.Billing_City__c = 'Harrisburg';
    ht.Billing_State_Province__c = 'PA';
    ht.Billing_Postal_Code__c = '17101';
    ht.Billing_Country__c = 'USA';
    ht.Create_Time__c = Datetime.newInstance(2021, 3, 1);
    ht.Settlement_Date__c = Datetime.newInstance(2021, 3, 2);
    ht.Retrieved_Details__c = true;
    insert ht;

    Test.startTest();
    HistoricalTransactionProcessingJob.schedule(null, null);
    HistoricalTransactionProcessingJob.run();
    Test.stopTest();
  }
}