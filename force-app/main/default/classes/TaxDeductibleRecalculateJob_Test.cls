@isTest
private class TaxDeductibleRecalculateJob_Test {
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

      Account acc = new Account();
      acc.Name = 'test';
      insert acc;

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
      o.AccountId = acc.Id;
      o.Name = 'opp';
      o.StageName = 'Closed-Won';
      o.CloseDate = Date.today();
      o.Cash_Batch__c = cb.Id;
      o.Receipt_Type__c = 'Email';
      insert o;

      npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
      gau.Name = 'Test Fund';
      gau.Purpose_Code__c = '123456';
      insert gau;

      npsp__Allocation__c alloc = new npsp__Allocation__c();
      alloc.npsp__Opportunity__c = o.Id;
      alloc.Original_Amount__c = 10;
      alloc.Original_Currency__c = 'USD';
      alloc.npsp__General_Accounting_Unit__c = gau.Id;
      alloc.Tax_Deductible__c = true;
      insert alloc;
    } 

    @isTest
    static void testTaxDeductibleRecalculateJob() {
      Test.startTest();
      Id jobId = Database.executeBatch(new TaxDeductibleRecalculateJob(null), 25);
      System.assert(jobId != null, 'A job should be scheduled');
      Test.stopTest();
    }
}