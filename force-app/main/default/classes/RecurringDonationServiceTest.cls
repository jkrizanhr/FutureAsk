@isTest
private class RecurringDonationServiceTest {
    
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
  static void recurringDonationSustainerRollupTest() {
    Account acct = new Account(
      Name = 'Test Account'
    );
    insert acct;

    npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
      Name = 'Test Recurring Donation',
      npe03__Organization__c = acct.Id,
      npe03__Amount__c = 100,
      Original_Amount__c = 100,
      Original_Currency__c = 'USD',
      npe03__Date_Established__c = Date.today(),
      npe03__Installment_Period__c = 'Monthly',
      npsp__Status__c = 'Active'
    );

    Test.startTest();
      //TEST INSERT
      insert rd;
      Account res1 = [SELECT Id, Sustainer__c FROM Account WHERE Id = :acct.Id LIMIT 1];
      System.assertEquals(true, res1.Sustainer__c, 'The Account does not have an active Recurring Donation or the checkbox did not get updated.');
      
      //TEST DELETE
      delete rd;
      Account res2 = [SELECT Id, Sustainer__c FROM Account WHERE Id = :acct.Id LIMIT 1];
      System.assertEquals(false, res2.Sustainer__c, 'The Account has an active Recurring Donation or the checkbox did not get updated.');
      
      //TEST UNDELETE
      undelete rd;
      Account res3 = [SELECT Id, Sustainer__c FROM Account WHERE Id = :acct.Id LIMIT 1];
      System.assertEquals(true, res3.Sustainer__c, 'The Account does not have an active Recurring Donation or the checkbox did not get updated.');
      
      //TEST UPDATE
      rd.npsp__Status__c = 'Lapsed';
      update rd;
      Account res4 = [SELECT Id, Sustainer__c FROM Account WHERE Id = :acct.Id LIMIT 1];
      System.assertEquals(false, res4.Sustainer__c, 'The Account has an active Recurring Donation or the checkbox did not get updated.');
    Test.stopTest();
  }
}