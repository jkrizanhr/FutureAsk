@isTest
private class MonthlyGiverJobTest {
  @testSetup 
  static void insertData() {
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
  static void testGuardianAssignment(){
    Account acct = new Account(
      Name = 'Test Account'
    );
    insert acct;

    npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
      Name = 'Test Recurring Donation',
      npe03__Installment_Period__c = 'Monthly',
      npsp__InstallmentFrequency__c = 1,
      npe03__Organization__c = acct.Id, 
      npsp__PaymentMethod__c = 'Credit Card',
      npe03__Amount__c = 100,
      npsp__Status__c = 'Active'
    );
    insert rd;

    Opportunity opp = new Opportunity(
      Name = 'opp',
      Original_Amount__c = 10,
      Original_Currency__c = 'USD',
      AccountId = acct.Id,
      CloseDate = Date.today().addMonths(-1),
      StageName = 'Posted',
      Payment_Method__c = 'Credit Card',
      npe03__Recurring_Donation__c = rd.Id
    );
    insert opp;

    Test.startTest();
      Database.executeBatch(new MonthlyGiverJob(), 1);
    Test.stopTest();
    
    List<Account> results = [SELECT Id, Monthly_Giver__c FROM Account WHERE Id = :acct.Id];
    System.assertEquals('Guardian', results[0].Monthly_Giver__c);
  }

  @isTest
  static void testAutoGiverAssignment(){
    Account acct = new Account(
      Name = 'Test Account'
    );
    insert acct;

    npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
      Name = 'Test Recurring Donation',
      npe03__Installment_Period__c = 'Monthly',
      npsp__InstallmentFrequency__c = 3,
      npe03__Organization__c = acct.Id, 
      npsp__PaymentMethod__c = 'Credit Card',
      npe03__Amount__c = 10,
      npsp__Status__c = 'Active'
    );
    insert rd;

    Opportunity opp = new Opportunity(
      Name = 'opp',
      Original_Amount__c = 10,
      Original_Currency__c = 'USD',
      AccountId = acct.Id,
      CloseDate = Date.today().addMonths(-1),
      StageName = 'Posted',
      Payment_Method__c = 'Credit Card',
      npe03__Recurring_Donation__c = rd.Id
    );
    insert opp;

    Test.startTest();
      Database.executeBatch(new MonthlyGiverJob(), 1);
    Test.stopTest();
    
    List<Account> results = [SELECT Id, Monthly_Giver__c FROM Account WHERE Id = :acct.Id];
    System.assertEquals('Auto-Giver', results[0].Monthly_Giver__c);
  }

  @isTest
  static void testDonorAssignment(){
    Account acct = new Account(
      Name = 'Test Account'
    );
    insert acct;

    Opportunity opp1 = new Opportunity(
      Name = 'opp1',
      Original_Amount__c = 10,
      Original_Currency__c = 'USD',
      AccountId = acct.Id,
      CloseDate = Date.today().addMonths(-1),
      StageName = 'Posted',
      Payment_Method__c = 'Credit Card'
    );
    Opportunity opp2 = new Opportunity(
      Name = 'opp2',
      Original_Amount__c = 10,
      Original_Currency__c = 'USD',
      AccountId = acct.Id,
      CloseDate = Date.today().addMonths(-2),
      StageName = 'Posted',
      Payment_Method__c = 'Credit Card'
    );
    Opportunity opp3 = new Opportunity(
      Name = 'opp3',
      Original_Amount__c = 10,
      Original_Currency__c = 'USD',
      AccountId = acct.Id,
      CloseDate = Date.today().addMonths(-3),
      StageName = 'Posted',
      Payment_Method__c = 'Credit Card'
    );
    Opportunity opp4 = new Opportunity(
      Name = 'opp4',
      Original_Amount__c = 10,
      Original_Currency__c = 'USD',
      AccountId = acct.Id,
      CloseDate = Date.today().addMonths(-4),
      StageName = 'Posted',
      Payment_Method__c = 'Credit Card'
    );
    Opportunity opp5 = new Opportunity(
      Name = 'opp5',
      Original_Amount__c = 10,
      Original_Currency__c = 'USD',
      AccountId = acct.Id,
      CloseDate = Date.today().addMonths(-5),
      StageName = 'Posted',
      Payment_Method__c = 'Credit Card'
    );
    Opportunity opp6 = new Opportunity(
      Name = 'opp6',
      Original_Amount__c = 10,
      Original_Currency__c = 'USD',
      AccountId = acct.Id,
      CloseDate = Date.today().addMonths(-6),
      StageName = 'Posted',
      Payment_Method__c = 'Credit Card'
    );
    insert new List<Opportunity>{opp1, opp2, opp3, opp4, opp5, opp6};

    Test.startTest();
      Database.executeBatch(new MonthlyGiverJob(), 1);
    Test.stopTest();
    
    List<Account> results = [SELECT Id, Monthly_Giver__c FROM Account WHERE Id = :acct.Id];
    System.assertEquals('Regular Donor', results[0].Monthly_Giver__c);
  }

  @isTest
  static void testNotApplicableAssignment(){
    Account acct = new Account(
      Name = 'Test Account'
    );
    insert acct;

    Opportunity opp1 = new Opportunity(
      Name = 'opp1',
      Original_Amount__c = 10,
      Original_Currency__c = 'USD',
      AccountId = acct.Id,
      CloseDate = Date.today().addMonths(-1),
      StageName = 'Posted',
      Payment_Method__c = 'Credit Card'
    );
    Opportunity opp2 = new Opportunity(
      Name = 'opp2',
      Original_Amount__c = 10,
      Original_Currency__c = 'USD',
      AccountId = acct.Id,
      CloseDate = Date.today().addMonths(-2),
      StageName = 'Posted',
      Payment_Method__c = 'Credit Card'
    );
    insert new List<Opportunity>{opp1, opp2};

    Test.startTest();
      Database.executeBatch(new MonthlyGiverJob(), 1);
    Test.stopTest();
    
    List<Account> results = [SELECT Id, Monthly_Giver__c FROM Account WHERE Id = :acct.Id];
    System.assertEquals('Not Applicable', results[0].Monthly_Giver__c);
  }

  @isTest
  static void testOtherAssignments(){
    Account acct = new Account(
      Name = 'Test Account',
      Override_Monthly_Giver_Type__c = true,
      Monthly_Giver__c = 'Guardian'
    );
    insert acct;

    Opportunity opp1 = new Opportunity(
      Name = 'opp1',
      Original_Amount__c = 10,
      Original_Currency__c = 'USD',
      AccountId = acct.Id,
      CloseDate = Date.today().addMonths(-1),
      StageName = 'Posted',
      Payment_Method__c = 'Credit Card'
    );
    Opportunity opp2 = new Opportunity(
      Name = 'opp2',
      Original_Amount__c = 10,
      Original_Currency__c = 'USD',
      AccountId = acct.Id,
      CloseDate = Date.today().addMonths(-2),
      StageName = 'Posted',
      Payment_Method__c = 'Credit Card'
    );
    insert new List<Opportunity>{opp1, opp2};

    Test.startTest();
      Database.executeBatch(new MonthlyGiverJob(), 1);
    Test.stopTest();
    
    List<Account> results = [SELECT Id, Monthly_Giver__c FROM Account WHERE Id = :acct.Id];
    System.assertEquals('Guardian', results[0].Monthly_Giver__c);
  }

  @isTest
  static void testCheckAmountAndCheckFrequency(){
    Account acct = new Account(
      Name = 'Test Account'
    );
    insert acct;

    npe03__Recurring_Donation__c weeklyRD = new npe03__Recurring_Donation__c(
      Name = 'Test Recurring Donation',
      npe03__Installment_Period__c = 'Weekly',
      npsp__InstallmentFrequency__c = 8,
      npe03__Organization__c = acct.Id, 
      npsp__PaymentMethod__c = 'Credit Card',
      npe03__Amount__c = 200,
      npsp__Status__c = 'Active'
    );
    insert weeklyRD;
    
    npe03__Recurring_Donation__c firstAndFifteenRD = new npe03__Recurring_Donation__c(
      Name = 'Test Recurring Donation',
      npe03__Installment_Period__c = '1st and 15th',
      npsp__InstallmentFrequency__c = 2,
      npe03__Organization__c = acct.Id, 
      npsp__PaymentMethod__c = 'Credit Card',
      npe03__Amount__c = 5,
      npsp__Status__c = 'Active'
    );
    insert firstAndFifteenRD;
    
    npe03__Recurring_Donation__c yearlyRD = new npe03__Recurring_Donation__c(
      Name = 'Test Recurring Donation',
      npe03__Installment_Period__c = 'Yearly',
      npsp__InstallmentFrequency__c = 1,
      npe03__Organization__c = acct.Id, 
      npsp__PaymentMethod__c = 'Credit Card',
      npe03__Amount__c = 5,
      npsp__Status__c = 'Active'
    );
    insert yearlyRD;

    Test.startTest();
      Boolean res1 = MonthlyGiverJobService.checkAmount(weeklyRD);
      Boolean res2 = MonthlyGiverJobService.checkAmount(firstAndFifteenRD);
      Boolean res3 = MonthlyGiverJobService.checkAmount(yearlyRD);
      Boolean res4 = MonthlyGiverJobService.checkFrequency(weeklyRD);
      Boolean res5 = MonthlyGiverJobService.checkFrequency(firstAndFifteenRD);
      Boolean res6 = MonthlyGiverJobService.checkFrequency(yearlyRD);
    Test.stopTest();

    System.assertEquals(true, res1, 'The amount received monthly is greater than seven dollars.');
    System.assertEquals(true, res2, 'The amount received monthly is greater than seven dollars.');
    System.assertEquals(false, res3, 'The amount received monthly is not greater than seven dollars.');
    System.assertEquals(false, res4, 'A donation will be received at least ten times each year.');
    System.assertEquals(true, res5, 'A donation will be received at least ten times each year.');
    System.assertEquals(false, res6, 'A donation will be received at least ten times each year.');
  }

  @IsTest
  static void testScheduleJob() {
    Test.startTest();
      String jobId = MonthlyGiverJob.schedule('Monthly Giver Job Unit Test', null);
    Test.stopTest();

    CronTrigger ct = [
      SELECT Id,
      CronExpression,
      TimesTriggered,
      NextFireTime
      FROM CronTrigger
      WHERE Id = :jobId
    ];

    System.assertEquals('0 0 3 * * ?', ct.CronExpression);
    System.assertEquals(0, ct.TimesTriggered);
    System.assert(ct.NextFireTime != null);
  }
}