@isTest
public class EventServiceTest {
  
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
  static void testEventService() {
    Account acct = new Account(
      Name = 'Test Account',
      Donor_Stage__c = 'Prospect Qualification'
    );
    insert acct;
    
    Event e1 = new Event(
      Subject = 'Test',
      ActivityDateTime = DateTime.now(),
      WhatId = acct.Id,
      DurationInMinutes = 60
    );
    insert e1;
    
    Event res1 = [SELECT Id, Stage_When_Activity_Created__c FROM Event WHERE Id = :e1.Id];
    System.AssertEquals('Prospect Qualification', res1.Stage_When_Activity_Created__c);
    
    Future_Gift__c gift = new Future_Gift__c(
      Account__c = acct.Id, 
      Stage__c = 'Solicitation',
      RecordTypeId = Schema.SObjectType.Future_Gift__c.getRecordTypeInfosByDeveloperName().get('Proposal').getRecordTypeId()
    );
    insert gift;
      
    Event e2 = new Event(
      Subject = 'Test',
      ActivityDateTime = DateTime.now(),
      WhatId = gift.Id,
      DurationInMinutes = 60
    );
    insert e2;
    
    Event res2 = [SELECT Id, Stage_When_Activity_Created__c FROM Event WHERE Id = :e2.Id];
    System.AssertEquals('Solicitation', res2.Stage_When_Activity_Created__c);
  }
}