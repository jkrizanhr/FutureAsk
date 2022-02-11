@isTest
public class TaskServiceTest {

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
  static void testTaskService() {
    Account acct = new Account(
      Name = 'Test Account',
      Donor_Stage__c = 'Solicitation'
    );
    insert acct;
    
    Task t1 = new Task(
      Subject = 'Test',
      ActivityDate = Date.today(),
      WhatId = acct.Id
    );
    insert t1;
    
    Task res1 = [SELECT Id, Stage_When_Activity_Created__c FROM Task WHERE Id = :t1.Id];
    System.AssertEquals('Solicitation', res1.Stage_When_Activity_Created__c);
    
    Future_Gift__c gift = new Future_Gift__c(
      Account__c = acct.Id, 
      Stage__c = 'Commitment Made',
      RecordTypeId = Schema.SObjectType.Future_Gift__c.getRecordTypeInfosByDeveloperName().get('Proposal').getRecordTypeId()
    );
    insert gift;
      
    Task t2 = new Task(
      Subject = 'Test',
      ActivityDate = Date.today(),
      WhatId = gift.Id
    );
    insert t2;
    
    Task res2 = [SELECT Id, Stage_When_Activity_Created__c FROM Task WHERE Id = :t2.Id];
    System.AssertEquals('Commitment Made', res2.Stage_When_Activity_Created__c);
  }
}