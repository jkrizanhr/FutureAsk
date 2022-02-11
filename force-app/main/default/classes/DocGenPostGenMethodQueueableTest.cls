@IsTest
private class DocGenPostGenMethodQueueableTest {
  @TestSetup 
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
  static void testInsert() {
    Account acc = new Account();
    acc.Name = 'Test Organization';
    acc.BillingStreet = '123 Test Street';
    acc.BillingCity = 'NY';
    acc.BillingState = 'NY';
    acc.BillingCountry = 'United States';
    acc.BillingPostalCode = '12345';
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
    insert acc;

    DocGenSettings__c docGenSettings = new DocGenSettings__c();
    docGenSettings.Email_Service__c = 'StandardSalesforce';
    insert docGenSettings;

    Document_Template__c template = new Document_Template__c();
    template.Name = 'Test Receipt';
    template.Is_Active__c = true;
    template.Salesforce_Object__c = 'Account';
    template.Email_Template__c = 'Dear {!npe01__One2OneContact__r.SALUTATION} {!npe01__One2OneContact__r.FirstName} {!npe01__One2OneContact__r.LastName}, Attached is your annual receipt.Thank you, Candoris Test';
    template.Delivery_Options__c = 'CSV - Direct Download';
    template.FROM_Address__c = 'test@test.com';
    insert template;

    Map<String, List<SObject>> sObjectInsertMap = new Map<String, List<SObject>>();
    Task task = new Task();
    task.WhatId = acc.Id;
    task.Subject = 'Test Receipt Complete';
    task.Status = 'Completed';
    task.ActivityDate = Date.today();

    sObjectInsertMap.put('Task', new List<SObject>{task});

    Map<String, List<SObject>> sObjectUpdateMap = new Map<String, List<SObject>>();

    Test.startTest();
    System.enqueueJob(new DocGenPostGenMethodQueueable(template.Id, sObjectInsertMap, sObjectUpdateMap));
    Test.stopTest();

    System.assertEquals(1, [SELECT Id FROM Task].size());
  }

  @IsTest
  static void testUpdate() {
    Account acc = new Account();
    acc.Name = 'Test Organization';
    acc.BillingStreet = '123 Test Street';
    acc.BillingCity = 'NY';
    acc.BillingState = 'NY';
    acc.BillingCountry = 'United States';
    acc.BillingPostalCode = '12345';
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
    insert acc;

    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opp1';
    opp.CloseDate = Date.today();
    opp.StageName = 'Committed';
    opp.AccountId = acc.Id;
    opp.Amount = 100;
    opp.Payment_Method__c = 'Check';
    insert opp;

    DocGenSettings__c docGenSettings = new DocGenSettings__c();
    docGenSettings.Email_Service__c = 'StandardSalesforce';
    insert docGenSettings;

    Document_Template__c template = new Document_Template__c();
    template.Name = 'Test Receipt';
    template.Is_Active__c = true;
    template.Salesforce_Object__c = 'Account';
    template.Email_Template__c = 'Dear {!npe01__One2OneContact__r.SALUTATION} {!npe01__One2OneContact__r.FirstName} {!npe01__One2OneContact__r.LastName}, Attached is your annual receipt.Thank you, Candoris Test';
    template.Delivery_Options__c = 'CSV - Direct Download';
    template.FROM_Address__c = 'test@test.com';
    insert template;

    Map<String, List<SObject>> sObjectInsertMap = new Map<String, List<SObject>>();
    Map<String, List<SObject>> sObjectUpdateMap = new Map<String, List<SObject>>();
    Opportunity oppData = new Opportunity();
    oppData.Id = opp.Id;
    oppData.npsp__Acknowledgment_Date__c = Date.today();
    sObjectUpdateMap.put('Opportunity', new List<SObject>{oppData});

    Test.startTest();
    System.enqueueJob(new DocGenPostGenMethodQueueable(template.Id, sObjectInsertMap, sObjectUpdateMap));
    Test.stopTest();

    System.assertEquals(
      Date.today(),
      [SELECT npsp__Acknowledgment_Date__c FROM Opportunity]
      .npsp__Acknowledgment_Date__c
    );
  }

  @IsTest
  static void testHandleError() {
    Account acc = new Account();
    acc.Name = 'Test Organization';
    acc.BillingStreet = '123 Test Street';
    acc.BillingCity = 'NY';
    acc.BillingState = 'NY';
    acc.BillingCountry = 'United States';
    acc.BillingPostalCode = '12345';
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
    insert acc;

    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opp1';
    opp.CloseDate = Date.today();
    opp.StageName = 'Committed';
    opp.AccountId = acc.Id;
    opp.Amount = 100;
    opp.Payment_Method__c = 'Check';
    insert opp;

    DocGenSettings__c docGenSettings = new DocGenSettings__c();
    docGenSettings.Email_Service__c = 'StandardSalesforce';
    insert docGenSettings;

    Document_Template__c template = new Document_Template__c();
    template.Name = 'Test Receipt';
    template.Is_Active__c = true;
    template.Salesforce_Object__c = 'Account';
    template.Email_Template__c = 'Dear {!npe01__One2OneContact__r.SALUTATION} {!npe01__One2OneContact__r.FirstName} {!npe01__One2OneContact__r.LastName}, Attached is your annual receipt.Thank you, Candoris Test';
    template.Delivery_Options__c = 'CSV - Direct Download';
    template.FROM_Address__c = 'test@test.com';
    insert template;

    Map<String, List<SObject>> sObjectInsertMap = new Map<String, List<SObject>>();
    Map<String, List<SObject>> sObjectUpdateMap = new Map<String, List<SObject>>();
    Opportunity oppData = new Opportunity();
    oppData.Id = null;
    oppData.npsp__Acknowledgment_Date__c = Date.today();
    sObjectUpdateMap.put('Opportunity', new List<SObject>{oppData});

    Test.startTest();
    System.enqueueJob(new DocGenPostGenMethodQueueable(template.Id, sObjectInsertMap, sObjectUpdateMap));
    Test.stopTest();

    System.assertEquals(null, [SELECT npsp__Acknowledgment_Date__c FROM Opportunity].npsp__Acknowledgment_Date__c);
  }
}