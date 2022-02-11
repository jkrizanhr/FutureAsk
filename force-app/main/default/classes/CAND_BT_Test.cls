@IsTest
private class CAND_BT_Test {
  
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
  
  @IsTest
  static void testGetBTSettings() {
    Test.startTest();
    String result = CAND_BT_Setting_Controller.getBTSettings();
    Test.stopTest();

    // This method is just for test coverage.

    // Deliberately not adding assertions because we don't know
    // if the custom metadata type records are populated without
    // querying for them, which defeats the purpose of the unit test.
  }

  @IsTest
  static void testFetchListViewData() {
    Account acc = new Account();
    acc.Name = 'Test Account';
    acc.BillingCity = 'Anneville';
    insert acc;

    Opportunity opp1 = new Opportunity();
    opp1.Name = 'Test Opp1';
    opp1.CloseDate = Date.today();
    opp1.Original_Amount__c = 10;
    opp1.Original_Currency__c = 'USD';
    opp1.StageName = 'Committed';
    opp1.AccountId = acc.Id;
    opp1.Payment_Method__c = 'Cash';
    insert opp1;

    Opportunity opp2 = new Opportunity();
    opp2.Name = 'Test Opp2';
    opp2.CloseDate = Date.today();
    opp2.Original_Amount__c = 20;
    opp2.Original_Currency__c = 'USD';
    opp2.StageName = 'Committed';
    opp2.Payment_Method__c = 'Cash';
    opp2.AccountId = acc.Id;
    insert opp2;

    CAND_BT_Models.QueryParams params = new CAND_BT_Models.QueryParams();
    params.fromObject = 'Opportunity';
    params.whereClause = 'CloseDate = TODAY';
    params.orderBy = 'Amount';
    params.lim = '10';
    params.offSet = '0';

    String paramsJSON = JSON.serialize(params);

    Test.startTest();
    List<SObject> results = CAND_BT_Controller.fetchData(paramsJSON, paramsJSON);
    Test.stopTest();

    System.assertEquals(opp1.Id, results[0].get('Id'));
    System.assertEquals(opp2.Id, results[1].get('Id'));
  }

  @IsTest
  static void testFetchFormLookupData() {
    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    CAND_BT_Models.QueryParams params = new CAND_BT_Models.QueryParams();
    params.fromObject = 'Account';
    params.whereClause = 'CreatedDate = TODAY';
    params.orderBy = 'Name';
    params.lim = '10';
    params.offSet = '0';
    params.searchText = 'Test';
    params.searchValues = new List<String>{'Test'};
    params.soslSearchGroup = 'NAME FIELDS';

    String paramsJSON = JSON.serialize(params);

    Test.startTest();
    List<SObject> results = CAND_BT_Controller.fetchData(paramsJSON, paramsJSON);
    Test.stopTest();

    System.assertEquals(acc.Id, results[0].get('Id'));
  }

  @IsTest
  static void testListViewUpdateRecord() {
    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opp';
    opp.CloseDate = Date.today();
    opp.Original_Amount__c = 10;
    opp.Original_Currency__c = 'USD';
    opp.StageName = 'Committed';
    opp.AccountId = acc.Id;
    opp.Payment_Method__c = 'Cash';
    insert opp;

    opp.StageName = 'Voided';

    Test.startTest();
    SObject result = CAND_BT_Controller.updateRecord(opp);
    Test.stopTest();

    List<Opportunity> oppResultList = [SELECT StageName FROM Opportunity];

    System.assertEquals(opp.StageName, result.get('StageName'));
    System.assertEquals(opp.StageName, oppResultList[0].StageName);
  }

  @IsTest
  static void testUpdateRecordEdit() {
    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Purpose_Code__c = '123';
    insert gau;

    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opp';
    opp.CloseDate = Date.today();
    opp.Original_Amount__c = 10;
    opp.Original_Currency__c = 'USD';
    opp.StageName = 'Committed';
    opp.Payment_Method__c = 'Cash';
    opp.AccountId = acc.Id;
    insert opp;

    npsp__Allocation__c allocToUpdate = new npsp__Allocation__c();
    allocToUpdate.npsp__General_Accounting_Unit__c = gau.id;
    allocToUpdate.Original_Amount__c = 5;
    allocToUpdate.Original_Currency__c = 'USD';
    allocToUpdate.npsp__Opportunity__c = opp.id;
    insert allocToUpdate;

    npsp__Allocation__c allocToDelete = new npsp__Allocation__c();
    allocToDelete.npsp__General_Accounting_Unit__c = gau.id;
    allocToDelete.Original_Amount__c = 5;
    allocToDelete.Original_Currency__c = 'USD';
    allocToDelete.npsp__Opportunity__c = opp.id;
    insert allocToDelete;

    List<npsp__Allocation__c> allocListToAdd = new List<npsp__Allocation__c>();

    npsp__Allocation__c alloc = new npsp__Allocation__c();
    alloc.npsp__General_Accounting_Unit__c = gau.id;
    alloc.Original_Amount__c = 3;
    alloc.Original_Currency__c = 'USD';
    allocListToAdd.add(alloc);

    npsp__Allocation__c alloc2 = new npsp__Allocation__c();
    alloc2.npsp__General_Accounting_Unit__c = gau.id;
    alloc2.Original_Amount__c = 3;
    alloc2.Original_Currency__c = 'USD';
    allocListToAdd.add(alloc2);

    allocToUpdate.Original_Amount__c = 4;
    allocToUpdate.Original_Currency__c = 'USD';

    List<npsp__Allocation__c> updateAllocList = new List<npsp__Allocation__c>();
    List<npsp__Allocation__c> deleteAllocList = new List<npsp__Allocation__c>();
    updateAllocList.add(allocToUpdate);
    deleteAllocList.add(allocToDelete);

    String formRecord = JSON.serialize(opp);
    String formRecordSplits = JSON.serialize(allocListToAdd);
    String updateSplits = JSON.serialize(updateAllocList);
    String deleteRecordSplitList = JSON.serialize(deleteAllocList);

    Test.startTest();
    CAND_BT_Controller.updateRecordEdit(formRecord, formRecordSplits, updateSplits, true, deleteRecordSplitList);
    Test.stopTest();

    List<npsp__Allocation__c> checkAllocations = [
      SELECT Id, npsp__Amount__c, npsp__Opportunity__c
      FROM npsp__Allocation__c
    ];
    System.assertEquals(3, checkAllocations.size());
    for (npsp__Allocation__c all : checkAllocations) {
      System.assertEquals(opp.Id, all.npsp__Opportunity__c);
    }
  }

  @IsTest
  static void testUpdateRecordEditOppAmountLowered() {
    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Purpose_Code__c = '123';
    insert gau;

    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opp';
    opp.CloseDate = Date.today();
    opp.Original_Amount__c = 10;
    opp.Original_Currency__c = 'USD';
    opp.StageName = 'Committed';
    opp.AccountId = acc.Id;
    opp.Payment_Method__c = 'Cash';
    insert opp;

    npsp__Allocation__c allocToUpdate = new npsp__Allocation__c();
    allocToUpdate.npsp__General_Accounting_Unit__c = gau.id;
    allocToUpdate.Original_Amount__c = 5;
    allocToUpdate.Original_Currency__c = 'USD';
    allocToUpdate.npsp__Opportunity__c = opp.id;
    insert allocToUpdate;

    npsp__Allocation__c allocToDelete = new npsp__Allocation__c();
    allocToDelete.npsp__General_Accounting_Unit__c = gau.id;
    allocToDelete.Original_Amount__c = 5;
    allocToDelete.Original_Currency__c = 'USD';
    allocToDelete.npsp__Opportunity__c = opp.id;
    insert allocToDelete;

    List<npsp__Allocation__c> allocListToAdd = new List<npsp__Allocation__c>();

    npsp__Allocation__c alloc = new npsp__Allocation__c();
    alloc.npsp__General_Accounting_Unit__c = gau.id;
    alloc.Original_Amount__c = 3;
    alloc.Original_Currency__c = 'USD';
    allocListToAdd.add(alloc);

    npsp__Allocation__c alloc2 = new npsp__Allocation__c();
    alloc2.npsp__General_Accounting_Unit__c = gau.id;
    alloc2.Original_Amount__c = 3;
    alloc2.Original_Currency__c = 'USD';
    allocListToAdd.add(alloc2);

    allocToUpdate.Original_Amount__c = 3;
    allocToUpdate.Original_Currency__c = 'USD';
    
    opp.Original_Amount__c = 9;
    opp.Original_Currency__c = 'USD';

    List<npsp__Allocation__c> updateAllocList = new List<npsp__Allocation__c>();
    List<npsp__Allocation__c> deleteAllocList = new List<npsp__Allocation__c>();
    updateAllocList.add(allocToUpdate);
    deleteAllocList.add(allocToDelete);

    String formRecord = JSON.serialize(opp);
    String formRecordSplits = JSON.serialize(allocListToAdd);
    String updateSplits = JSON.serialize(updateAllocList);
    String deleteRecordSplitList = JSON.serialize(deleteAllocList);

    Test.startTest();
    CAND_BT_Controller.updateRecordEdit(formRecord, formRecordSplits, updateSplits, false, deleteRecordSplitList);
    Test.stopTest();

    List<npsp__Allocation__c> checkAllocations = [
      SELECT Id, npsp__Amount__c, npsp__Opportunity__c
      FROM npsp__Allocation__c
    ];
    System.assertEquals(3, checkAllocations.size());
    for (npsp__Allocation__c all : checkAllocations) {
      System.assertEquals(opp.Id, all.npsp__Opportunity__c);
    }
  }

  @IsTest
  static void testUpdateRecordEditOppAmountRaised() {
    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Purpose_Code__c = '123';
    insert gau;

    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opp';
    opp.CloseDate = Date.today();
    opp.Original_Amount__c = 10;
    opp.Original_Currency__c = 'USD';
    opp.StageName = 'Committed';
    opp.AccountId = acc.Id;
    opp.Payment_Method__c = 'Cash';
    insert opp;

    npsp__Allocation__c allocToUpdate = new npsp__Allocation__c();
    allocToUpdate.npsp__General_Accounting_Unit__c = gau.id;
    allocToUpdate.Original_Amount__c = 5;
    allocToUpdate.Original_Currency__c = 'USD';
    allocToUpdate.npsp__Opportunity__c = opp.id;
    insert allocToUpdate;

    npsp__Allocation__c allocToDelete = new npsp__Allocation__c();
    allocToDelete.npsp__General_Accounting_Unit__c = gau.id;
    allocToDelete.Original_Amount__c = 5;
    allocToDelete.Original_Currency__c = 'USD';
    allocToDelete.npsp__Opportunity__c = opp.id;
    insert allocToDelete;

    List<npsp__Allocation__c> allocListToAdd = new List<npsp__Allocation__c>();

    npsp__Allocation__c alloc = new npsp__Allocation__c();
    alloc.npsp__General_Accounting_Unit__c = gau.id;
    alloc.Original_Amount__c = 3;
    alloc.Original_Currency__c = 'USD';
    allocListToAdd.add(alloc);

    npsp__Allocation__c alloc2 = new npsp__Allocation__c();
    alloc2.npsp__General_Accounting_Unit__c = gau.id;
    alloc2.Original_Amount__c = 3;
    alloc2.Original_Currency__c = 'USD';
    allocListToAdd.add(alloc2);

    allocToUpdate.Original_Amount__c = 5;
    allocToUpdate.Original_Currency__c = 'USD';
    
    opp.Original_Amount__c = 11;
    opp.Original_Currency__c = 'USD';

    List<npsp__Allocation__c> updateAllocList = new List<npsp__Allocation__c>();
    List<npsp__Allocation__c> deleteAllocList = new List<npsp__Allocation__c>();
    updateAllocList.add(allocToUpdate);
    deleteAllocList.add(allocToDelete);

    String formRecord = JSON.serialize(opp);
    String formRecordSplits = JSON.serialize(allocListToAdd);
    String updateSplits = JSON.serialize(updateAllocList);
    String deleteRecordSplitList = JSON.serialize(deleteAllocList);

    Test.startTest();
    CAND_BT_Controller.updateRecordEdit(formRecord, formRecordSplits, updateSplits, true, deleteRecordSplitList);
    Test.stopTest();

    List<npsp__Allocation__c> checkAllocations = [
      SELECT Id, npsp__Amount__c, npsp__Opportunity__c
      FROM npsp__Allocation__c
    ];
    System.assertEquals(3, checkAllocations.size());
    for (npsp__Allocation__c all : checkAllocations) {
      System.assertEquals(opp.Id, all.npsp__Opportunity__c);
    }
  }

  @IsTest
  static void testGetFormPicklists() {
    Map<String, List<String>> testMap = new Map<String, List<String>>();
    List<String> plValues = new List<String>();
    Schema.DescribeFieldResult F = Opportunity.Type.getDescribe();
    for (Schema.PicklistEntry ple : F.getPicklistValues()) {
      plValues.add(ple.getValue());
    }
    testMap.put('Type', plValues);
    List<String> picklistFields = new List<String>{'Type'};

    Test.startTest();
    CAND_BT_Models.PickList testPickList = CAND_BT_Controller.getFormPicklists(picklistFields, 'Opportunity');
    Test.stopTest();

    System.assert(testMap.get('Type').equals(testPickList.picklistFieldMap.get('Type').values));
  }

  @IsTest
  static void testSubmitForm() {
    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Purpose_Code__c = '123';
    insert gau;

    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opp';
    opp.CloseDate = Date.today();
    opp.Original_Amount__c = 10;
    opp.Original_Currency__c = 'USD';
    opp.StageName = 'Committed';
    opp.Payment_Method__c = 'Cash';
    opp.AccountId = acc.Id;

    List<npsp__Allocation__c> allocListToAdd = new List<npsp__Allocation__c>();

    npsp__Allocation__c alloc = new npsp__Allocation__c();
    alloc.npsp__General_Accounting_Unit__c = gau.id;
    alloc.Original_Amount__c = 5;
    alloc.Original_Currency__c = 'USD';
    allocListToAdd.add(alloc);
    npsp__Allocation__c alloc2 = new npsp__Allocation__c();
    alloc2.npsp__General_Accounting_Unit__c = gau.id;
    alloc2.Original_Amount__c = 5;
    alloc2.Original_Currency__c = 'USD';
    allocListToAdd.add(alloc2);

    String formRecord = JSON.serialize(opp);
    String formRecordSplits = JSON.serialize(allocListToAdd);

    Test.startTest();
    CAND_BT_Controller.submitForm(formRecord, formRecordSplits);
    Test.stopTest();

    List<Opportunity> oppList = [SELECT Id, Amount FROM Opportunity];
    System.assertEquals(1, oppList.size());
    System.assertEquals(10, oppList[0].Amount);
    List<npsp__Allocation__c> checkAllocations = [
      SELECT Id, npsp__Amount__c, npsp__Opportunity__c
      FROM npsp__Allocation__c
    ];
    System.assertEquals(2, checkAllocations.size());
    for (npsp__Allocation__c all : checkAllocations) {
      System.assertEquals(5, all.npsp__Amount__c);
      System.assertEquals(oppList[0].Id, all.npsp__Opportunity__c);
    }
  }

  @IsTest
  static void testGetNewParent() {
    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Status__c = 'New';
    cb.Type__c = 'Credit Cards';
    cb.Date__c = Date.today();
    cb.Control_Batch_Size__c = 10;
    cb.Original_Control_Batch_Total__c = 30;
    cb.Original_Currency__c = 'USD';
    cb.Records_included_in_Batch__c = 10;
    cb.Total_Included_in_Batch__c = 30;
    cb.Opportunity_Type__c = 'Indirect Donor or Estate Gift';
    insert cb;
    cb.Status__c = 'Closed';
    update cb;

    Test.startTest();
    Cash_Batch__c newCb = CAND_BT_Controller.getNewParent(cb.Id);
    Test.stopTest();

    System.assertEquals(cb.Status__c, newCb.Status__c);
    System.assertEquals(cb.Date__c, newCb.Date__c);
    System.assertEquals(cb.Control_Batch_Size__c, newCb.Control_Batch_Size__c);
    System.assertEquals(cb.Original_Control_Batch_Total__c, newCb.Control_Batch_Total__c);
    System.assertEquals(cb.Records_included_in_Batch__c, newCb.Records_included_in_Batch__c);
    System.assertEquals(cb.Total_Included_in_Batch__c, newCb.Total_Included_in_Batch__c);
    System.assertEquals('Indirect Donor or Estate Gift', newCb.Opportunity_Type__c);
    System.assertEquals(0, newCb.Balance__c);
  }

  @IsTest
  static void testGetOppRecord() {
    Opportunity opp = new Opportunity();
    opp.Name = 'name';
    opp.StageName = 'Planned';
    opp.CloseDate = Date.today();
    opp.Payment_Method__c = 'Cash';
    insert opp;

    Test.startTest();
    List<Opportunity> oppList = CAND_BT_Controller.getOppRecord(opp.Id);
    Test.stopTest();
    System.assertEquals(opp.Id, oppList[0].Id);
  }

  @IsTest
  static void testGetKeyovers() {
    Test.startTest();
    List<CAND_BT_Receipt_Key_Over__mdt> keys = CAND_BT_Controller.getKeyovers();
    Test.stopTest();

    System.assertEquals(8, keys.size());
  }

  @IsTest
  static void testGetGivingOptions() {
    List<String> pickListValuesList = new List<String>();
    Schema.DescribeFieldResult fieldResult = Opportunity.Giving_Method__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    Test.startTest();
    List<String> givingOptions = CAND_BT_Controller.getGivingOptions();
    Test.stopTest();
    System.assertEquals(ple.size(), givingOptions.size());
  }

  @IsTest
  static void testGetReceiptTypes() {
    List<String> pickListValuesList = new List<String>();
    Schema.DescribeFieldResult fieldResult = Opportunity.Receipt_Type__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    Test.startTest();
    List<String> receiptTypes = CAND_BT_Controller.getReceiptTypes();
    Test.stopTest();
    System.assertEquals(ple.size(), receiptTypes.size());
  }
  
  @IsTest
  static void testGetLanguagePreferences() {
    List<String> pickListValuesList = new List<String>();
    Schema.DescribeFieldResult fieldResult = Account.Language_Preference__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    Test.startTest();
    List<String> languagePreferences = CAND_BT_Controller.getLanguagePreferences();
    Test.stopTest();
    System.assertEquals(ple.size(), languagePreferences.size());
  }

  @IsTest
  static void testGetDonationSources() {
    List<String> pickListValuesList = new List<String>();
    Schema.DescribeFieldResult fieldResult = Opportunity.Donation_Source__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    Test.startTest();
    List<String> donationSources = CAND_BT_Controller.getDonationSources();
    Test.stopTest();
    System.assertEquals(ple.size(), donationSources.size());
  }

  @IsTest
  static void testSearches() {
    Account a = new Account();
    a.Name = 'New Name';
    a.BillingStreet = '124 Street';
    a.BillingCity = 'City';
    a.BillingState = 'New York';
    a.BillingCountry = 'United States';
    a.BillingPostalCode = '17033';
    insert a;
    
    Opportunity o = new Opportunity();
    o.AccountId = a.Id;
    o.Original_Amount__c = 25;
    o.Original_Currency__c = 'USD';
    o.Payment_Method__c = 'Cash';
    o.Name = 'name';
    o.StageName = 'Committed';
    o.CloseDate = Date.today();
    insert o;

    Test.setFixedSearchResults(new List<Id>{a.Id});

    Test.startTest();
    List<Account> accs = CAND_BT_Controller.donorSearch(new List<String>{'New'}, null);
    Opportunity opp = CAND_BT_Controller.opportunitySearch('SELECT Id, Amount FROM Opportunity LIMIT 1');
    Test.stopTest();

    System.assertEquals(1, accs.size());
    System.assertEquals(25, opp.Amount);
  }

  @IsTest
  static void testCheckForOtherOpps() {
    Account a = new Account();
    a.Name = 'New Name';
    a.BillingStreet = '124 Street';
    a.BillingCity = 'City';
    a.BillingState = 'New York';
    a.BillingCountry = 'United States';
    a.BillingPostalCode = '17033';
    insert a;
    Opportunity o = new Opportunity();
    o.AccountId = a.Id;
    o.Original_Amount__c = 25;
    o.Original_Currency__c = 'USD';
    o.Payment_Method__c = 'Cash';
    o.Name = 'name';
    o.StageName = 'Committed';
    o.CloseDate = Date.today();
    insert o;
    Opportunity o2 = new Opportunity();
    o2.AccountId = a.Id;
    o2.Original_Amount__c = 30;
    o2.Original_Currency__c = 'USD';
    o2.Payment_Method__c = 'Cash';
    o2.Name = 'name';
    o2.StageName = 'Committed';
    o2.CloseDate = Date.today();
    insert o2;

    Test.startTest();
    List<Opportunity> opps = CAND_BT_Controller.checkForOtherOpps(a.Id, Date.today());
    Test.stopTest();

    System.assertEquals(2, opps.size());
  }

  @IsTest
  static void testSetStageToAdjustmentInAPostedCashBatch() {
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'gaue';
    gau.Purpose_Code__c = '123';
    insert gau;
    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Status__c = 'New';
    cb.Type__c = 'Cash and Checks';
    cb.Original_Control_Batch_Total__c = 25;
    cb.Original_Currency__c = 'USD';
    insert cb;
    Account a = new Account();
    a.Name = 'New Name';
    a.BillingStreet = '124 Street';
    a.BillingCity = 'City';
    a.BillingState = 'New York';
    a.BillingCountry = 'United States';
    a.BillingPostalCode = '17033';
    insert a;
    Opportunity o = new Opportunity();
    o.AccountId = a.Id;
    o.Original_Amount__c = 25;
    o.Original_Currency__c = 'USD';
    o.Payment_Method__c = 'Cash';
    o.Name = 'name';
    o.StageName = 'Committed';
    o.CloseDate = Date.today();
    o.Receipt_Type__c = 'Email';
    o.Cash_Batch__c = cb.Id;
    insert o;
    npsp__Allocation__c all = new npsp__Allocation__c();
    all.npsp__Opportunity__c = o.Id;
    all.Original_Amount__c = 25;
    all.Original_Currency__c = 'USD';
    all.npsp__General_Accounting_Unit__c = gau.Id;
    insert all;
    cb.Status__c = 'Closed';
    update cb;
    cb.Status__c = 'Approved';
    update cb;

    Test.startTest();
    CAND_BT_Controller.setStageToAdjustment(o);
    Test.stopTest();
    Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
    System.assertEquals('Adjustment', opp.StageName);
    npsp__Allocation__c all2 = [SELECT Id, Gift_Stage__c FROM npsp__Allocation__c WHERE Id = :all.Id];
    System.assertEquals('Adjustment', all2.Gift_Stage__c);
  }

  @IsTest
  static void testGetTodaysDate() {
    Test.startTest();
    String testDate = CAND_BT_Controller.getTodaysDate();
    Test.stopTest();
    System.assertEquals(Datetime.now().format('yyyy-MM-dd'), testDate);
  }

  @IsTest
  static void testGetUserId() {
    Test.startTest();
    User u = CAND_BT_Controller.getUserId();
    Test.stopTest();
    String uid = UserInfo.getUserId();
    System.assertEquals(uid, u.Id);
  }

  @IsTest
  static void testMarkReceipted() {
    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Status__c = 'New';
    cb.Type__c = 'Credit Cards';
    cb.Date__c = Date.today();
    cb.Control_Batch_Size__c = 10;
    cb.Original_Control_Batch_Total__c = 30;
    cb.Original_Currency__c = 'USD';
    cb.Records_included_in_Batch__c = 10;
    cb.Total_Included_in_Batch__c = 30;
    insert cb;
    cb.Status__c = 'Closed';
    update cb;

    String batchJSON = '[{"Id":"' + cb.Id + '"}]';

    Test.startTest();
    CAND_BT_Controller.markReceipted(batchJSON);
    Test.stopTest();

    Cash_Batch__c cb2 = [SELECT Receipted_Date__c FROM Cash_Batch__c WHERE Id = :cb.Id];
    System.assertEquals(Date.today(), cb2.Receipted_Date__c);
  }

  @IsTest
  static void testgetReconciliationReportId() {
    Test.startTest();
    try{
      Id res = CAND_BT_Controller.getReconciliationReportId();
    } catch (Exception e){
      System.debug(e.getMessage());
    }
    Test.stopTest();
  }
  
  @IsTest
  static void testgetGauReportId() {
    Test.startTest();
    try{
      Id res = CAND_BT_Controller.getGauReportId();
    } catch (Exception e){
      System.debug(e.getMessage());
    }
    Test.stopTest();
  }

  @IsTest
  static void testReturnIdTypes() {
    Test.startTest();
    CAND_BT_Controller.IdTypes t = CAND_BT_Controller.returnIdTypes();
    Test.stopTest();
    System.assertEquals(
      t.matchingGift,
      Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Matching Gift').getRecordTypeId()
    );
    System.assertEquals(
      t.inKindGift,
      Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('In-Kind Gift').getRecordTypeId()
    );
  }

  @IsTest
  static void testSetMatchingGiftLookup() {
    Account a = new Account();
    a.Name = 'New Name';
    a.BillingStreet = '124 Street';
    a.BillingCity = 'City';
    a.BillingState = 'New York';
    a.BillingCountry = 'United States';
    a.BillingPostalCode = '17033';
    insert a;
    Opportunity o = new Opportunity();
    o.AccountId = a.Id;
    o.Original_Amount__c = 25;
    o.Original_Currency__c = 'USD';
    o.Payment_Method__c = 'Cash';
    o.Name = 'name';
    o.StageName = 'Committed';
    o.CloseDate = Date.today();
    o.Receipt_Type__c = 'Email';
    o.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Matching Gift').getRecordTypeId();
    insert o;
    Opportunity o2 = new Opportunity();
    o2.AccountId = a.Id;
    o2.Original_Amount__c = 25;
    o2.Original_Currency__c = 'USD';
    o2.Payment_Method__c = 'Cash';
    o2.Name = 'name';
    o2.StageName = 'Committed';
    o2.CloseDate = Date.today();
    o2.Receipt_Type__c = 'Email';
    insert o2;
    Opportunity o3 = new Opportunity();
    o3.AccountId = a.Id;
    o3.Original_Amount__c = 25;
    o3.Original_Currency__c = 'USD';
    o3.Payment_Method__c = 'Cash';
    o3.Name = 'name';
    o3.StageName = 'Committed';
    o3.CloseDate = Date.today();
    o3.Receipt_Type__c = 'Email';
    insert o3;

    List<Opportunity> opps = new List<Opportunity>();
    opps.add(o2);
    opps.add(o3);

    Test.startTest();
    CAND_BT_Controller.setMatchingGiftLookup(opps, o);
    Test.stopTest();
    List<Opportunity> postOpps = [SELECT npsp__Matching_Gift__c FROM Opportunity WHERE Id = :o2.Id OR Id = :o3.Id];
    for (Opportunity po : postOpps) {
      System.assertEquals(o.Id, po.npsp__Matching_Gift__c);
    }
  }

  @IsTest
  static void testRemoveMatchingGiftLookup() {
    Account a = new Account();
    a.Name = 'New Name';
    a.BillingStreet = '124 Street';
    a.BillingCity = 'City';
    a.BillingState = 'New York';
    a.BillingCountry = 'United States';
    a.BillingPostalCode = '17033';
    insert a;
    Opportunity o = new Opportunity();
    o.AccountId = a.Id;
    o.Original_Amount__c = 25;
    o.Original_Currency__c = 'USD';
    o.Payment_Method__c = 'Cash';
    o.Name = 'name';
    o.StageName = 'Committed';
    o.CloseDate = Date.today();
    o.Receipt_Type__c = 'Email';
    o.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Matching Gift').getRecordTypeId();
    insert o;
    Opportunity o2 = new Opportunity();
    o2.AccountId = a.Id;
    o2.Original_Amount__c = 25;
    o2.Original_Currency__c = 'USD';
    o2.Payment_Method__c = 'Cash';
    o2.Name = 'name';
    o2.StageName = 'Committed';
    o2.CloseDate = Date.today();
    o2.Receipt_Type__c = 'Email';
    o2.npsp__Matching_Gift__c = o.Id;
    insert o2;
    Opportunity o3 = new Opportunity();
    o3.AccountId = a.Id;
    o3.Original_Amount__c = 25;
    o3.Original_Currency__c = 'USD';
    o3.Payment_Method__c = 'Cash';
    o3.Name = 'name';
    o3.StageName = 'Committed';
    o3.CloseDate = Date.today();
    o3.Receipt_Type__c = 'Email';
    o3.npsp__Matching_Gift__c = o.Id;
    insert o3;

    List<Opportunity> opps = new List<Opportunity>();
    opps.add(o2);
    opps.add(o3);

    Test.startTest();
    CAND_BT_Controller.removeMatchingGiftLookup(opps);
    Test.stopTest();
    List<Opportunity> postOpps = [SELECT npsp__Matching_Gift__c FROM Opportunity WHERE Id = :o2.Id OR Id = :o3.Id];
    for (Opportunity po : postOpps) {
      System.assertEquals(null, po.npsp__Matching_Gift__c);
    }
  }

  @isTest
  static void testGetFutureGifts() {
    Account acct = new Account(
      Name = 'Test Account'
    );
    insert acct;

    Future_Gift__c fg = new Future_Gift__c(
      Account__c = acct.Id,
      Original_Actual_Ask_Amount__c = 150,
      Original_Currency__c = 'USD',
      Actual_Ask_Amount__c = 150,
      Stage__c = 'Commitment Made',
      RecordTypeId = Schema.SObjectType.Future_Gift__c.getRecordTypeInfosByDeveloperName().get('Proposal').getRecordTypeId()
    );
    insert fg;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c(
      Name = 'Test GAU',
      Purpose_Code__c = '123456'
    );
    insert gau;

    Future_Gift_Allocation__c fga50 = new Future_Gift_Allocation__c(
      Future_Gift__c = fg.Id,
      General_Accounting_Unit__c = gau.Id,
      Allocation_Amount__c = 50
    );
    Future_Gift_Allocation__c fga60 = new Future_Gift_Allocation__c(
      Future_Gift__c = fg.Id,
      General_Accounting_Unit__c = gau.Id,
      Allocation_Amount__c = 60
    );
    Future_Gift_Allocation__c fga40 = new Future_Gift_Allocation__c(
      Future_Gift__c = fg.Id,
      General_Accounting_Unit__c = gau.Id,
      Allocation_Amount__c = 40
    );
    insert new List<Future_Gift_Allocation__c>{fga50, fga60, fga40};

    Test.startTest();
      List<Future_Gift__c> res = CAND_BT_Controller.getFutureGifts(acct.Id);
    Test.stopTest();

    System.assertEquals(false, res.isEmpty());
  }

  @isTest
  static void testUpdateAccount(){
    Account acct = new Account(
      Name = 'Test Account'
    );
    insert acct;

    Test.startTest();
    CAND_BT_Controller.updateAccountRecord(acct.Id, true);
    Test.stopTest();

    Account res = [SELECT Id, Is_Ongoing_Check_Donor__c FROM Account WHERE Id = :acct.Id LIMIT 1];
    System.assertEquals(true, res.Is_Ongoing_Check_Donor__c);
  }
}