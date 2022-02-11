/**
 * @description This class tests the logic of the GAUBalanceJob class.
 */
@isTest
public without sharing class GAUBalanceJobTest {
  /**
   * @description This method creates the data to be used in the following tests.
   */
  @testSetup
  public static void createData() {
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

    Account a = new Account();
    a.Name = 'Test Account';
    insert a;

    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Original_Control_Batch_Total__c = 11;
    cb.Original_Currency__c = 'USD';
    cb.Status__c = 'New';
    cb.Type__c = 'Credit Cards';
    insert cb;

    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opp';
    opp.Amount = 50;
    opp.StageName = 'Posted';
    opp.CloseDate = Date.today();
    opp.AccountId = a.Id;
    opp.Cash_Batch__c = cb.Id;
    insert opp;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test GAU';
    gau.Purpose_Code__c = 'gau1';
    npsp__General_Accounting_Unit__c gau2 = new npsp__General_Accounting_Unit__c();
    gau2.Name = 'Test GAU 2';
    gau2.Purpose_Code__c = 'gau2';
    insert new List<npsp__General_Accounting_Unit__c>{gau, gau2};

    npsp__Allocation__c alloc = new npsp__Allocation__c();
    alloc.npsp__Amount__c = 20;
    alloc.npsp__Opportunity__c = opp.Id;
    alloc.npsp__General_Accounting_Unit__c = gau.Id;
    npsp__Allocation__c alloc2 = new npsp__Allocation__c();
    alloc2.npsp__Amount__c = 30;
    alloc2.npsp__Opportunity__c = opp.Id;
    alloc2.npsp__General_Accounting_Unit__c = gau2.Id;
    insert new List<npsp__Allocation__c>{alloc, alloc2};

    GAU_Balance__c balance = new GAU_Balance__c();
    balance.General_Accounting_Unit__c = gau.Id;
    balance.Date__c = Date.today();
    balance.GP_Balance__c = 100;
    GAU_Balance__c balance2 = new GAU_Balance__c();
    balance2.General_Accounting_Unit__c = gau2.Id;
    balance2.Date__c = Date.today();
    balance2.GP_Balance__c = 500;
    insert new List<GAU_Balance__c>{balance, balance2};

    Expense__c exp = new Expense__c();
    exp.Date__c = Date.today();
    exp.General_Accounting_Unit__c = gau.Id;
    exp.Amount__c = 25;
    Expense__c exp2 = new Expense__c();
    exp2.Date__c = Date.today();
    exp2.General_Accounting_Unit__c = gau2.Id;
    exp2.Amount__c = 45;
    insert new List<Expense__c>{exp, exp2};

    Transfer__c t = new Transfer__c();
    t.Date__c = Date.today();
    t.Amount__c = 50;
    t.Primary_General_Accounting_Unit__c = gau.Id;
    t.Secondary_General_Accounting_Unit__c = gau2.Id;
    t.Type__c = 'To';
    t.Status__c = 'Complete';
    insert t;
  }

  /**
   * @description This test evaluates the result when the job is run against GAU records.
   * Expected outcome:
   * The GAU current balance value is updated.
   */
  @isTest
  public static void testJob() {
    Test.startTest();
    Database.executeBatch(new GAUBalanceJob());
    Test.stopTest();

    List<npsp__General_Accounting_Unit__c> gaus = [
      SELECT Id, Name, Current_Balance__c
      FROM npsp__General_Accounting_Unit__c
    ];
    System.assertEquals(
      2,
      gaus.size(),
      'The wrong number of GAUs were returned.'
    );

    for (npsp__General_Accounting_Unit__c gau : gaus) {
      if (gau.Name == 'Test GAU') {
        System.assertEquals(
          45,
          gau.Current_Balance__c,
          'Balance did not match expected value.'
        );
      } else if (gau.Name == 'Test GAU 2') {
        System.assertEquals(
          535,
          gau.Current_Balance__c,
          'Balance did not match expected value.'
        );
      }
    }
  }

  /**
   * @description This test evaluates the result when the job is run against GAU records with old
   * expense records.
   * Expected outcome:
   * The GAU current balance value is updated.
   */
  @isTest
  public static void testJobWithOldDates() {
    List<Expense__c> expenses = [SELECT Id, Date__c FROM Expense__c];

    for (Expense__c exp : expenses) {
      exp.Date__c = Date.today().addDays(-10);
    }

    update expenses;

    Test.startTest();
    Database.executeBatch(new GAUBalanceJob());
    Test.stopTest();

    List<npsp__General_Accounting_Unit__c> gaus = [
      SELECT Id, Name, Current_Balance__c
      FROM npsp__General_Accounting_Unit__c
    ];
    System.assertEquals(
      2,
      gaus.size(),
      'The wrong number of GAUs were returned.'
    );

    for (npsp__General_Accounting_Unit__c gau : gaus) {
      if (gau.Name == 'Test GAU') {
        System.assertEquals(
          70,
          gau.Current_Balance__c,
          'Balance did not match expected value.'
        );
      } else if (gau.Name == 'Test GAU 2') {
        System.assertEquals(
          580,
          gau.Current_Balance__c,
          'Balance did not match expected value.'
        );
      }
    }
  }
}