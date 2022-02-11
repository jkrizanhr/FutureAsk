@isTest
private class RecalculateOpportunityRollupsJobTest {
  @testSetup 
  static void insertData() {
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

    User receiptingUser = UnitTestHelper.createStandardUser();
    receiptingUser.IsActive = true;
    receiptingUser.Receipting_Assignments__c = 'Large';
    insert receiptingUser;

    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Type__c = 'Cash and Checks';
    cb.Opportunity_Type__c = 'Donation';
    cb.Batch_Variation__c = 'A';
    cb.Date__c = Date.today();
    cb.Original_Currency__c = 'USD';
    cb.Keyer__c = receiptingUser.Id;
    insert cb;

    Account acct = new Account();
    acct.Name = 'Test Account';
    insert acct;

    Opportunity opp1 = new Opportunity(
      Name = 'Test Opportunity',
      AccountId = acct.Id,
      Original_Amount__c = 100,
      Original_Currency__c = 'USD',
      Cash_Batch__c = cb.Id,
      StageName = 'Posted',
      CloseDate = Date.today()
    );
    insert opp1;
    
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c(
      Name = 'Test GAU',
      Purpose_Code__c = '123'
    );
    insert gau;

    npsp__Allocation__c alloc1 = new npsp__Allocation__c(
      npsp__General_Accounting_Unit__c = gau.Id,
      npsp__Opportunity__c = opp1.Id,
      Original_Currency__c = 'USD',
      Original_Amount__c = 50,
      Tax_Deductible__c = true
    );
    npsp__Allocation__c alloc2 = new npsp__Allocation__c(
      npsp__General_Accounting_Unit__c = gau.Id,
      npsp__Opportunity__c = opp1.Id,
      Original_Currency__c = 'USD',
      Original_Amount__c = 50,
      Tax_Deductible__c = false
    );
    insert new List<npsp__Allocation__c>{alloc1, alloc2};
  }

  @IsTest
  static void testSchedule() {
    Test.startTest();
    String jobId = RecalculateOpportunityRollupsJob.schedule(null, null, null);
    Test.stopTest();

    CronTrigger ct = [
      SELECT Id, CronExpression, TimesTriggered, NextFireTime
      FROM CronTrigger
      WHERE Id = :jobId
    ];

    System.assert(String.isNotBlank(jobId));
    System.assert(ct.NextFireTime != null);
  }

  @isTest
  static void testBatchJob() {
    Test.startTest();
    new RecalculateOpportunityRollupsJob();
    Test.stopTest();

    Opportunity opp = [
      SELECT
        Id,
        Sum_of_GAU_Allocations__c
      FROM Opportunity
      ORDER BY LastModifiedDate DESC
      LIMIT 1
    ];

    System.assert(opp.Sum_of_GAU_Allocations__c == 100);
  }

  @isTest
  static void testBatchJobWithGivenWhereClause() {
    Test.startTest();
    new RecalculateOpportunityRollupsJob(
      'WHERE StageName = \'Posted\''
    );
    Test.stopTest();

    Opportunity opp = [
      SELECT
        Id,
        Sum_of_GAU_Allocations__c
      FROM Opportunity
      ORDER BY LastModifiedDate DESC
      LIMIT 1
    ];

    System.assert(opp.Sum_of_GAU_Allocations__c == 100);
  }
}