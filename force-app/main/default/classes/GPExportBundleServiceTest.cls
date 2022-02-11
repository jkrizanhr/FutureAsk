@IsTest
private class GPExportBundleServiceTest {
  @TestSetup
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

  private static List<GP_Export_Bundle__c> retrieveBundles() {
    return [
      SELECT
        End_Date__c,
        Fund_GL_Error_Message__c,
        Fund_GL_Validation_Check__c,
        Id,
        Start_Date__c,
        Validation_Error__c
      FROM GP_Export_Bundle__c
    ];
  }

  private static List<GP_Export_AAGL_Row__c> retrieveAAGLRows() {
    return [
      SELECT
        Checkbook__c,
        Donation_Amount__c,
        Donation_Batch_Number__c,
        Donation_Date__c,
        Donation_ID__c,
        GAU_Allocation__c,
        GP_Export_Bundle__c,
        GP_Full_Account__c,
        GP_Natural_Account__c,
        Id,
        Name,
        Purpose_Code__c,
        SeqID__c
      FROM GP_Export_AAGL_Row__c
      ORDER BY SeqID__c
    ];
  }

  private static List<GP_Export_Deposit_Row__c> retrieveDepositRows() {
    return [
      SELECT
        Cash_Batch__c,
        Checkbook__c,
        Donation_Batch_Number__c,
        Donation_Date__c,
        GP_Export_Bundle__c,
        GP_Full_Account__c,
        Id,
        Name,
        SumOfDonation_Amount__c
      FROM GP_Export_Deposit_Row__c
    ];
  }

  private static List<GP_Export_Return_Row__c> retrieveReturnRows() {
    return [
      SELECT
        Cash_Batch__c,
        Checkbook__c,
        Donation_Batch_Number__c,
        Donation_Date__c,
        GP_Export_Bundle__c,
        GP_Full_Account__c,
        Id,
        Name,
        SumOfDonation_Amount__c
      FROM GP_Export_Return_Row__c
    ];
  }

  private static List<Cash_Batch__c> retrieveCashBatches() {
    return [SELECT GP_Export_Bundle__c, GP_Export_Error__c, Id, Name FROM Cash_Batch__c];
  }

  private static List<Opportunity> retrieveOpportunities() {
    return [SELECT GP_Export_Error__c, Id FROM Opportunity];
  }

  private static List<npsp__Allocation__c> retrieveAllocations() {
    return [SELECT GP_Export_Error__c, Id FROM npsp__Allocation__c];
  }

  @IsTest
  static void testSuccess() {
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test GAU';
    gau.npsp__Active__c = true;
    gau.Purpose_Code__c = '789';
    insert gau;

    Fund_GL_Account__c fundGLAccount = new Fund_GL_Account__c();
    fundGLAccount.Active__c = true;
    fundGLAccount.GL_Account__c = '1234-000-000';
    fundGLAccount.GL_Account_Prefix__c = '1234';
    fundGLAccount.GL_Account_External_Id__c = '789:1234-000-000';
    fundGLAccount.General_Accounting_Unit__c = gau.Id;
    insert fundGLAccount;

    Cash_Batch__c batch = new Cash_Batch__c();
    batch.Status__c = 'New';
    batch.Date__c = Date.today();
    batch.Type__c = 'Bank Accounts';
    batch.Name = String.valueOf(Date.today()) + 'BankAccount';
    insert batch;

    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opp';
    opp.AccountId = acc.Id;
    opp.CloseDate = Date.today();
    opp.Cash_Batch__c = batch.Id;
    opp.StageName = 'Closed Won';
    opp.Amount = 100;
    opp.Original_Amount__c = 100;
    opp.Original_Currency__c = 'USD';
    insert opp;

    npsp__Allocation__c all = new npsp__Allocation__c();
    all.npsp__Opportunity__c = opp.Id;
    all.npsp__Amount__c = 100;
    all.Original_Amount__c = 100;
    all.Original_Currency__c = 'USD';
    all.npsp__General_Accounting_Unit__c = gau.Id;
    all.Fund_GL_Account__c = fundGLAccount.Id;
    insert all;

    batch.Status__c = 'Approved';
    update batch;

    GP_Export_Bundle__c bundle = new GP_Export_Bundle__c();
    bundle.Start_Date__c = Date.today();
    bundle.End_Date__c = Date.today();
    bundle.RecordTypeId = Utils.getRecordTypeId('GP_Export_Bundle__c', 'Donation Income');

    Test.startTest();
    insert bundle;
    Test.stopTest();

    List<GP_Export_Bundle__c> bundles = retrieveBundles();
    List<GP_Export_AAGL_Row__c> aaglRows = retrieveAAGLRows();
    List<GP_Export_Deposit_Row__c> depositRows = retrieveDepositRows();
    List<GP_Export_Return_Row__c> returnRows = retrieveReturnRows();
    List<Cash_Batch__c> cashBatches = retrieveCashBatches();
    List<Opportunity> opps = retrieveOpportunities();
    List<npsp__Allocation__c> allocations = retrieveAllocations();

    System.assertEquals(1, cashBatches.size());
    System.assertEquals(batch.Id, cashBatches[0].Id);
    System.assertEquals(bundles[0].Id, cashBatches[0].GP_Export_Bundle__c);

    System.assertEquals(1, bundles.size());
    System.assertEquals(Date.today(), bundles[0].End_Date__c);

    System.assertEquals('Check Transaction Numbers', bundles[0].Fund_GL_Validation_Check__c);
    System.assertEquals(Date.today(), bundles[0].Start_Date__c);
    System.assertEquals(false, bundles[0].Validation_Error__c);

    System.assertEquals(2, aaglRows.size());
    // Auto-generated reciprocal row
    System.assertEquals('MILLENNIUM', aaglRows[0].Checkbook__c);
    System.assertEquals(100, aaglRows[0].Donation_Amount__c);
    System.assertEquals(cashBatches[0].Name, aaglRows[0].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today()), aaglRows[0].Donation_Date__c);
    System.assertEquals(opp.Id, aaglRows[0].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[0].GP_Export_Bundle__c);
    System.assertEquals('1014-000-000', aaglRows[0].GP_Full_Account__c);
    System.assertEquals(null, aaglRows[0].GP_Natural_Account__c);
    System.assertEquals(null, aaglRows[0].Purpose_Code__c);
    System.assertEquals(all.Id, aaglRows[0].GAU_Allocation__c);
    System.assertEquals(1, aaglRows[0].SeqID__c);

    // Mapped AAGL Row
    System.assertEquals(null, aaglRows[1].Checkbook__c);
    System.assertEquals(-100, aaglRows[1].Donation_Amount__c);
    System.assertEquals(cashBatches[0].Name, aaglRows[1].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today()), aaglRows[1].Donation_Date__c);
    System.assertEquals(opp.Id, aaglRows[1].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[1].GP_Export_Bundle__c);
    System.assertEquals('1234-000-000', aaglRows[1].GP_Full_Account__c);
    System.assertEquals('1234', aaglRows[1].GP_Natural_Account__c);
    System.assertEquals('789', aaglRows[1].Purpose_Code__c);
    System.assertEquals(all.Id, aaglRows[1].GAU_Allocation__c);
    System.assertEquals(2, aaglRows[1].SeqID__c);

    System.assertEquals(1, depositRows.size());
    System.assertEquals('MILLENNIUM', depositRows[0].Checkbook__c);
    System.assertEquals(cashBatches[0].Name, depositRows[0].Donation_Batch_Number__c);
    System.assertEquals(Date.today(), depositRows[0].Donation_Date__c);
    System.assertEquals(bundles[0].Id, depositRows[0].GP_Export_Bundle__c);
    System.assertEquals('1014-000-000', depositRows[0].GP_Full_Account__c);
    System.assertEquals(100, depositRows[0].SumOfDonation_Amount__c);
    System.assertEquals(batch.Id, depositRows[0].Cash_Batch__c);

    System.assertEquals(null, bundles[0].Fund_GL_Error_Message__c);
    System.assertEquals(null, cashBatches[0].GP_Export_Error__c);
    System.assertEquals(null, opps[0].GP_Export_Error__c);
    System.assertEquals(null, allocations[0].GP_Export_Error__c);

    System.assertEquals(0, returnRows.size());
  }

  @IsTest
  static void testAdjustmentBatch() {
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test GAU';
    gau.npsp__Active__c = true;
    gau.Purpose_Code__c = '789';
    insert gau;

    Fund_GL_Account__c fundGLAccount = new Fund_GL_Account__c();
    fundGLAccount.Active__c = true;
    fundGLAccount.GL_Account__c = '1234-000-000';
    fundGLAccount.GL_Account_Prefix__c = '1234';
    fundGLAccount.GL_Account_External_Id__c = '789:1234-000-000';
    fundGLAccount.General_Accounting_Unit__c = gau.Id;
    insert fundGLAccount;

    Cash_Batch__c batch = new Cash_Batch__c();
    batch.Status__c = 'New';
    batch.Date__c = Date.today();
    batch.Type__c = 'Adjustments';
    batch.Name = String.valueOf(Date.today()) + 'Adjustments';
    insert batch;

    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opp';
    opp.AccountId = acc.Id;
    opp.CloseDate = Date.today();
    opp.Cash_Batch__c = batch.Id;
    opp.StageName = 'Closed Won';
    opp.Amount = 100;
    opp.Original_Amount__c = 100;
    opp.Original_Currency__c = 'USD';
    insert opp;

    npsp__Allocation__c all = new npsp__Allocation__c();
    all.npsp__Opportunity__c = opp.Id;
    all.npsp__Amount__c = 100;
    all.Original_Amount__c = 100;
    all.Original_Currency__c = 'USD';
    all.npsp__General_Accounting_Unit__c = gau.Id;
    all.Fund_GL_Account__c = fundGLAccount.Id;
    insert all;

    batch.Status__c = 'Approved';
    update batch;

    GP_Export_Bundle__c bundle = new GP_Export_Bundle__c();
    bundle.Start_Date__c = Date.today();
    bundle.End_Date__c = Date.today();
    bundle.RecordTypeId = Utils.getRecordTypeId('GP_Export_Bundle__c', 'Donation Income');

    Test.startTest();
    insert bundle;
    Test.stopTest();

    List<GP_Export_Bundle__c> bundles = retrieveBundles();
    List<GP_Export_AAGL_Row__c> aaglRows = retrieveAAGLRows();
    List<GP_Export_Deposit_Row__c> depositRows = retrieveDepositRows();
    List<GP_Export_Return_Row__c> returnRows = retrieveReturnRows();
    List<Cash_Batch__c> cashBatches = retrieveCashBatches();
    List<Opportunity> opps = retrieveOpportunities();
    List<npsp__Allocation__c> allocations = retrieveAllocations();

    System.assertEquals(1, cashBatches.size());
    System.assertEquals(batch.Id, cashBatches[0].Id);
    System.assertEquals(bundles[0].Id, cashBatches[0].GP_Export_Bundle__c);

    System.assertEquals(1, bundles.size());
    System.assertEquals(Date.today(), bundles[0].End_Date__c);

    System.assertEquals('Check Transaction Numbers', bundles[0].Fund_GL_Validation_Check__c);
    System.assertEquals(Date.today(), bundles[0].Start_Date__c);
    System.assertEquals(false, bundles[0].Validation_Error__c);

    System.assertEquals(2, aaglRows.size());
    // Auto-generated reciprocal row
    System.assertEquals('MILLENNIUM', aaglRows[0].Checkbook__c);
    System.assertEquals(100, aaglRows[0].Donation_Amount__c);
    System.assertEquals(cashBatches[0].Name, aaglRows[0].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today()), aaglRows[0].Donation_Date__c);
    System.assertEquals(opp.Id, aaglRows[0].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[0].GP_Export_Bundle__c);
    System.assertEquals('1014-000-000', aaglRows[0].GP_Full_Account__c);
    System.assertEquals(null, aaglRows[0].GP_Natural_Account__c);
    System.assertEquals(null, aaglRows[0].Purpose_Code__c);
    System.assertEquals(all.Id, aaglRows[0].GAU_Allocation__c);
    System.assertEquals(1, aaglRows[0].SeqID__c);

    // Mapped AAGL Row
    System.assertEquals(null, aaglRows[1].Checkbook__c);
    System.assertEquals(-100, aaglRows[1].Donation_Amount__c);
    System.assertEquals(cashBatches[0].Name, aaglRows[1].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today()), aaglRows[1].Donation_Date__c);
    System.assertEquals(opp.Id, aaglRows[1].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[1].GP_Export_Bundle__c);
    System.assertEquals('1234-000-000', aaglRows[1].GP_Full_Account__c);
    System.assertEquals('1234', aaglRows[1].GP_Natural_Account__c);
    System.assertEquals('789', aaglRows[1].Purpose_Code__c);
    System.assertEquals(all.Id, aaglRows[1].GAU_Allocation__c);
    System.assertEquals(2, aaglRows[1].SeqID__c);

    System.assertEquals(0, depositRows.size());

    System.assertEquals(1, returnRows.size());

    System.assertEquals('MILLENNIUM', returnRows[0].Checkbook__c);
    System.assertEquals(cashBatches[0].Name, returnRows[0].Donation_Batch_Number__c);
    System.assertEquals(Date.today(), returnRows[0].Donation_Date__c);
    System.assertEquals(bundles[0].Id, returnRows[0].GP_Export_Bundle__c);
    System.assertEquals('1014-000-000', returnRows[0].GP_Full_Account__c);
    System.assertEquals(100, returnRows[0].SumOfDonation_Amount__c);
    System.assertEquals(batch.Id, returnRows[0].Cash_Batch__c);

    System.assertEquals(null, bundles[0].Fund_GL_Error_Message__c);
    System.assertEquals(null, cashBatches[0].GP_Export_Error__c);
    System.assertEquals(null, opps[0].GP_Export_Error__c);
    System.assertEquals(null, allocations[0].GP_Export_Error__c);
  }

  @IsTest
  static void testZeroSumDonationRow() {
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test GAU';
    gau.npsp__Active__c = true;
    gau.Purpose_Code__c = '789';
    insert gau;

    Fund_GL_Account__c fundGLAccount = new Fund_GL_Account__c();
    fundGLAccount.Active__c = true;
    fundGLAccount.GL_Account__c = '1234-000-000';
    fundGLAccount.GL_Account_Prefix__c = '1234';
    fundGLAccount.GL_Account_External_Id__c = '789:1234-000-000';
    fundGLAccount.General_Accounting_Unit__c = gau.Id;
    insert fundGLAccount;

    Cash_Batch__c batch = new Cash_Batch__c();
    batch.Status__c = 'New';
    batch.Date__c = Date.today();
    batch.Type__c = 'Bank Accounts';
    batch.Name = String.valueOf(Date.today()) + 'Bank Accounts';
    insert batch;

    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    Opportunity opp1 = new Opportunity();
    opp1.Name = 'Test Opp';
    opp1.AccountId = acc.Id;
    opp1.CloseDate = Date.today();
    opp1.Cash_Batch__c = batch.Id;
    opp1.StageName = 'Closed Won';
    opp1.Amount = 100;
    opp1.Original_Amount__c = 100;
    opp1.Original_Currency__c = 'USD';

    Opportunity opp2 = new Opportunity();
    opp2.Name = 'Test Opp';
    opp2.AccountId = acc.Id;
    opp2.CloseDate = Date.today();
    opp2.Cash_Batch__c = batch.Id;
    opp2.StageName = 'Closed Won';
    opp2.Amount = -100;
    opp2.Original_Amount__c = -100;
    opp2.Original_Currency__c = 'USD';

    insert new List<Opportunity>{ opp1, opp2 };

    npsp__Allocation__c all1 = new npsp__Allocation__c();
    all1.npsp__Opportunity__c = opp1.Id;
    all1.npsp__Amount__c = 100;
    all1.Original_Amount__c = 100;
    all1.Original_Currency__c = 'USD';
    all1.npsp__General_Accounting_Unit__c = gau.Id;
    all1.Fund_GL_Account__c = fundGLAccount.Id;

    npsp__Allocation__c all2 = new npsp__Allocation__c();
    all2.npsp__Opportunity__c = opp2.Id;
    all2.npsp__Amount__c = -100;
    all2.Original_Amount__c = -100;
    all2.Original_Currency__c = 'USD';
    all2.npsp__General_Accounting_Unit__c = gau.Id;
    all2.Fund_GL_Account__c = fundGLAccount.Id;

    insert new List<npsp__Allocation__c>{ all1, all2 };

    batch.Status__c = 'Approved';
    update batch;

    GP_Export_Bundle__c bundle = new GP_Export_Bundle__c();
    bundle.Start_Date__c = Date.today();
    bundle.End_Date__c = Date.today();
    bundle.RecordTypeId = Utils.getRecordTypeId('GP_Export_Bundle__c', 'Donation Income');

    Test.startTest();
    insert bundle;
    Test.stopTest();

    List<GP_Export_Bundle__c> bundles = retrieveBundles();
    List<GP_Export_AAGL_Row__c> aaglRows = retrieveAAGLRows();
    List<GP_Export_Deposit_Row__c> depositRows = retrieveDepositRows();
    List<GP_Export_Return_Row__c> returnRows = retrieveReturnRows();
    List<Cash_Batch__c> cashBatches = retrieveCashBatches();
    List<Opportunity> opps = retrieveOpportunities();
    List<npsp__Allocation__c> allocations = retrieveAllocations();

    System.assertEquals(1, cashBatches.size());
    System.assertEquals(batch.Id, cashBatches[0].Id);
    System.assertEquals(bundles[0].Id, cashBatches[0].GP_Export_Bundle__c);

    System.assertEquals(1, bundles.size());
    System.assertEquals(Date.today(), bundles[0].End_Date__c);

    System.assertEquals('Check Transaction Numbers', bundles[0].Fund_GL_Validation_Check__c);
    System.assertEquals(Date.today(), bundles[0].Start_Date__c);
    System.assertEquals(false, bundles[0].Validation_Error__c);

    System.assertEquals(4, aaglRows.size());

    // Auto-generated reciprocal row
    System.assertEquals('MILLENNIUM', aaglRows[0].Checkbook__c);
    System.assertEquals(100, aaglRows[0].Donation_Amount__c);
    System.assertEquals(cashBatches[0].Name, aaglRows[0].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today()), aaglRows[0].Donation_Date__c);
    System.assertEquals(opp1.Id, aaglRows[0].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[0].GP_Export_Bundle__c);
    System.assertEquals('1014-000-000', aaglRows[0].GP_Full_Account__c);
    System.assertEquals(null, aaglRows[0].GP_Natural_Account__c);
    System.assertEquals(null, aaglRows[0].Purpose_Code__c);
    System.assertEquals(all1.Id, aaglRows[0].GAU_Allocation__c);
    System.assertEquals(1, aaglRows[0].SeqID__c);

    // Mapped AAGL Row
    System.assertEquals(null, aaglRows[1].Checkbook__c);
    System.assertEquals(-100, aaglRows[1].Donation_Amount__c);
    System.assertEquals(cashBatches[0].Name, aaglRows[1].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today()), aaglRows[1].Donation_Date__c);
    System.assertEquals(opp1.Id, aaglRows[1].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[1].GP_Export_Bundle__c);
    System.assertEquals('1234-000-000', aaglRows[1].GP_Full_Account__c);
    System.assertEquals('1234', aaglRows[1].GP_Natural_Account__c);
    System.assertEquals('789', aaglRows[1].Purpose_Code__c);
    System.assertEquals(all1.Id, aaglRows[1].GAU_Allocation__c);
    System.assertEquals(2, aaglRows[1].SeqID__c);

    // Auto-generated reciprocal row
    System.assertEquals('MILLENNIUM', aaglRows[2].Checkbook__c);
    System.assertEquals(-100, aaglRows[2].Donation_Amount__c);
    System.assertEquals(cashBatches[0].Name, aaglRows[2].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today()), aaglRows[2].Donation_Date__c);
    System.assertEquals(opp2.Id, aaglRows[2].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[2].GP_Export_Bundle__c);
    System.assertEquals('1014-000-000', aaglRows[2].GP_Full_Account__c);
    System.assertEquals(null, aaglRows[2].GP_Natural_Account__c);
    System.assertEquals(null, aaglRows[2].Purpose_Code__c);
    System.assertEquals(all2.Id, aaglRows[2].GAU_Allocation__c);
    System.assertEquals(3, aaglRows[2].SeqID__c);

    // Mapped AAGL Row
    System.assertEquals(null, aaglRows[3].Checkbook__c);
    System.assertEquals(100, aaglRows[3].Donation_Amount__c);
    System.assertEquals(cashBatches[0].Name, aaglRows[3].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today()), aaglRows[3].Donation_Date__c);
    System.assertEquals(opp2.Id, aaglRows[3].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[3].GP_Export_Bundle__c);
    System.assertEquals('1234-000-000', aaglRows[3].GP_Full_Account__c);
    System.assertEquals('1234', aaglRows[3].GP_Natural_Account__c);
    System.assertEquals('789', aaglRows[3].Purpose_Code__c);
    System.assertEquals(all2.Id, aaglRows[3].GAU_Allocation__c);
    System.assertEquals(4, aaglRows[3].SeqID__c);

    System.assertEquals(0, depositRows.size());

    System.assertEquals(0, returnRows.size());

    System.assertEquals(null, bundles[0].Fund_GL_Error_Message__c);
    System.assertEquals(null, cashBatches[0].GP_Export_Error__c);
    System.assertEquals(null, opps[0].GP_Export_Error__c);
    System.assertEquals(null, opps[1].GP_Export_Error__c);
    System.assertEquals(null, allocations[0].GP_Export_Error__c);
    System.assertEquals(null, allocations[1].GP_Export_Error__c);
  }

  @IsTest
  static void testNoOpportunitiesFound() {
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test GAU';
    gau.npsp__Active__c = true;
    gau.Purpose_Code__c = '1234';
    insert gau;

    Fund_GL_Account__c fundGLAccount = new Fund_GL_Account__c();
    fundGLAccount.Active__c = true;
    fundGLAccount.GL_Account__c = '4321-000-000';
    fundGLAccount.GL_Account_Prefix__c = '4321';
    fundGLAccount.GL_Account_External_Id__c = '1234:4321-000-000';
    fundGLAccount.General_Accounting_Unit__c = gau.Id;
    insert fundGLAccount;

    Cash_Batch__c batch = new Cash_Batch__c();
    batch.Status__c = 'Approved';
    batch.Date__c = Date.today();
    batch.Type__c = 'Bank Accounts';
    insert batch;

    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    GP_Export_Bundle__c bundle = new GP_Export_Bundle__c();
    bundle.Start_Date__c = Date.today();
    bundle.End_Date__c = Date.today();
    bundle.RecordTypeId = Utils.getRecordTypeId('GP_Export_Bundle__c', 'Donation Income');

    Test.startTest();
    insert bundle;
    Test.stopTest();

    List<GP_Export_Bundle__c> bundles = retrieveBundles();
    List<GP_Export_AAGL_Row__c> aaglRows = retrieveAAGLRows();
    List<GP_Export_Deposit_Row__c> depositRows = retrieveDepositRows();
    List<Cash_Batch__c> cashBatches = retrieveCashBatches();
    List<Opportunity> opps = retrieveOpportunities();
    List<npsp__Allocation__c> allocations = retrieveAllocations();

    System.assertEquals(1, cashBatches.size());
    System.assertEquals(batch.Id, cashBatches[0].Id);
    System.assertEquals(bundles[0].Id, cashBatches[0].GP_Export_Bundle__c);

    System.assertEquals(1, bundles.size());
    System.assertEquals(Date.today(), bundles[0].End_Date__c);
    System.assertEquals(
      'Check Opportunities, Allocations, and GAUs',
      bundles[0].Fund_GL_Validation_Check__c
    );
    System.assertEquals(Date.today(), bundles[0].Start_Date__c);
    System.assertEquals(true, bundles[0].Validation_Error__c);

    System.assertEquals(0, aaglRows.size());

    System.assertEquals(0, depositRows.size());

    System.assertNotEquals(null, bundles[0].Fund_GL_Error_Message__c);
    System.assertNotEquals(null, cashBatches[0].GP_Export_Error__c);
    System.assertEquals(true, opps.isEmpty());
    System.assertEquals(0, allocations.size());
  }

  @IsTest
  static void testFailedOpportunityCheck() {
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test GAU';
    gau.npsp__Active__c = true;
    gau.Purpose_Code__c = '1234';
    insert gau;

    Fund_GL_Account__c fundGLAccount = new Fund_GL_Account__c();
    fundGLAccount.Active__c = true;
    fundGLAccount.GL_Account__c = '4321-000-000';
    fundGLAccount.GL_Account_Prefix__c = '4321';
    fundGLAccount.GL_Account_External_Id__c = '1234:4321-000-000';
    fundGLAccount.General_Accounting_Unit__c = gau.Id;
    insert fundGLAccount;

    Cash_Batch__c batch = new Cash_Batch__c();
    batch.Status__c = 'New';
    batch.Date__c = Date.today();
    batch.Type__c = 'Bank Accounts';
    insert batch;

    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opp';
    opp.AccountId = acc.Id;
    opp.CloseDate = Date.today();
    opp.Cash_Batch__c = batch.Id;
    opp.StageName = 'Closed Won';
    opp.Amount = 100;
    opp.Original_Amount__c = 100;
    opp.Original_Currency__c = 'USD';
    insert opp;

    batch.Status__c = 'Approved';
    update batch;

    GP_Export_Bundle__c bundle = new GP_Export_Bundle__c();
    bundle.Start_Date__c = Date.today();
    bundle.End_Date__c = Date.today();
    bundle.RecordTypeId = Utils.getRecordTypeId('GP_Export_Bundle__c', 'Donation Income');

    Test.startTest();
    insert bundle;
    Test.stopTest();

    List<GP_Export_Bundle__c> bundles = retrieveBundles();
    List<GP_Export_AAGL_Row__c> aaglRows = retrieveAAGLRows();
    List<GP_Export_Deposit_Row__c> depositRows = retrieveDepositRows();
    List<Cash_Batch__c> cashBatches = retrieveCashBatches();
    List<Opportunity> opps = retrieveOpportunities();
    List<npsp__Allocation__c> allocations = retrieveAllocations();

    System.assertEquals(1, cashBatches.size());
    System.assertEquals(batch.Id, cashBatches[0].Id);
    System.assertEquals(bundles[0].Id, cashBatches[0].GP_Export_Bundle__c);

    System.assertEquals(1, bundles.size());
    System.assertEquals(Date.today(), bundles[0].End_Date__c);
    System.assertEquals(
      'Check Opportunities, Allocations, and GAUs',
      bundles[0].Fund_GL_Validation_Check__c
    );
    System.assertEquals(Date.today(), bundles[0].Start_Date__c);
    System.assertEquals(true, bundles[0].Validation_Error__c);

    System.assertEquals(0, aaglRows.size());

    System.assertEquals(0, depositRows.size());

    System.assertNotEquals(null, bundles[0].Fund_GL_Error_Message__c);
    System.assertEquals(null, cashBatches[0].GP_Export_Error__c);
    System.assertNotEquals(null, opps[0].GP_Export_Error__c);
    System.assertEquals(0, allocations.size());
  }

  @IsTest
  static void testValidationErrorGAUAllocationSum() {
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test GAU';
    gau.npsp__Active__c = true;
    gau.Purpose_Code__c = '1234';
    insert gau;

    Fund_GL_Account__c fundGLAccount = new Fund_GL_Account__c();
    fundGLAccount.Active__c = true;
    fundGLAccount.GL_Account__c = '4321-000-000';
    fundGLAccount.GL_Account_Prefix__c = '4321';
    fundGLAccount.GL_Account_External_Id__c = '1234:4321-000-000';
    fundGLAccount.General_Accounting_Unit__c = gau.Id;
    insert fundGLAccount;

    Cash_Batch__c batch = new Cash_Batch__c();
    batch.Status__c = 'New';
    batch.Date__c = Date.today();
    batch.Type__c = 'Bank Accounts';
    insert batch;

    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opp';
    opp.AccountId = acc.Id;
    opp.CloseDate = Date.today();
    opp.Cash_Batch__c = batch.Id;
    opp.StageName = 'Closed Won';
    opp.Amount = 100;
    opp.Original_Amount__c = 100;
    opp.Original_Currency__c = 'USD';
    insert opp;

    npsp__Allocation__c all = new npsp__Allocation__c();
    all.npsp__Opportunity__c = opp.Id;
    all.npsp__Amount__c = 100;
    all.Original_Amount__c = 100;
    all.Original_Currency__c = 'USD';
    all.npsp__General_Accounting_Unit__c = gau.Id;
    all.Fund_GL_Account__c = fundGLAccount.Id;
    insert all;

    all.npsp__Amount__c = 50;
    update all;

    batch.Status__c = 'Approved';
    update batch;

    GP_Export_Bundle__c bundle = new GP_Export_Bundle__c();
    bundle.Start_Date__c = Date.today();
    bundle.End_Date__c = Date.today();
    bundle.RecordTypeId = Utils.getRecordTypeId('GP_Export_Bundle__c', 'Donation Income');

    Test.startTest();
    insert bundle;
    Test.stopTest();

    List<GP_Export_Bundle__c> bundles = retrieveBundles();
    List<GP_Export_AAGL_Row__c> aaglRows = retrieveAAGLRows();
    List<GP_Export_Deposit_Row__c> depositRows = retrieveDepositRows();
    List<Cash_Batch__c> cashBatches = retrieveCashBatches();
    List<Opportunity> opps = retrieveOpportunities();
    List<npsp__Allocation__c> allocations = retrieveAllocations();

    System.assertEquals(1, cashBatches.size());
    System.assertEquals(batch.Id, cashBatches[0].Id);
    System.assertEquals(bundles[0].Id, cashBatches[0].GP_Export_Bundle__c);

    System.assertEquals(1, bundles.size());
    System.assertEquals(Date.today(), bundles[0].End_Date__c);
    System.assertEquals(
      'Check Opportunities, Allocations, and GAUs',
      bundles[0].Fund_GL_Validation_Check__c
    );
    System.assertEquals(Date.today(), bundles[0].Start_Date__c);
    System.assertEquals(true, bundles[0].Validation_Error__c);
    System.assertEquals(2, aaglRows.size());

    // Auto-generated reciprocal row
    System.assertEquals('MILLENNIUM', aaglRows[0].Checkbook__c);
    System.assertEquals(50, aaglRows[0].Donation_Amount__c);
    System.assertEquals(cashBatches[0].Name, aaglRows[0].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today()), aaglRows[0].Donation_Date__c);
    System.assertEquals(opp.Id, aaglRows[0].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[0].GP_Export_Bundle__c);
    System.assertEquals('1014-000-000', aaglRows[0].GP_Full_Account__c);
    System.assertEquals(null, aaglRows[0].GP_Natural_Account__c);
    System.assertEquals(null, aaglRows[0].Purpose_Code__c);
    System.assertEquals(1, aaglRows[0].SeqID__c);

    // Mapped AAGL Row
    System.assertEquals(null, aaglRows[1].Checkbook__c);
    System.assertEquals(-50, aaglRows[1].Donation_Amount__c);
    System.assertEquals(cashBatches[0].Name, aaglRows[1].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today()), aaglRows[1].Donation_Date__c);
    System.assertEquals(opp.Id, aaglRows[1].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[1].GP_Export_Bundle__c);
    System.assertEquals('4321-000-000', aaglRows[1].GP_Full_Account__c);
    System.assertEquals('4321', aaglRows[1].GP_Natural_Account__c);
    System.assertEquals('1234', aaglRows[1].Purpose_Code__c);
    System.assertEquals(2, aaglRows[1].SeqID__c);

    System.assertEquals(1, depositRows.size());
    System.assertEquals('MILLENNIUM', depositRows[0].Checkbook__c);
    System.assertEquals(cashBatches[0].Name, depositRows[0].Donation_Batch_Number__c);
    System.assertEquals(Date.today(), depositRows[0].Donation_Date__c);
    System.assertEquals(bundles[0].Id, depositRows[0].GP_Export_Bundle__c);
    System.assertEquals('1014-000-000', depositRows[0].GP_Full_Account__c);
    System.assertEquals(50, depositRows[0].SumOfDonation_Amount__c);

    System.assertNotEquals(null, bundles[0].Fund_GL_Error_Message__c);
    System.assertEquals(null, cashBatches[0].GP_Export_Error__c);
    System.assertNotEquals(null, opps[0].GP_Export_Error__c);
    System.assertEquals(null, allocations[0].GP_Export_Error__c);
  }

  @IsTest
  static void testFailedGeneralAccountingUnitCheck() {
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test GAU';
    gau.npsp__Active__c = true;
    gau.Purpose_Code__c = '1234';
    insert gau;

    Fund_GL_Account__c fundGLAccount = new Fund_GL_Account__c();
    fundGLAccount.Active__c = false;
    fundGLAccount.General_Accounting_Unit__c = gau.Id;
    fundGLAccount.GL_Account__c = '007-000-123';
    fundGLAccount.GL_Account_Prefix__c = '007';
    fundGLAccount.GL_Account_External_Id__c = '1234:007-000-123';
    insert fundGLAccount;

    Cash_Batch__c batch = new Cash_Batch__c();
    batch.Status__c = 'New';
    batch.Date__c = Date.today();
    batch.Type__c = 'Bank Accounts';
    insert batch;

    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opp';
    opp.AccountId = acc.Id;
    opp.CloseDate = Date.today();
    opp.Cash_Batch__c = batch.Id;
    opp.StageName = 'Closed Won';
    opp.Amount = 100;
    opp.Original_Amount__c = 100;
    opp.Original_Currency__c = 'USD';
    insert opp;

    npsp__Allocation__c all = new npsp__Allocation__c();
    all.npsp__Opportunity__c = opp.Id;
    all.npsp__Amount__c = 100;
    all.Original_Amount__c = 100;
    all.Original_Currency__c = 'USD';
    all.npsp__General_Accounting_Unit__c = gau.Id;
    all.Fund_GL_Account__c = null;
    insert all;

    gau.npsp__Active__c = false;
    update gau;

    batch.Status__c = 'Approved';
    update batch;

    GP_Export_Bundle__c bundle = new GP_Export_Bundle__c();
    bundle.Start_Date__c = Date.today();
    bundle.End_Date__c = Date.today();
    bundle.RecordTypeId = Utils.getRecordTypeId('GP_Export_Bundle__c', 'Donation Income');

    Test.startTest();
    insert bundle;
    Test.stopTest();

    List<GP_Export_Bundle__c> bundles = retrieveBundles();
    List<GP_Export_AAGL_Row__c> aaglRows = retrieveAAGLRows();
    List<GP_Export_Deposit_Row__c> depositRows = retrieveDepositRows();
    List<Cash_Batch__c> cashBatches = retrieveCashBatches();
    List<Opportunity> opps = retrieveOpportunities();
    List<npsp__Allocation__c> allocations = retrieveAllocations();

    System.assertEquals(1, cashBatches.size());
    System.assertEquals(batch.Id, cashBatches[0].Id);
    System.assertEquals(bundles[0].Id, cashBatches[0].GP_Export_Bundle__c);

    System.assertEquals(1, bundles.size());
    System.assertEquals(Date.today(), bundles[0].End_Date__c);
    System.assertEquals(
      'Check Opportunities, Allocations, and GAUs',
      bundles[0].Fund_GL_Validation_Check__c
    );
    System.assertEquals(Date.today(), bundles[0].Start_Date__c);
    System.assertEquals(true, bundles[0].Validation_Error__c);

    System.assertEquals(0, aaglRows.size());
    System.assertEquals(0, depositRows.size());

    System.assertNotEquals(null, bundles[0].Fund_GL_Error_Message__c);
    System.assertEquals(null, cashBatches[0].GP_Export_Error__c);
    System.assertEquals(null, opps[0].GP_Export_Error__c);
    System.assertEquals(null, allocations[0].GP_Export_Error__c);
  }

  @IsTest
  static void testFailedDepositRowsCheck() {
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test GAU';
    gau.npsp__Active__c = true;
    gau.Purpose_Code__c = '444';
    insert gau;

    Fund_GL_Account__c fundGLAccount = new Fund_GL_Account__c();
    fundGLAccount.Active__c = true;
    fundGLAccount.GL_Account__c = '1234-000-000';
    fundGLAccount.GL_Account_Prefix__c = '1234';
    fundGLAccount.GL_Account_External_Id__c = '444:1234-000-000';
    fundGLAccount.General_Accounting_Unit__c = gau.Id;
    insert fundGLAccount;

    Cash_Batch__c batch = new Cash_Batch__c();
    batch.Status__c = 'New';
    batch.Date__c = Date.today().addDays(-1);
    batch.Type__c = 'Bank Accounts';
    insert batch;

    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opp';
    opp.AccountId = acc.Id;
    opp.CloseDate = Date.today().addDays(-1);
    opp.Cash_Batch__c = batch.Id;
    opp.StageName = 'Closed Won';
    opp.Amount = -100;
    opp.Original_Amount__c = -100;
    opp.Original_Currency__c = 'USD';
    insert opp;

    npsp__Allocation__c all = new npsp__Allocation__c();
    all.npsp__Opportunity__c = opp.Id;
    all.npsp__Amount__c = -100;
    all.Original_Amount__c = -100;
    all.Original_Currency__c = 'USD';
    all.npsp__General_Accounting_Unit__c = gau.Id;
    all.Fund_GL_Account__c = fundGLAccount.Id;
    insert all;

    batch.Status__c = 'Approved';
    update batch;

    GP_Export_Bundle__c bundle = new GP_Export_Bundle__c();
    bundle.Start_Date__c = Date.today().addDays(-1);
    bundle.End_Date__c = Date.today().addDays(-1);
    bundle.RecordTypeId = Utils.getRecordTypeId('GP_Export_Bundle__c', 'Donation Income');

    Test.startTest();
    insert bundle;
    Test.stopTest();

    List<GP_Export_Bundle__c> bundles = retrieveBundles();
    List<GP_Export_AAGL_Row__c> aaglRows = retrieveAAGLRows();
    List<GP_Export_Deposit_Row__c> depositRows = retrieveDepositRows();
    List<Cash_Batch__c> cashBatches = retrieveCashBatches();
    List<Opportunity> opps = retrieveOpportunities();
    List<npsp__Allocation__c> allocations = retrieveAllocations();

    System.assertEquals(1, cashBatches.size());
    System.assertEquals(batch.Id, cashBatches[0].Id);
    System.assertEquals(bundles[0].Id, cashBatches[0].GP_Export_Bundle__c);

    System.assertEquals(1, bundles.size());
    System.assertEquals(Date.today().addDays(-1), bundles[0].End_Date__c);
    System.assertEquals(
      'Check Opportunities, Allocations, and GAUs',
      bundles[0].Fund_GL_Validation_Check__c
    );
    System.assertEquals(Date.today().addDays(-1), bundles[0].Start_Date__c);
    System.assertEquals(true, bundles[0].Validation_Error__c);

    // Auto-generated reciprocal row
    System.assertEquals(2, aaglRows.size());
    System.assertEquals('MILLENNIUM', aaglRows[0].Checkbook__c);
    System.assertEquals(-100, aaglRows[0].Donation_Amount__c);
    System.assertEquals(cashBatches[0].Name, aaglRows[0].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today().addDays(-1)), aaglRows[0].Donation_Date__c);
    System.assertEquals(opp.Id, aaglRows[0].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[0].GP_Export_Bundle__c);
    System.assertEquals('1014-000-000', aaglRows[0].GP_Full_Account__c);
    System.assertEquals(null, aaglRows[0].GP_Natural_Account__c);
    System.assertEquals(null, aaglRows[0].Purpose_Code__c);
    System.assertEquals(1, aaglRows[0].SeqID__c);

    // Mapped AAGL Row
    System.assertEquals(null, aaglRows[1].Checkbook__c);
    System.assertEquals(100, aaglRows[1].Donation_Amount__c);
    System.assertEquals(cashBatches[0].Name, aaglRows[1].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today().addDays(-1)), aaglRows[1].Donation_Date__c);
    System.assertEquals(opp.Id, aaglRows[1].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[1].GP_Export_Bundle__c);
    System.assertEquals('1234-000-000', aaglRows[1].GP_Full_Account__c);
    System.assertEquals('1234', aaglRows[1].GP_Natural_Account__c);
    System.assertEquals('444', aaglRows[1].Purpose_Code__c);
    System.assertEquals(2, aaglRows[1].SeqID__c);

    System.assertEquals(1, depositRows.size());
    System.assertEquals('MILLENNIUM', depositRows[0].Checkbook__c);
    System.assertEquals(cashBatches[0].Name, depositRows[0].Donation_Batch_Number__c);
    System.assertEquals(Date.today().addDays(-1), depositRows[0].Donation_Date__c);
    System.assertEquals(bundles[0].Id, depositRows[0].GP_Export_Bundle__c);
    System.assertEquals('1014-000-000', depositRows[0].GP_Full_Account__c);
    System.assertEquals(-100, depositRows[0].SumOfDonation_Amount__c);

    System.assertNotEquals(null, bundles[0].Fund_GL_Error_Message__c);
    System.assertEquals(null, cashBatches[0].GP_Export_Error__c);
    System.assertEquals(null, opps[0].GP_Export_Error__c);
    System.assertEquals(null, allocations[0].GP_Export_Error__c);
  }
}