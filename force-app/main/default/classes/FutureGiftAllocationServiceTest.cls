@isTest
private class FutureGiftAllocationServiceTest {
  private class AllocationValidationException extends Exception{}

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
  static void allocationAmountNotToExceedFutureGiftTest() {
    Account acct = new Account(
      Name = 'Test Account'
    );
    insert acct;

    Contact con1 = new Contact(
      LastName = 'Test1'
    );
    Contact con2 = new Contact(
      LastName = 'Test2'
    );
    insert new List<Contact>{con1, con2};  

    Future_Gift__c fg = new Future_Gift__c(
      Account__c = acct.Id,
      Original_Actual_Ask_Amount__c = 100,
      Original_Currency__c = 'USD',
      Actual_Ask_Amount__c = 100,
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

    Test.startTest();
      // TEST INSERT FUTURE ASK ALLOCATION WITH GOOD VALUE
      try {
        insert fga50;
      } 
      catch(Exception e) {
        throw new AllocationValidationException('An exception should NOT have been thrown by the trigger but was.'); 
      } 
      // TEST INSERT FUTURE ASK ALLOCATION WITH BAD VALUE
      try {
        insert fga60;
        throw new AllocationValidationException('An exception should have been thrown by the trigger but was not.'); 
      } 
      catch(Exception e) {
        System.debug(e.getMessage());
        Boolean expectedExceptionThrown =  e.getMessage().contains('The sum of the Future Ask Allocations cannot exceed the Future Ask Actual Amount.') 
          ? true 
          : false;
        System.AssertEquals(expectedExceptionThrown, true);
      } 
      List<Future_Gift_Allocation__c> fgaList = [SELECT Id, Future_Gift__c, Allocation_Amount__c FROM Future_Gift_Allocation__c WHERE Future_Gift__c = :fg.Id];
      System.debug(fgaList);
      // TEST INSERT FUTURE ASK ALLOCATION WITH GOOD VALUE
      try {
        insert fga40;
      } 
      catch(Exception e) {
        System.debug(e.getMessage());
        throw new AllocationValidationException('An exception should NOT have been thrown by the trigger but was.'); 
      } 
      
      // TEST UPDATE FUTURE ASK ALLOCATION WITH GOOD VALUES
      try {
        fga50.Allocation_Amount__c = 20;
        fga40.Allocation_Amount__c = 60;
        update new List<Future_Gift_Allocation__c>{fga50, fga40};
      } 
      catch(Exception e) {
        System.debug(e.getMessage());
        throw new AllocationValidationException('An exception should NOT have been thrown by the trigger but was.'); 
      } 
      // TEST UPDATE FUTURE ASK ALLOCATION WITH BAD VALUE
      try {
        fga50.Allocation_Amount__c = 70;
        update fga50;
        throw new AllocationValidationException('An exception should have been thrown by the trigger but was not.'); 
      } 
      catch(Exception e) {
        System.debug(e.getMessage());
        Boolean expectedExceptionThrown =  e.getMessage().contains('The sum of the Future Ask Allocations cannot exceed the Future Ask Actual Amount.') 
          ? true 
          : false;
        System.AssertEquals(expectedExceptionThrown, true);
      } 
    Test.stopTest();
  }
}