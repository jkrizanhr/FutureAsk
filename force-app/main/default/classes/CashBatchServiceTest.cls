@IsTest
public class CashBatchServiceTest {
  
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
  public static void testErrorOnDuplicateBatch() {
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

    Cash_Batch__c cbTwo = new Cash_Batch__c();
    cbTwo.Type__c = 'Cash and Checks';
    cbTwo.Opportunity_Type__c = 'Donation';
    cbTwo.Batch_Variation__c = 'A';
    cbTwo.Date__c = Date.today();
    cbTwo.Original_Currency__c = 'USD';
    cbTwo.Keyer__c = receiptingUser.Id;

    Boolean exceptionMessage = false;
    Test.startTest();
    try {
      insert cbTwo;
    } catch (Exception e) {
      exceptionMessage = e.getMessage()
        .contains('There is already an open Batch with this Date, Type and Batch Variation.');
    }
    Test.stopTest();
  }
  @IsTest
  public static void testSnsureBatchIsEditable() {
    Account a = new Account();
    a.Name = 'a';
    a.BillingStreet = '123 Test St.';
    a.BillingCity = 'Annville';
    a.BillingState = 'Pennsylvania';
    a.BillingPostalCode = '17003';
    a.BillingCountry = 'United States';
    insert a;

    Contact c = new Contact();
    c.LastName = 'LastName';
    c.Email = 'email@email.com';
    c.AccountId = a.Id;
    insert c;
    a.npe01__One2OneContact__c = c.Id;
    update a;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Purpose_Code__c = '123';
    insert gau;

    Cash_Batch__c cb = new Cash_Batch__c();
    cb.Type__c = 'Credit Cards';
    cb.Original_Control_Batch_Total__c = 25;
    cb.Original_Currency__c = 'USD';
    cb.Status__c = 'New';
    insert cb;
    Opportunity opp = new Opportunity();
    opp.Original_Amount__c = 25;
    opp.Original_Currency__c = 'USD';
    opp.Cash_Batch__c = cb.Id;
    opp.Name = 'm';
    opp.StageName = 'Posted';
    opp.CloseDate = Date.today();
    opp.Payment_Method__c = 'Credit Card';
    opp.AccountId = a.Id;
    opp.npsp__Primary_Contact__c = c.Id;
    opp.Receipt_Type__c = 'Email';
    insert opp;
    npsp__Allocation__c all = new npsp__Allocation__c();
    all.npsp__Opportunity__c = opp.Id;
    all.Original_Amount__c = 25;
    all.Original_Currency__c = 'USD';
    all.npsp__General_Accounting_Unit__c = gau.Id;
    insert all;

    cb.Status__c = 'Approved';
    update cb;

    Boolean exceptionMessage = false;
    Test.startTest();
    try {
      cb.Date__c = Date.Today().addDays(-10);
      update cb;
    } catch (Exception e) {
      exceptionMessage = e.getMessage()
        .contains('The following fields cannot edited if the Batch is locked: Date, Opportunity Type, Batch Variation, Type, Original Currency, Original Control Batch Total, Control Batch Total and Control Batch Size.');
    }
    Test.stopTest();
  }
}