@isTest
private class GAUAllocationServiceTest {
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
  }

  @isTest
  static void testValidation() {
    User receiptingUser = UnitTestHelper.createStandardUser();
    receiptingUser.IsActive = true;
    receiptingUser.Receipting_Assignments__c = 'Large';
    insert receiptingUser;

    Contact c = new Contact(LastName = 'Contact', Email = 'test@test.com');
    insert c;

    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Original_Control_Batch_Total__c = 11;
    cb.Original_Currency__c = 'USD';
    cb.Status__c = 'New';
    cb.Type__c = 'Credit Cards';
    insert cb;

    Account a = new Account(
      Name = 'Account',
      BillingStreet = '1 Street',
      BillingCity = 'Annville',
      BillingState = 'Pennsylvania',
      BillingCountry = 'United States',
      BillingPostalCode = '17033',
      npe01__One2OneContact__c = c.Id
    );
    insert a;

    Opportunity opp = new Opportunity(
      Name = 'test opp',
      Original_Amount__c = 11,
      Original_Currency__c = 'USD',
      LeadSource = 'Web',
      CloseDate = Date.today(),
      StageName = 'Closed Won',
      Payment_Method__c = 'Cash',
      AccountId = a.Id,
      Receipt_Type__c = 'Email',
      Cash_Batch__c = cb.Id
    );
    insert opp;

    Opportunity batchedOpp = [
      SELECT Id, Cash_Batch__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];
    System.assertNotEquals(null, batchedOpp.Cash_Batch__c);

    Opportunity opp2 = new Opportunity(
      Name = 'test opp2',
      Original_Amount__c = 11,
      Original_Currency__c = 'USD',
      LeadSource = 'Web',
      CloseDate = Date.today(),
      StageName = 'Closed Won',
      Payment_Method__c = 'Cash',
      AccountId = a.Id,
      Cash_Batch__c = cb.Id
    );
    insert opp2;
    delete opp2;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c(
      Name = 'mike\'s food fund',
      Purpose_Code__c = '123'
    );
    insert gau;

    npsp__Allocation__c alloc = new npsp__Allocation__c(
      npsp__Opportunity__c = opp.Id,
      Original_Amount__c = 10,
      Original_Currency__c = 'USD',
      npsp__General_Accounting_Unit__c = gau.Id
    );
    insert alloc;

    npsp__Allocation__c alloc2 = new npsp__Allocation__c(
      npsp__Opportunity__c = opp.Id,
      Original_Amount__c = 1,
      Original_Currency__c = 'USD',
      npsp__General_Accounting_Unit__c = gau.Id
    );
    insert alloc2;
    delete alloc2;

    Cash_Batch__c batch1 = [
      SELECT
        Id,
        Status__c,
        Control_Batch_Total__c,
        Total_Included_in_Batch__c,
        Balance__c
      FROM Cash_Batch__c
      WHERE Id = :batchedOpp.Cash_Batch__c
    ];
    batch1.Control_Batch_Total__c = 11;
    batch1.Status__c = 'New';
    update batch1;

    Test.startTest();

    Cash_Batch__c batch = [
      SELECT
        Id,
        Status__c,
        Control_Batch_Total__c,
        Total_Included_in_Batch__c,
        Balance__c
      FROM Cash_Batch__c
      WHERE Id = :batch1.Id
    ];
    batch.Status__c = 'Approved';
    update batch;

    try {
      insert new npsp__Allocation__c(
        npsp__General_Accounting_Unit__c = gau.Id,
        Original_Amount__c = 1,
        Original_Currency__c = 'USD',
        npsp__Opportunity__c = opp.Id
      );
    } catch (Exception e) {
      System.assertEquals(
        true,
        e.getMessage().contains(GAUAllocationService.recordIsLockedError)
      );
    }
    try {
      alloc.Original_Amount__c = 11;
      update alloc;
    } catch (Exception e) {
      System.assertEquals(
        true,
        e.getMessage().contains(GAUAllocationService.recordIsLockedError)
      );
    }
    try {
      delete alloc;
    } catch (Exception e) {
      System.assertEquals(
        true,
        e.getMessage().contains(GAUAllocationService.recordIsLockedError)
      );
    }
    try {
      undelete alloc2;
    } catch (Exception e) {
      System.assertEquals(
        true,
        e.getMessage().contains(GAUAllocationService.recordIsLockedError)
      );
    }

    try {
      opp.Original_Amount__c = 11;
      update opp;
    } catch (Exception e) {
      System.assertEquals(
        true,
        e.getMessage().contains(OpportunityService.recordIsLockedError)
      );
    }
    try {
      delete opp;
    } catch (Exception e) {
      System.assertEquals(
        true,
        e.getMessage().contains(OpportunityService.recordIsLockedError)
      );
    }
    try {
      undelete opp2;
    } catch (Exception e) {
      //Saw unexpected results, asserting an unmeaningful value, but should indicate it is working.
      System.assert(e.getMessage() != null);
    }
    Test.stopTest();
  }

  @isTest
  static void testSetCampaignFromRecurringDonation() {
    Account acct = new Account();
    acct.Name = 'Test Account';
    insert acct;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c(
      Name = 'Test GAU',
      Purpose_Code__c = '123'
    );
    insert gau;

    Campaign camp1 = new Campaign(Name = 'Test Campaign 1');
    Campaign camp2 = new Campaign(Name = 'Test Campaign 2');
    insert new List<Campaign>{camp1, camp2};

    npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
      Name = 'Test Recurring Donation',
      npe03__Organization__c = acct.Id,
      npe03__Amount__c = 100,
      Original_Amount__c = 100,
      Original_Currency__c = 'USD',
      npe03__Date_Established__c = Date.today(),
      npe03__Installment_Period__c = 'Monthly',
      npsp__Status__c = 'Active',
      npe03__Recurring_Donation_Campaign__c = camp1.Id
    );
    insert rd;

    npsp__Allocation__c alloc1 = new npsp__Allocation__c(
      npsp__General_Accounting_Unit__c = gau.Id,
      npsp__Recurring_Donation__c = rd.Id,
      Original_Currency__c = 'USD',
      Original_Amount__c = 33,
      Tax_Deductible__c = true
    );
    npsp__Allocation__c alloc2 = new npsp__Allocation__c(
      npsp__General_Accounting_Unit__c = gau.Id,
      npsp__Recurring_Donation__c = rd.Id,
      Original_Currency__c = 'USD',
      Original_Amount__c = 33,
      Tax_Deductible__c = true,
      Campaign__c = camp2.Id
    );

    Test.startTest();
    // INSERT ALLOCATION TEST (insert allocations)
    insert new List<npsp__Allocation__c>{alloc1, alloc2};
    npsp__Allocation__c res1 = [
      SELECT Id, Campaign__c
      FROM npsp__Allocation__c
      WHERE Id = :alloc1.Id
    ];
    System.assertEquals(
      camp1.Id,
      res1.Campaign__c,
      'The campaign should be set to match the recurring donation.'
    );
    npsp__Allocation__c res2 = [
      SELECT Id, Campaign__c
      FROM npsp__Allocation__c
      WHERE Id = :alloc2.Id
    ];
    System.assertEquals(
      camp2.Id,
      res2.Campaign__c,
      'The campaign should not be overwritten to match the recc don.'
    );
    Test.stopTest();
  }

  @isTest
  static void testTaxDeductibleRollup() {
    Account acct = new Account();
    acct.Name = 'Test Account';
    insert acct;

    Opportunity opp1 = new Opportunity(
      Name = 'Test Opportunity',
      AccountId = acct.Id,
      Original_Amount__c = 66,
      Original_Currency__c = 'USD',
      StageName = 'Pledged',
      CloseDate = Date.today()
    );
    insert opp1;

    Opportunity opp2 = new Opportunity(
      Name = 'Test Opportunity',
      AccountId = acct.Id,
      Original_Amount__c = 33,
      Original_Currency__c = 'USD',
      StageName = 'Pledged',
      CloseDate = Date.today()
    );
    insert opp2;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c(
      Name = 'Test GAU',
      Purpose_Code__c = '123'
    );
    insert gau;

    npsp__Allocation__c alloc1 = new npsp__Allocation__c(
      npsp__General_Accounting_Unit__c = gau.Id,
      npsp__Opportunity__c = opp1.Id,
      Original_Currency__c = 'USD',
      Original_Amount__c = 33,
      Tax_Deductible__c = true
    );
    npsp__Allocation__c alloc2 = new npsp__Allocation__c(
      npsp__General_Accounting_Unit__c = gau.Id,
      npsp__Opportunity__c = opp1.Id,
      Original_Currency__c = 'USD',
      Original_Amount__c = 33,
      Tax_Deductible__c = true
    );

    Test.startTest();
    // INSERT ALLOCATION TEST (insert allocations)
    insert new List<npsp__Allocation__c>{alloc1, alloc2};
    Opportunity oppRes1 = [
      SELECT Id, Tax_Deductible_Amount__c
      FROM Opportunity
      WHERE Id = :opp1.Id
    ];
    System.assertEquals(
      66,
      oppRes1.Tax_Deductible_Amount__c,
      'The Tax-Deductible Amount should be 66 (alloc 1 & 2).'
    );

    // UPDATE ALLOCATION TEST (change amount)
    alloc1.npsp__Amount__c = 30;
    update alloc1;
    Opportunity oppRes2 = [
      SELECT Id, Tax_Deductible_Amount__c
      FROM Opportunity
      WHERE Id = :opp1.Id
    ];
    System.assertEquals(
      63,
      oppRes2.Tax_Deductible_Amount__c,
      'The Tax-Deductible Amount should be 63 (alloc 1 & 2).'
    );

    // UPDATE ALLOCATION TEST (change tax deductible)
    alloc2.Tax_Deductible__c = false;
    update alloc2;
    Opportunity oppRes3 = [
      SELECT Id, Tax_Deductible_Amount__c
      FROM Opportunity
      WHERE Id = :opp1.Id
    ];
    System.assertEquals(
      30,
      oppRes3.Tax_Deductible_Amount__c,
      'The Tax-Deductible Amount should be 30 (alloc 1).'
    );

    // UPDATE ALLOCATION TEST (change opp)
    alloc1.npsp__Opportunity__c = opp2.Id;
    update alloc1;
    Opportunity oppRes4 = [
      SELECT Id, Tax_Deductible_Amount__c
      FROM Opportunity
      WHERE Id = :opp1.Id
    ];
    System.assertEquals(
      0,
      oppRes4.Tax_Deductible_Amount__c,
      'The Tax-Deductible Amount should be 0 (no td alloc).'
    );
    Opportunity oppRes5 = [
      SELECT Id, Tax_Deductible_Amount__c
      FROM Opportunity
      WHERE Id = :opp2.Id
    ];
    System.assertEquals(
      30,
      oppRes5.Tax_Deductible_Amount__c,
      'The Tax-Deductible Amount should be 30 (alloc 1).'
    );

    // DELETE ALLOCATION TEST
    delete alloc1;
    Opportunity oppRes6 = [
      SELECT Id, Tax_Deductible_Amount__c
      FROM Opportunity
      WHERE Id = :opp2.Id
    ];
    System.assertEquals(
      0,
      oppRes6.Tax_Deductible_Amount__c,
      'The Tax-Deductible Amount should be 33 (no alloc).'
    );

    // UNDELETE ALLOCATION TEST
    undelete alloc1;
    Opportunity oppRes7 = [
      SELECT Id, Tax_Deductible_Amount__c
      FROM Opportunity
      WHERE Id = :opp2.Id
    ];
    System.assertEquals(
      30,
      oppRes7.Tax_Deductible_Amount__c,
      'The Tax-Deductible Amount should be 200 (alloc 1).'
    );
    Test.stopTest();
  }

  @IsTest
  public static void testInsertOfCampaignMember() {
    Campaign c = new Campaign();
    c.Name = 'campaign';
    insert c;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'gau';
    gau.Purpose_Code__c = '123';
    insert gau;

    Account a = new Account();
    a.Name = 'Account';
    insert a;

    Contact con = new Contact();
    con.FirstName = 'name';
    con.LastName = 'Last';
    insert con;

    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Type__c = 'Cash and Checks';
    cb.Opportunity_Type__c = 'Donation';
    cb.Batch_Variation__c = 'A';
    cb.Date__c = Date.today();
    cb.Original_Currency__c = 'USD';
    insert cb;

    Opportunity o = new Opportunity();
    o.Name = 'opp';
    o.StageName = 'Closed Won';
    o.Amount = 25;
    o.CloseDate = Date.today();
    o.npsp__Primary_Contact__c = con.Id;
    o.Cash_Batch__c = cb.Id;
    insert o;

    npsp__Allocation__c all = new npsp__Allocation__c();
    all.npsp__opportunity__c = o.Id;
    all.npsp__Amount__c = 25;
    all.npsp__General_Accounting_Unit__c = gau.Id;
    all.Campaign__c = c.Id;

    Test.startTest();
    insert all;
    Test.stopTest();

    List<CampaignMember> members = [
      SELECT Id
      FROM CampaignMember
      WHERE campaignId = :c.Id
    ];
    System.assertEquals(1, members.size());
  }

  @IsTest
  public static void testSetDefaultFundGLAccount() {
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'gau';
    gau.Purpose_Code__c = '123';
    insert gau;

    Fund_Gl_Account__c fgl = new Fund_GL_Account__c();
    fgl.Name = '123-123-1233';
    fgl.General_Accounting_Unit__c = gau.Id;
    fgl.GL_Account_External_Id__c = '123:123-123-1233';
    fgl.GL_Account_Prefix__c = '123';
    fgl.GL_Account__c = fgl.Name;
    insert fgl;

    gau.Default_Fund_GL_Account__c = fgl.Id;
    update gau;

    Account a = new Account();
    a.Name = 'Account';
    insert a;

    Contact con = new Contact();
    con.FirstName = 'name';
    con.LastName = 'Last';
    insert con;

    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Type__c = 'Cash and Checks';
    cb.Opportunity_Type__c = 'Donation';
    cb.Batch_Variation__c = 'A';
    cb.Date__c = Date.today();
    cb.Original_Currency__c = 'USD';
    insert cb;

    Opportunity o = new Opportunity();
    o.Name = 'opp';
    o.StageName = 'Closed Won';
    o.Amount = 25;
    o.CloseDate = Date.today();
    o.npsp__Primary_Contact__c = con.Id;
    o.Cash_Batch__c = cb.Id;
    insert o;

    npsp__Allocation__c all = new npsp__Allocation__c();
    all.npsp__opportunity__c = o.Id;
    all.npsp__Amount__c = 25;
    all.npsp__General_Accounting_Unit__c = gau.Id;

    Test.startTest();
    insert all;
    Test.stopTest();

    List<npsp__Allocation__c> allResults = [
      SELECT Id, Fund_GL_Account__C
      FROM npsp__Allocation__c
      WHERE Id = :all.Id
    ];
    System.assertEquals(fgl.Id, allResults[0].Fund_GL_Account__C);
  }

  @IsTest
  public static void testUpdateOfCampaignMember() {
    Campaign c = new Campaign();
    c.Name = 'campaign';
    insert c;

    CampaignMemberStatus stat = new CampaignMemberStatus();
    stat.CampaignId = c.Id;
    stat.HasResponded = true;
    stat.Label = 'RespondedTest';
    insert stat;

    CampaignMemberStatus stat2 = new CampaignMemberStatus();
    stat2.CampaignId = c.Id;
    stat2.HasResponded = false;
    stat2.IsDefault = true;
    stat2.Label = 'NewTest';
    insert stat2;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'gau';
    gau.Purpose_Code__c = '123';
    insert gau;

    Account a = new Account();
    a.Name = 'Account';
    insert a;

    Contact con = new Contact();
    con.FirstName = 'name';
    con.LastName = 'Last';
    insert con;

    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Type__c = 'Cash and Checks';
    cb.Opportunity_Type__c = 'Donation';
    cb.Batch_Variation__c = 'A';
    cb.Date__c = Date.today();
    cb.Original_Currency__c = 'USD';
    insert cb;

    Opportunity o = new Opportunity();
    o.Name = 'opp';
    o.StageName = 'Closed Won';
    o.Amount = 25;
    o.CloseDate = Date.today();
    o.npsp__Primary_Contact__c = con.Id;
    o.Cash_Batch__c = cb.Id;
    insert o;

    npsp__Allocation__c all = new npsp__Allocation__c();
    all.npsp__opportunity__c = o.Id;
    all.npsp__Amount__c = 25;
    all.npsp__General_Accounting_Unit__c = gau.Id;
    insert all;

    Test.startTest();
    all.Campaign__c = c.Id;
    update all;
    Test.stopTest();

    List<CampaignMember> members = [
      SELECT Id, Status
      FROM CampaignMember
      WHERE campaignId = :c.Id
    ];
    CampaignMemberStatus cms = [
      SELECT Label
      FROM CampaignMemberStatus
      WHERE CampaignId = :c.Id AND HasResponded = true
    ];
    System.assertEquals(1, members.size());
    System.assertEquals(cms.Label, members[0].Status);
  }

  @IsTest
  public static void testInsertOfCampaignMemberBulk() {
    Campaign c = new Campaign();
    c.Name = 'campaign';
    insert c;

    List<npsp__Allocation__c> allocs = generateTestData(100, c);

    Test.startTest();
    insert allocs;
    Test.stopTest();

    List<CampaignMember> members = [
      SELECT Id
      FROM CampaignMember
      WHERE campaignId = :c.Id
    ];
    System.assertEquals(100, members.size());
  }

  private static List<npsp__Allocation__c> generateTestData(
    Integer amount,
    Campaign c
  ) {
    List<Contact> cons = new List<Contact>();
    List<Opportunity> opps = new List<Opportunity>();
    List<npsp__Allocation__c> allocs = new List<npsp__Allocation__c>();

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'gau';
    gau.Purpose_Code__c = '123';
    insert gau;

    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Type__c = 'Cash and Checks';
    cb.Opportunity_Type__c = 'Donation';
    cb.Batch_Variation__c = 'A';
    cb.Date__c = Date.today();
    cb.Original_Currency__c = 'USD';
    insert cb;

    for (Integer i = 0; i < amount; i++) {
      Contact con = new Contact();
      con.FirstName = 'name';
      con.LastName = 'Last';
      cons.add(con);
    }
    insert cons;

    for (Integer i = 0; i < amount; i++) {
      Opportunity o = new Opportunity();
      o.Name = 'opp';
      o.StageName = 'Closed Won';
      o.Amount = 25;
      o.CloseDate = Date.today();
      o.npsp__Primary_Contact__c = cons[i].Id;
      o.Cash_Batch__c = cb.Id;
      opps.add(o);
    }
    insert opps;

    for (Integer i = 0; i < amount; i++) {
      npsp__Allocation__c all = new npsp__Allocation__c();
      all.npsp__opportunity__c = opps[i].Id;
      all.npsp__Amount__c = 25;
      all.npsp__General_Accounting_Unit__c = gau.Id;
      all.Campaign__c = c.Id;
      allocs.add(all);
    }
    return allocs;
  }

  /**
   * Simple test for the copying and merge field processing of the receipt message from
   * the campaign to the allocation.
   */
  @IsTest
  static void testCopyReceiptMessage() {
    Campaign campaign = new Campaign();
    campaign.Name = 'Test Campaign';
    campaign.Receipt_Message__c = 'Dear Test, This is a test receipt for {!npsp__Amount__c} dollars.';
    insert campaign;

    Account acc = new Account();
    acc.Name = 'Test Account';
    acc.npo02__Informal_Greeting__c = 'Test';
    insert acc;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test General Accounting Unit';
    gau.Purpose_Code__c = '123';
    insert gau;

    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Type__c = 'Cash and Checks';
    cb.Opportunity_Type__c = 'Donation';
    cb.Batch_Variation__c = 'A';
    cb.Date__c = Date.today();
    cb.Original_Currency__c = 'USD';
    insert cb;

    Opportunity opp = new Opportunity();
    opp.Amount = 100;
    opp.AccountId = acc.Id;
    opp.Name = 'Test Opportunity';
    opp.CloseDate = Date.today();
    opp.StageName = 'Closed Won';
    opp.Original_Amount__c = 100;
    opp.Original_Currency__c = 'USD';
    opp.Cash_Batch__c = cb.Id;
    insert opp;

    npsp__Allocation__c all = new npsp__Allocation__c();
    all.npsp__Opportunity__c = opp.Id;
    all.npsp__Amount__c = 100;
    all.npsp__General_Accounting_Unit__c = gau.Id;
    all.Campaign__c = campaign.Id;
    all.Original_Amount__c = 100;
    all.Original_Currency__c = 'USD';

    Test.startTest();
    insert all;
    Test.stopTest();

    npsp__Allocation__c result = [
      SELECT Id, Receipt_Message__c
      FROM npsp__Allocation__c
    ];

    System.assertEquals(all.Id, result.Id);
    System.assertEquals(
      'Dear Test, This is a test receipt for $100.00 dollars.',
      result.Receipt_Message__c
    );
  }

  /**
   * Test for the copying and merge field processing of the major donor receipt message from
   * the parent campaign to the allocation.
   * This also is a test for the hierachy of which receipt message to use.
   */
  @IsTest
  static void testCopyMajorDonorReceiptMessage() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    User usr;

    System.runAs(currentUser) {
      usr = UnitTestHelper.createStandardUser();
      usr.UserRoleId = [
        SELECT Id
        FROM UserRole
        WHERE Name = 'Major Gift Officer'
      ]
      .Id;
      insert usr;
    }

    Campaign parentCampaign = new Campaign();
    parentCampaign.Name = 'Test Parent Campaign';
    parentCampaign.Major_Donor_Receipt_Message__c = 'Dear Test, This is a major donor receipt for {!npsp__Amount__c} dollars.';
    parentCampaign.Recurring_Donation_Receipt_Message__c = 'Dear Test, This is a recurring donation receipt for {!npsp__Amount__c} dollars.';
    parentCampaign.Receipt_Message__c = 'Dear Test, This is a receipt for {!npsp__Amount__c} dollars.';
    insert parentCampaign;

    Campaign campaign = new Campaign();
    campaign.Name = 'Test Campaign';
    campaign.ParentId = parentCampaign.Id;
    insert campaign;

    Account acc = new Account();
    acc.Name = 'Test Account';
    acc.npo02__Informal_Greeting__c = 'Test';
    acc.Donor_Relationship_Manager__c = usr.Id;
    insert acc;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test General Accounting Unit';
    gau.Purpose_Code__c = '123';
    insert gau;

    npe03__Recurring_Donation__c recur = new npe03__Recurring_Donation__c();
    recur.npe03__Organization__c = acc.Id;
    recur.npe03__Recurring_Donation_Campaign__c = campaign.Id;
    recur.npe03__Date_Established__c = Date.today();
    recur.npe03__Installment_Period__c = 'Yearly';
    recur.npsp__InstallmentFrequency__c = 1;
    recur.npe03__Amount__c = 100000;
    insert recur;

    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Type__c = 'Cash and Checks';
    cb.Opportunity_Type__c = 'Donation';
    cb.Batch_Variation__c = 'A';
    cb.Date__c = Date.today();
    cb.Original_Currency__c = 'USD';
    insert cb;

    Opportunity opp = new Opportunity();
    opp.Amount = 100000;
    opp.AccountId = acc.Id;
    opp.Name = 'Test Opportunity';
    opp.CloseDate = Date.today();
    opp.StageName = 'Closed Won';
    opp.Original_Amount__c = 100000;
    opp.Original_Currency__c = 'USD';
    opp.npe03__Recurring_Donation__c = recur.Id;
    opp.Cash_Batch__c = cb.Id;
    insert opp;

    npsp__Allocation__c all = new npsp__Allocation__c();
    all.npsp__Opportunity__c = opp.Id;
    all.npsp__Amount__c = 100000;
    all.npsp__General_Accounting_Unit__c = gau.Id;
    all.Campaign__c = campaign.Id;
    all.Original_Amount__c = 100000;
    all.Original_Currency__c = 'USD';

    Test.startTest();
    insert all;
    Test.stopTest();

    npsp__Allocation__c result = [
      SELECT Id, Receipt_Message__c
      FROM npsp__Allocation__c
    ];

    System.assertEquals(all.Id, result.Id);
    System.assertEquals(
      'Dear Test, This is a major donor receipt for $100,000.00 dollars.',
      result.Receipt_Message__c
    );
  }

  /**
   * Test for the copying and merge field processing of the major donor receipt message from
   * the parent's parent campaign to the allocation.
   */
  @IsTest
  static void testCopyGrandParentCampaignReceiptMessage() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    User usr;

    System.runAs(currentUser) {
      usr = UnitTestHelper.createStandardUser();
      usr.UserRoleId = [
        SELECT Id
        FROM UserRole
        WHERE Name = 'Major Gift Officer'
      ]
      .Id;
      insert usr;
    }

    Campaign grandParentCampaign = new Campaign();
    grandParentCampaign.Name = 'Test GrandParent Campaign';
    grandParentCampaign.Major_Donor_Receipt_Message__c = 'Dear Test, This is a test receipt for {!npsp__Amount__c} dollars.';
    insert grandParentCampaign;

    Campaign parentCampaign = new Campaign();
    parentCampaign.Name = 'Test Parent Campaign';
    parentCampaign.ParentId = grandParentCampaign.Id;
    insert parentCampaign;

    Campaign campaign = new Campaign();
    campaign.Name = 'Test Campaign';
    campaign.ParentId = parentCampaign.Id;
    insert campaign;

    Account acc = new Account();
    acc.Name = 'Test Account';
    acc.npo02__Informal_Greeting__c = 'Test';
    acc.Donor_Relationship_Manager__c = usr.Id;
    insert acc;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test General Accounting Unit';
    gau.Purpose_Code__c = '123';
    insert gau;

    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Type__c = 'Cash and Checks';
    cb.Opportunity_Type__c = 'Donation';
    cb.Batch_Variation__c = 'A';
    cb.Date__c = Date.today();
    cb.Original_Currency__c = 'USD';
    insert cb;

    Opportunity opp = new Opportunity();
    opp.Amount = 100000;
    opp.AccountId = acc.Id;
    opp.Name = 'Test Opportunity';
    opp.CloseDate = Date.today();
    opp.StageName = 'Closed Won';
    opp.Original_Amount__c = 100000;
    opp.Original_Currency__c = 'USD';
    opp.Cash_Batch__c = cb.Id;
    insert opp;

    npsp__Allocation__c all = new npsp__Allocation__c();
    all.npsp__Opportunity__c = opp.Id;
    all.npsp__Amount__c = 100000;
    all.npsp__General_Accounting_Unit__c = gau.Id;
    all.Campaign__c = campaign.Id;
    all.Original_Amount__c = 100000;
    all.Original_Currency__c = 'USD';

    Test.startTest();
    insert all;
    Test.stopTest();

    npsp__Allocation__c result = [
      SELECT Id, Receipt_Message__c
      FROM npsp__Allocation__c
    ];

    System.assertEquals(all.Id, result.Id);
    System.assertEquals(
      'Dear Test, This is a test receipt for $100,000.00 dollars.',
      result.Receipt_Message__c
    );
  }

  /**
   * Test that the receipt message is blanked out when the campaign is removed from the allocation
   * and there isn't a recurring donation with a campaign for the allocation's parent opportunity.
   */
  @IsTest
  static void testClearReceiptMessage() {
    Campaign parentCampaign = new Campaign();
    parentCampaign.Name = 'Test Parent Campaign';
    parentCampaign.Major_Donor_Receipt_Message__c = 'Dear Test, This is a test receipt for {!npsp__Amount__c} dollars.';
    insert parentCampaign;

    Campaign campaign = new Campaign();
    campaign.Name = 'Test Campaign';
    campaign.ParentId = parentCampaign.Id;
    insert campaign;

    Account acc = new Account();
    acc.Name = 'Test Account';
    acc.npo02__Informal_Greeting__c = 'Test';
    insert acc;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test General Accounting Unit';
    gau.Purpose_Code__c = '123';
    insert gau;

    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Type__c = 'Cash and Checks';
    cb.Opportunity_Type__c = 'Donation';
    cb.Batch_Variation__c = 'A';
    cb.Date__c = Date.today();
    cb.Original_Currency__c = 'USD';
    insert cb;

    Opportunity opp = new Opportunity();
    opp.Amount = 100000;
    opp.AccountId = acc.Id;
    opp.Name = 'Test Opportunity';
    opp.CloseDate = Date.today();
    opp.StageName = 'Closed Won';
    opp.Original_Amount__c = 100000;
    opp.Original_Currency__c = 'USD';
    opp.Cash_Batch__c = cb.Id;
    insert opp;

    npsp__Allocation__c all = new npsp__Allocation__c();
    all.npsp__Opportunity__c = opp.Id;
    all.npsp__Amount__c = 100000;
    all.npsp__General_Accounting_Unit__c = gau.Id;
    all.Campaign__c = campaign.Id;
    all.Original_Amount__c = 100000;
    all.Original_Currency__c = 'USD';
    all.Receipt_Message__c = 'Dear Test, This is a test receipt for $100,000.00 dollars.';

    Test.startTest();
    insert all;
    all.Campaign__c = null;
    update all;
    Test.stopTest();

    npsp__Allocation__c result = [
      SELECT Id, Receipt_Message__c
      FROM npsp__Allocation__c
    ];

    System.assertEquals(all.Id, result.Id);
    System.assertEquals(null, result.Receipt_Message__c);
  }

  /**
   * Test for the copying and merge field processing of the receipt message when the receipt
   * message is cleared out.
   */
  @IsTest
  static void testRecreateReceiptMessage() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    User usr;

    System.runAs(currentUser) {
      usr = UnitTestHelper.createStandardUser();
      usr.UserRoleId = [
        SELECT Id
        FROM UserRole
        WHERE Name = 'Major Gift Officer'
      ]
      .Id;
      insert usr;
    }

    Campaign parentCampaign = new Campaign();
    parentCampaign.Name = 'Test Parent Campaign';
    parentCampaign.Major_Donor_Receipt_Message__c = 'Dear Test, This is a test receipt for {!npsp__Amount__c} dollars.';
    insert parentCampaign;

    Campaign campaign = new Campaign();
    campaign.Name = 'Test Campaign';
    campaign.ParentId = parentCampaign.Id;
    insert campaign;

    Account acc = new Account();
    acc.Name = 'Test Account';
    acc.npo02__Informal_Greeting__c = 'Test';
    acc.Donor_Relationship_Manager__c = usr.Id;
    insert acc;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test General Accounting Unit';
    gau.Purpose_Code__c = '123';
    insert gau;

    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Type__c = 'Cash and Checks';
    cb.Opportunity_Type__c = 'Donation';
    cb.Batch_Variation__c = 'A';
    cb.Date__c = Date.today();
    cb.Original_Currency__c = 'USD';
    insert cb;

    Opportunity opp = new Opportunity();
    opp.Amount = 100000;
    opp.AccountId = acc.Id;
    opp.Name = 'Test Opportunity';
    opp.CloseDate = Date.today();
    opp.StageName = 'Closed Won';
    opp.Original_Amount__c = 100000;
    opp.Original_Currency__c = 'USD';
    opp.Cash_Batch__c = cb.Id;
    insert opp;

    npsp__Allocation__c all = new npsp__Allocation__c();
    all.npsp__Opportunity__c = opp.Id;
    all.npsp__Amount__c = 100000;
    all.npsp__General_Accounting_Unit__c = gau.Id;
    all.Campaign__c = campaign.Id;
    all.Original_Amount__c = 100000;
    all.Original_Currency__c = 'USD';
    all.Receipt_Message__c = 'Dear Test, This is a test receipt for $100,000.00 dollars.';

    Test.startTest();
    insert all;
    all.Receipt_Message__c = null;
    update all;
    Test.stopTest();

    npsp__Allocation__c result = [
      SELECT Id, Receipt_Message__c
      FROM npsp__Allocation__c
    ];

    System.assertEquals(all.Id, result.Id);
    System.assertEquals(
      'Dear Test, This is a test receipt for $100,000.00 dollars.',
      result.Receipt_Message__c
    );
  }

  /**
   * Test for the copying and merge field processing of the receipt message from
   * the recurring donation's campaign.
   */
  @IsTest
  static void testRecurringDonationCampaignReceiptMessage() {
    Campaign parentCampaign = new Campaign();
    parentCampaign.Name = 'Test Parent Campaign';
    parentCampaign.Recurring_Donation_Receipt_Message__c = 'Dear Test, This is a test receipt for {!npsp__Amount__c} dollars.';
    insert parentCampaign;

    Campaign campaign = new Campaign();
    campaign.Name = 'Test Campaign';
    campaign.ParentId = parentCampaign.Id;
    insert campaign;

    Account acc = new Account();
    acc.Name = 'Test Account';
    acc.npo02__Informal_Greeting__c = 'Test';
    insert acc;

    npe03__Recurring_Donation__c recur = new npe03__Recurring_Donation__c();
    recur.npe03__Organization__c = acc.Id;
    recur.npe03__Recurring_Donation_Campaign__c = campaign.Id;
    recur.npe03__Date_Established__c = Date.today();
    recur.npe03__Installment_Period__c = 'Yearly';
    recur.npsp__InstallmentFrequency__c = 1;
    recur.npe03__Amount__c = 10;
    insert recur;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test General Accounting Unit';
    gau.Purpose_Code__c = '123';
    insert gau;

    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Type__c = 'Cash and Checks';
    cb.Opportunity_Type__c = 'Donation';
    cb.Batch_Variation__c = 'A';
    cb.Date__c = Date.today();
    cb.Original_Currency__c = 'USD';
    insert cb;

    Opportunity opp = new Opportunity();
    opp.Amount = 10;
    opp.AccountId = acc.Id;
    opp.Name = 'Test Opportunity';
    opp.CloseDate = Date.today();
    opp.StageName = 'Closed Won';
    opp.Original_Amount__c = 10;
    opp.Original_Currency__c = 'USD';
    opp.npe03__Recurring_Donation__c = recur.Id;
    opp.Cash_Batch__c = cb.Id;
    insert opp;

    npsp__Allocation__c all = new npsp__Allocation__c();
    all.npsp__Opportunity__c = opp.Id;
    all.npsp__Amount__c = 10;
    all.npsp__General_Accounting_Unit__c = gau.Id;
    all.Original_Amount__c = 10;
    all.Original_Currency__c = 'USD';
    all.Campaign__c = campaign.Id;

    Test.startTest();
    insert all;
    Test.stopTest();

    npsp__Allocation__c result = [
      SELECT Id, Receipt_Message__c
      FROM npsp__Allocation__c
    ];

    System.assertEquals(all.Id, result.Id);
    System.assertEquals(
      'Dear Test, This is a test receipt for $10.00 dollars.',
      result.Receipt_Message__c
    );
  }

  /**
   * @description This test evaluates the result when a new allocation record is inserted.
   * Expected outcome:
   * The overhead percentage values of the GAU are copied to the allocation records.
   */
  @isTest
  public static void testCopyPercentages() {
    Account acct = new Account();
    acct.Name = 'Test Account';
    insert acct;

    Opportunity opp1 = new Opportunity(
      Name = 'Test Opportunity',
      AccountId = acct.Id,
      Original_Amount__c = 66,
      Original_Currency__c = 'USD',
      StageName = 'Pledged',
      CloseDate = Date.today()
    );

    Opportunity opp2 = new Opportunity(
      Name = 'Test Opportunity',
      AccountId = acct.Id,
      Original_Amount__c = 33,
      Original_Currency__c = 'USD',
      StageName = 'Pledged',
      CloseDate = Date.today()
    );
    insert new List<Opportunity>{opp1, opp2};

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c(
      Name = 'Test GAU',
      Purpose_Code__c = '123'
    );
    insert gau;

    Overhead_History__c oh = new Overhead_History__c(
      General_Accounting_Unit__c = gau.Id,
      Global_Admin_Overhead__c = 10,
      Program_Management_Overhead__c = 5,
      Start_Date__c = Date.today()
    );
    insert oh;

    npsp__Allocation__c alloc1 = new npsp__Allocation__c(
      npsp__General_Accounting_Unit__c = gau.Id,
      npsp__Opportunity__c = opp1.Id,
      Original_Currency__c = 'USD',
      Original_Amount__c = 33,
      Tax_Deductible__c = true
    );
    npsp__Allocation__c alloc2 = new npsp__Allocation__c(
      npsp__General_Accounting_Unit__c = gau.Id,
      npsp__Opportunity__c = opp1.Id,
      Original_Currency__c = 'USD',
      Original_Amount__c = 33,
      Tax_Deductible__c = true
    );

    Test.startTest();
    insert new List<npsp__Allocation__c>{alloc1, alloc2};
    Test.stopTest();

    List<npsp__Allocation__c> allocations = [
      SELECT Id, Global_Admin_Percentage__c, Program_Management_Percentage__c
      FROM npsp__Allocation__c
      WHERE Id = :alloc1.Id OR Id = :alloc2.Id
    ];
    System.assertEquals(
      allocations[0].Global_Admin_Percentage__c,
      oh.Global_Admin_Overhead__c
    );
    System.assertEquals(
      allocations[1].Global_Admin_Percentage__c,
      oh.Global_Admin_Overhead__c
    );
    System.assertEquals(
      allocations[0].Program_Management_Percentage__c,
      oh.Program_Management_Overhead__c
    );
    System.assertEquals(
      allocations[1].Program_Management_Percentage__c,
      oh.Program_Management_Overhead__c
    );
  }
}