@isTest
public class OpportunityServiceTest {
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
  // Test converting the opportunity amount from USD to GDP on insert as well as 
  // the rounding of result from the currency conversion. 
  @IsTest
  static void testConvertUSDtoGBPBeforeInsert() {
    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

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

    Opportunity opp = new Opportunity();
    opp.AccountId = acc.Id;
    opp.CloseDate = Date.today();
    opp.Name = 'Test Opportunity';
    opp.Original_Amount__c = 109; // The amount is $109 to test rounding up (half up).
    opp.Original_Currency__c = 'USD';
    opp.StageName = 'Posted';
    opp.Cash_Batch__c = cb.Id;

    Test.startTest();
    insert opp;
    Test.stopTest();

    List<Opportunity> results = [
        SELECT Amount, Id, Original_Amount__c, Original_Currency__c
        FROM Opportunity
    ];

    // USD Rate: 1.10385, GBP Rate: 0.855313, Amount: 109.00
    // Formula: GBP_Amount = (Opp.Amount / USD_Rate) * GBP_Rate
    System.assertEquals(1, results.size());
    System.assertEquals(opp.Id, results[0].Id);
    System.assertEquals(109, results[0].Amount);
    System.assertEquals(109, results[0].Original_Amount__c);
    System.assertEquals('USD', results[0].Original_Currency__c);
  }

  // Test converting the opportunity amount from USD to GDP on update as well as the currency 
  // being changed.
  @IsTest
  static void testConvertUSDtoGBPBeforeUpdate() {
    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    Decimal usdRate = 1.107506;
    Decimal gbpRate = 0.860309;

    Currency_Exchange_Rate__c rate = new Currency_Exchange_Rate__c();
    rate.Api_Response__c = CurrencyExchangeRateTestHelper.getResponseString(
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

    Opportunity opp = new Opportunity();
    opp.AccountId = acc.Id;
    opp.CloseDate = Date.today();
    opp.Name = 'Test Opportunity';
    opp.Original_Amount__c = 100;
    opp.Original_Currency__c = 'USD';
    opp.StageName = 'Posted';
    opp.Cash_Batch__c = cb.Id;
    insert opp;

    opp.Original_Amount__c = 200;
    opp.Original_Currency__c = 'GBP';

    List<Opportunity> initialResults = [
        SELECT Amount, Id, Original_Amount__c, Original_Currency__c
        FROM Opportunity
    ];

    System.assertEquals(1, initialResults.size());
    System.assertEquals(opp.Id, initialResults[0].Id);
    System.assertEquals(100, initialResults[0].Amount);
    System.assertEquals(100, initialResults[0].Original_Amount__c);
    System.assertEquals('USD', initialResults[0].Original_Currency__c);

    Test.startTest();
    update opp;
    Test.stopTest();

    List<Opportunity> finalResults = [
        SELECT Amount, Id, Original_Amount__c, Original_Currency__c
        FROM Opportunity
    ];

    System.assertEquals(1, finalResults.size());
    System.assertEquals(opp.Id, finalResults[0].Id);
    System.assertEquals(257.47, finalResults[0].Amount); // 257.467026382
    System.assertEquals(200, finalResults[0].Original_Amount__c);
    System.assertEquals('GBP', finalResults[0].Original_Currency__c);
  }

  @isTest
  static void testSoftCredits() {
    List<Account> acctList = new List<Account>();
    Account a1 = new Account(Name = 'a1');
    acctList.add(a1);
    Account a2 = new Account(Name = 'a2');
    acctList.add(a2);
    insert acctList;

    Account_Relationship__c ar = new Account_Relationship__c(
      Account__c = a2.Id,
      Related_Account__c = a1.Id,
      Status__c = 'Current',
      Type__c = 'Partner',
      Receives_Soft_Credit__c = true,
      Soft_Credit_Role__c = 'Match'
    );
    insert ar;

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

    Opportunity opp = new Opportunity(
      Name = 'test opp',
      Original_Amount__c = 11,
      Original_Currency__c = 'USD',
      CloseDate = Date.today(),
      StageName = 'Closed Won',
      AccountId = a1.Id,
      Cash_Batch__c = cb.Id
    );

    Test.startTest();
    insert opp;
    Test.stopTest();

    npsp__Account_Soft_Credit__c sc = [
      SELECT Id, npsp__Amount__c, npsp__Opportunity__c, npsp__Account__c, npsp__Role__c
      FROM npsp__Account_Soft_Credit__c
      WHERE npsp__Account__c = :a2.Id
      LIMIT 1
    ];

    System.assertEquals(11, sc.npsp__Amount__c, 'The soft credit amount should be equal to opp amount');
    System.assertEquals(
      a2.Id,
      sc.npsp__Account__c,
      'The account should be for the "Account" in the Account Relationship'
    );
    System.assertEquals(opp.Id, sc.npsp__Opportunity__c, 'The account soft credit should be linked to the opp');
    System.assertEquals('Match', sc.npsp__Role__c, 'The account soft credit should be linked to the opp');
  }

  @isTest
  static void testUpdateAmountOnSoftCredit() {
    List<Account> acctList = new List<Account>();
    Account a1 = new Account(Name = 'a1');
    acctList.add(a1);
    Account a2 = new Account(Name = 'a2');
    acctList.add(a2);
    Account a3 = new Account(Name = 'a3');
    acctList.add(a3);
    insert acctList;

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

    Opportunity opp = new Opportunity(
      Name = 'test opp',
      Original_Amount__c = 11,
      Original_Currency__c = 'USD',
      CloseDate = Date.today(),
      StageName = 'Closed Won',
      AccountId = a1.Id,
      Cash_Batch__c = cb.Id
    );
    insert opp;

    List<npsp__Account_Soft_Credit__c> scList = new List<npsp__Account_Soft_Credit__c>();
    npsp__Account_Soft_Credit__c sc1 = new npsp__Account_Soft_Credit__c(
      npsp__Account__c = a2.Id,
      npsp__Amount__c = opp.Amount,
      npsp__Opportunity__c = opp.Id,
      npsp__Role__c = 'Match'
    );
    scList.add(sc1);
    npsp__Account_Soft_Credit__c sc2 = new npsp__Account_Soft_Credit__c(
      npsp__Account__c = a3.Id,
      npsp__Amount__c = 20,
      npsp__Opportunity__c = opp.Id,
      npsp__Role__c = 'Match'
    );
    scList.add(sc2);
    insert scList;

    Test.startTest();
    opp.Original_Amount__c = 23;
    update opp;
    Test.stopTest();

    List<npsp__Account_Soft_Credit__c> scUpdateList = [
      SELECT Id, npsp__Amount__c, npsp__Opportunity__c, npsp__Account__c, npsp__Role__c
      FROM npsp__Account_Soft_Credit__c
      WHERE npsp__Account__c = :a2.Id OR npsp__Account__c = :a3.Id
    ];

    for (npsp__Account_Soft_Credit__c sc : scUpdateList) {
      if (sc.npsp__Account__c == a2.Id) {
        System.assertEquals(23, sc.npsp__Amount__c, 'The soft credit amount should be equal to opp amount');
      } else if (sc.npsp__Account__c == a3.Id) {
        System.assertEquals(
          20,
          sc.npsp__Amount__c,
          'The soft credit amount should not change because a custom amount was set'
        );
      }
    }
  }

  @isTest
  static void testIgnoreBatchLocking() {
    Account a = new Account();
    a.Name = 'Reichert';
    insert a;
    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Type__c = 'Cash and Checks';
    cb.Status__c = 'New';
    cb.Original_Control_Batch_Total__c = 50;
    cb.Original_Currency__c = 'USD';
    insert cb;
    Opportunity o = new Opportunity();
    o.Original_Amount__c = 50;
    o.Original_Currency__c = 'USD';
    o.Payment_Method__c = 'Cash';
    o.AccountId = a.Id;
    o.Name = 'opp';
    o.StageName = 'Closed-Won';
    o.CloseDate = Date.today();
    o.Cash_Batch__c = cb.Id;
    o.Receipt_Type__c = 'Email';
    insert o;
    cb.Status__c = 'Approved';
    update cb;

    Test.startTest();
    o.Payment_Method__c = 'Check';
    update o;
    Test.stopTest();

    Opportunity opp = [SELECT Payment_Method__c FROM Opportunity LIMIT 1];
    System.assertEquals('Check', opp.Payment_Method__c);
  }

  @IsTest
  static void testEnsureGiftsCanBeMatchedWhenClosed() {
    Account a = new Account();
    a.Name = 'Reichert';
    insert a;    
    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Type__c = 'Cash and Checks';
    cb.Status__c = 'New';
    cb.Original_Control_Batch_Total__c = 50;
    cb.Original_Currency__c = 'USD';
    insert cb;
    Opportunity o = new Opportunity();
    o.Original_Amount__c = 50;
    o.Original_Currency__c = 'USD';
    o.Payment_Method__c = 'Cash';
    o.AccountId = a.Id;
    o.Name = 'opp';
    o.StageName = 'Closed-Won';
    o.CloseDate = Date.today();
    o.Cash_Batch__c = cb.Id;
    o.Receipt_Type__c = 'Email';
    insert o;
    cb.Status__c = 'Approved';
    update cb;
    Opportunity matchedGift = new Opportunity();
    matchedGift.Original_Amount__c = 24;
    matchedGift.Original_Currency__c = 'USD';
    matchedGift.Payment_Method__c = 'Cash';
    matchedGift.AccountId = a.Id;
    matchedGift.Name = 'opp';
    matchedGift.StageName = 'Planned';
    matchedGift.CloseDate = Date.today();
    matchedGift.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
      .get('MatchingGift')
      .getRecordTypeId();
    insert matchedGift;

    Test.startTest();
    o.npsp__Matching_Gift__c = matchedGift.Id;
    update o;
    Test.stopTest();

    Opportunity oCheck = [
      SELECT npsp__Matching_Gift__c
      FROM Opportunity
      WHERE Id = :o.Id
    ];
    System.assertEquals(matchedGift.Id, oCheck.npsp__Matching_Gift__c);
  }

  @isTest
  static void testGiftPlanRollups() {
    Account acct = new Account();
    acct.Name = 'Test Account';
    insert acct;

    Future_Gift__c fg = new Future_Gift__c();
    fg.Account__c = acct.Id;
    insert fg;

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

    List<Opportunity> oppList = new List<Opportunity>();
    Opportunity opp1 = new Opportunity();
    opp1.Name = 'Test Opportunity';
    opp1.AccountId = acct.Id;
    opp1.Original_Amount__c = 100;
    opp1.Original_Currency__c = 'USD';
    opp1.StageName = 'Closed Lost';
    opp1.CloseDate = Date.today();
    opp1.Future_Gift__c = fg.Id;
    opp1.Cash_Batch__c = cb.Id;
    oppList.add(opp1);

    Opportunity opp2 = new Opportunity();
    opp2.Name = 'Test Opportunity';
    opp2.AccountId = acct.Id;
    opp2.Original_Amount__c = 100;
    opp2.Original_Currency__c = 'USD';
    opp2.StageName = 'Closed Won';
    opp2.CloseDate = Date.today().addDays(-3);
    opp2.Cash_Batch__c = cb.Id;
    oppList.add(opp2);
    insert oppList;
    
    Opportunity opp3 = new Opportunity();
    opp3.Name = 'Test Opportunity';
    opp3.AccountId = acct.Id;
    opp3.Original_Amount__c = 100;
    opp3.Original_Currency__c = 'USD';
    opp3.StageName = 'Closed Won';
    opp3.CloseDate = Date.today().addDays(-2);
    opp3.Future_Gift__c = fg.Id;
    opp3.Cash_Batch__c = cb.Id;
        
    Test.startTest();
      // INSERT OPPORTUNITY TEST (Insert Opportunity 3 with the Future_Gift__c field set)
      insert opp3;
      Future_Gift__c fgRes1 = [SELECT Id, Amount_Received__c FROM Future_Gift__c WHERE Id = :fg.Id];
      System.assertEquals(100, fgRes1.Amount_Received__c, 'The Amount Received should be 100 (opp3).');

      // UPDATE OPPORTUNITY TEST (Update Opportunity 2 to have Future_Gift__c field set)
      opp2.Future_Gift__c = fg.Id;
      update opp2;
      Future_Gift__c fgRes2 = [SELECT Id, Amount_Received__c FROM Future_Gift__c WHERE Id = :fg.Id];
      System.assertEquals(200, fgRes2.Amount_Received__c, 'The Amount Received should be 200 (opp2 and opp3).');

      // UPDATE OPPORTUNITY TEST (Update Opportunity 2 to not have Future_Gift__c field set and Opportunity 1 to have a Closed Won StageName)
      oppList[0].StageName = 'Closed Won';  //opp1
      oppList[1].Future_Gift__c = null;       //opp2
      update oppList;
      Future_Gift__c fgRes3 = [SELECT Id, Amount_Received__c FROM Future_Gift__c WHERE Id = :fg.Id];
      System.assertEquals(200, fgRes3.Amount_Received__c, 'The Amount Received should be 200 (opp1 and opp3).');

      // DELETE OPPORTUNITY TEST (Delete Opportunity 3 with the Future_Gift__c field set)
      delete opp3;
      Future_Gift__c fgRes4 = [SELECT Id, Amount_Received__c FROM Future_Gift__c WHERE Id = :fg.Id];    
      System.assertEquals(100, fgRes4.Amount_Received__c, 'The Amount Received should be 100 (opp1).');

      // UNDELETE OPPORTUNITY TEST (Undelete Opportunity 3 with the Future_Gift__c field set)
      undelete opp3;
      Future_Gift__c fgRes5 = [SELECT Id, Amount_Received__c FROM Future_Gift__c WHERE Id = :fg.Id];
      System.assertEquals(200, fgRes5.Amount_Received__c, 'The Amount Received should be 200 (opp1 and opp3).');
    Test.stopTest();
  }
      
  @isTest
  static void testCreateOpportuntityContactRolesFromFutureGift() {
    
    Account acct1 = new Account(
      Name = 'Test Account1'
    );
    Account acct2 = new Account(
      Name = 'Test Account2'
    );
    insert new List<Account>{acct1, acct2};

    Contact con1 = new Contact(
      LastName = 'Test1'
    );
    Contact con2 = new Contact(
      LastName = 'Test2'
    );
    Contact con3 = new Contact(
      LastName = 'Test3'
    );
    insert new List<Contact>{con1, con2, con3};  

    Future_Gift__c fg = new Future_Gift__c(
      Account__c = acct1.Id
    );
    insert fg;

    Future_Gift_Role__c fgr1 = new Future_Gift_Role__c(
      Contact__c = con1.Id,
      Future_Gift__c = fg.Id,
      Role__c = 'Family Member',
      Status__c = 'Current',
      Soft_Credit__c = true
    );
    Future_Gift_Role__c fgr2 = new Future_Gift_Role__c(
      Contact__c = con2.Id,
      Future_Gift__c = fg.Id,
      Role__c = 'Family Member',
      Status__c = 'Former'
    );
    Future_Gift_Role__c fgr3 = new Future_Gift_Role__c(
      Contact__c = con3.Id,
      Future_Gift__c = fg.Id,
      Role__c = 'Family Member',
      Status__c = 'Former',
      Soft_Credit__c = true
    );
    Future_Gift_Role__c fgr4 = new Future_Gift_Role__c(
      Organization__c = acct2.Id,
      Future_Gift__c = fg.Id,
      Role__c = 'Family Member',
      Status__c = 'Former',
      Soft_Credit__c = true
    );
    insert new List<Future_Gift_Role__c>{fgr1, fgr2, fgr3, fgr4};

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
    
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      AccountId = acct1.Id,
      npsp__Primary_Contact__c = con1.Id,
      Original_Amount__c = 100,
      Original_Currency__c = 'USD',
      StageName = 'Closed Won',
      CloseDate = Date.today(),
      Future_Gift__c = fg.Id,
      Cash_Batch__c = cb.Id
    );
    
    Test.startTest();
      // INSERT OPPORTUNITY TEST 
      insert opp;
      List<OpportunityContactRole> results1 = [SELECT ContactId, Role, IsPrimary FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];
      System.assertEquals(3, results1.size(), 'There should be three opp contact roles created for the contacts.');
      for (OpportunityContactRole res : results1){
        if (res.ContactId == con1.Id){
          System.assertEquals(true, res.isPrimary, 'This should be set by NPSP triggers. If created by this trigger then primary would be false.');
        } else if (res.ContactId == con2.Id) {
          System.assertEquals('Influencer', res.Role, 'Role was not set correctly.');
        } else if (res.ContactId == con3.Id) {
          System.assertEquals('Soft Credit', res.Role, 'Role was not set correctly.');
        }
      }
      List<npsp__Account_Soft_Credit__c> results2 = [SELECT npsp__Account__c, npsp__Opportunity__c, npsp__Role__c FROM npsp__Account_Soft_Credit__c WHERE npsp__Opportunity__c = :opp.Id];
      System.assertEquals(1, results2.size(), 'There should be one acct soft credit created for the acct.');
      System.assertEquals(acct2.Id, results2[0].npsp__Account__c, 'Acct was not set correctly.');
      System.assertEquals('Soft Credit', results2[0].npsp__Role__c, 'Role was not set correctly.');
    Test.stopTest();
  }

  @isTest
  static void testBatchAdjustmentDonations() {
    Account acc = new Account(
      Name = 'Test Account'
    );
    insert acc;

    List<Opportunity> oppGroup1 = new List<Opportunity>();
    Opportunity opp1 = new Opportunity(
      Name = 'test',
      AccountId = acc.Id,
      StageName = 'Adjustment',
      CloseDate = Date.today(),
      Amount = 100,
      Original_Currency__c = 'USD',
      Payment_Method__c = 'Credit Card',
      Credit_Card_Type__c = 'VISA'
    );
    oppGroup1.add(opp1);

    Opportunity opp2 = new Opportunity(
      Name = 'test',
      AccountId = acc.Id,
      StageName = 'Adjustment',
      CloseDate = Date.today(),
      Amount = 200,
      Original_Currency__c = 'USD',
      Payment_Method__c = 'Credit Card',
      Credit_Card_Type__c = 'AMEX'
    );
    oppGroup1.add(opp2);

    Opportunity opp3 = new Opportunity(
      Name = 'test',
      AccountId = acc.Id,
      StageName = 'Adjustment',
      CloseDate = Date.today(),
      Amount = 300,
      Original_Currency__c = 'USD',
      Payment_Method__c = 'Bank Account'
    );
    oppGroup1.add(opp3);

    List<Opportunity> oppGroup2 = new List<Opportunity>();
    Opportunity opp4 = new Opportunity(
      Name = 'test',
      AccountId = acc.Id,
      StageName = 'Adjustment',
      CloseDate = Date.today(),
      Amount = 300,
      Original_Currency__c = 'USD',
      Payment_Method__c = 'Credit Card',
      Credit_Card_Type__c = 'VISA'
    );
    oppGroup2.add(opp4);

    Opportunity opp5 = new Opportunity(
      Name = 'test',
      AccountId = acc.Id,
      StageName = 'Adjustment',
      CloseDate = Date.today(),
      Amount = 500,
      Original_Currency__c = 'USD',
      Payment_Method__c = 'Credit Card',
      Credit_Card_Type__c = 'AMEX'
    );
    oppGroup2.add(opp5);

    Opportunity opp6 = new Opportunity(
      Name = 'test',
      AccountId = acc.Id,
      StageName = 'Adjustment',
      CloseDate = Date.today(),
      Amount = 600,
      Original_Currency__c = 'USD',
      Payment_Method__c = 'Bank Account'
    );
    oppGroup2.add(opp6);

    Test.startTest();
    insert oppGroup1;

    List<Cash_Batch__c> cashBatches = [
      SELECT Id, Type__c, Is_Locked__c, Batch_Variation__c
      FROM Cash_Batch__c
      WHERE 
        Type__c = 'Adjustments'
        AND (Batch_Variation__c = 'AA' OR Batch_Variation__c = 'BB' OR Batch_Variation__c = 'CC')
        AND Date__c = TODAY
    ];
    System.assertEquals(3, cashBatches.size());

    insert oppGroup2;
    Test.stopTest();

    List<Opportunity> oppList = [
      SELECT 
        Id, Amount, Payment_Method__c, Credit_Card_Type__c, 
        Cash_Batch__c, Cash_Batch__r.Type__c, Cash_Batch__r.Batch_Variation__c
      FROM Opportunity
    ];
    for (Opportunity opp : oppList) {
      if (opp.Amount == 1234) {
        System.assertEquals(null, opp.Cash_Batch__c);
      }
      if (opp.Payment_Method__c == 'Credit Card') {
        System.assertEquals('Adjustments', opp.Cash_Batch__r.Type__c);
        if (opp.Credit_Card_Type__c != 'AMEX') {
          System.assertEquals('AA', opp.Cash_Batch__r.Batch_Variation__c);
        } else {
          System.assertEquals('BB', opp.Cash_Batch__r.Batch_Variation__c);
        }
      } else if (opp.Payment_Method__c == 'Bank Account') {
        System.assertEquals('Adjustments', opp.Cash_Batch__r.Type__c);
        System.assertEquals('CC', opp.Cash_Batch__r.Batch_Variation__c);
      }
    }
  }
}