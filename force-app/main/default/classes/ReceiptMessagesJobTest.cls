@IsTest
public class ReceiptMessagesJobTest {
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
  public static void testAllocationsSetMessage() {
    Campaign c = new Campaign();
    c.Name = 'Test Campaign';
    insert c;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'generalAccountingUnit';
    gau.Purpose_Code__c = '123456';
    insert gau;

    Account a = new Account();
    a.Name = 'Account';
    insert a;

    Contact con = new Contact();
    con.LastName = 'Contact';
    insert con;

    Opportunity o = new Opportunity();
    o.Original_Amount__c = 25;
    o.Original_Currency__c = 'USD';
    o.AccountId = a.Id;
    o.Name = 'Name';
    o.StageName = 'New';
    o.CloseDate = Date.today();
    insert o;

    npsp__Allocation__c alloc = new npsp__Allocation__c();
    alloc.Campaign__c = c.Id;
    alloc.npsp__General_Accounting_Unit__c = gau.Id;
    insert alloc;

    c.Receipt_Message__c = 'This is my brand-new Receipt Message!';
    update c;
    List<Id> campaignIds = new List<Id>{ c.Id };

    Test.startTest();
    Database.executeBatch(new ReceiptMessagesJob(campaignIds), 15);
    Test.stopTest();

    List<npsp__Allocation__c> allocs = [
      SELECT Receipt_Message__c
      FROM npsp__Allocation__c
    ];
    System.assertEquals(
      'This is my brand-new Receipt Message!',
      allocs[0].Receipt_Message__c
    );
  }

  @IsTest
  public static void testAllocationsSetMessageSOQLString() {
    Campaign c = new Campaign();
    c.Name = 'Test Campaign';
    insert c;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'generalAccountingUnit';
    gau.Purpose_Code__c = '123456';
    insert gau;

    Account a = new Account();
    a.Name = 'Account';
    insert a;

    Contact con = new Contact();
    con.LastName = 'Contact';
    insert con;

    Opportunity o = new Opportunity();
    o.Original_Amount__c = 25;
    o.Original_Currency__c = 'USD';
    o.AccountId = a.Id;
    o.Name = 'Name';
    o.StageName = 'New';
    o.CloseDate = Date.today();
    insert o;

    npsp__Allocation__c alloc = new npsp__Allocation__c();
    alloc.Campaign__c = c.Id;
    alloc.npsp__General_Accounting_Unit__c = gau.Id;
    insert alloc;

    c.Receipt_Message__c = 'This is my brand-new Receipt Message!';
    update c;

    Test.startTest();
    Database.executeBatch(
      new ReceiptMessagesJob('SELECT Id FROM npsp__Allocation__c'),
      15
    );
    Test.stopTest();

    List<npsp__Allocation__c> allocs = [
      SELECT Receipt_Message__c
      FROM npsp__Allocation__c
    ];
    System.assertEquals(
      'This is my brand-new Receipt Message!',
      allocs[0].Receipt_Message__c
    );
  }
}