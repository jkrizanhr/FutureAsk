public class DocumentGenerationTestHelper {
  public static void createSampleTestData() {
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

    Contact con1 = new Contact();
    con1.FirstName = 'Test';
    con1.LastName = 'Contact1';
    con1.Title = 'Test Title 1';
    con1.Email = 'testcontact1@test.com';
    con1.MailingStreet = '123 Test Street';
    con1.MailingCity = 'Test City';

    Contact con2 = new Contact();
    con2.FirstName = 'Test';
    con2.LastName = 'Contact2';
    con2.Title = 'Test Title 2';
    con2.Email = 'testcontact2@test.com';
    con2.MailingStreet = '321 Test Street';
    con2.MailingCity = 'Test City';

    insert new List<Contact>{ con1, con2 };

    Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, AccountId FROM Contact]);

    npsp__Address__c addr1 = new npsp__Address__c();
    addr1.npsp__Household_Account__c = contactMap.get(con1.Id).AccountId;
    addr1.npsp__MailingStreet__c = con1.MailingStreet;
    addr1.npsp__MailingCity__c = con1.MailingCity;

    npsp__Address__c addr2 = new npsp__Address__c();
    addr2.npsp__Household_Account__c = contactMap.get(con2.Id).AccountId;
    addr2.npsp__MailingStreet__c = con2.MailingStreet;
    addr2.npsp__MailingCity__c = con2.MailingCity;

    insert new List<npsp__Address__c>{ addr1, addr2 };

    Account acc = new Account();
    acc.Name = 'Test Organization';
    acc.BillingStreet = '789 Test Street';
    acc.BillingCity = 'Test City';
    acc.BillingState = 'Pennsylvania';
    acc.BillingCountry = 'United States';
    acc.BillingPostalCode = '12345';
    acc.npe01__One2OneContact__c = con1.Id;
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get('Organization')
      .getRecordTypeId();
    insert acc;

    Campaign cam = new Campaign();
    cam.Name = 'Test Campaign';
    insert cam;

    Cash_Batch__c cashBatch = new Cash_Batch__c();
    cashBatch.Type__c = 'Cash and Checks';
    cashBatch.Opportunity_Type__c = 'Donation';
    cashBatch.Batch_Variation__c = 'A';
    cashBatch.Date__c = Date.today();
    cashBatch.Original_Currency__c = 'USD';
    insert cashBatch;

    Opportunity opp1 = new Opportunity();
    opp1.Name = 'Test Opp1';
    opp1.CloseDate = Date.today();
    opp1.StageName = 'Posted';
    opp1.AccountId = acc.Id;
    opp1.npsp__Primary_Contact__c = con1.Id;
    opp1.Amount = 100;
    opp1.Cash_Batch__c = cashBatch.Id;

    Opportunity opp2 = new Opportunity();
    opp2.Name = 'Test Opp2';
    opp2.CloseDate = Date.today();
    opp2.StageName = 'Posted';
    opp2.AccountId = acc.Id;
    opp2.npsp__Primary_Contact__c = con1.Id;
    opp2.Amount = 200;
    opp2.Cash_Batch__c = cashBatch.Id;

    Opportunity opp3 = new Opportunity();
    opp3.Name = 'Test Opp3';
    opp3.CloseDate = Date.today();
    opp3.StageName = 'Posted';
    opp3.AccountId = acc.Id;
    opp3.npsp__Primary_Contact__c = con2.Id;
    opp3.Amount = 300;
    opp3.Cash_Batch__c = cashBatch.Id;

    Opportunity opp4 = new Opportunity();
    opp4.Name = 'Test Opp4';
    opp4.CloseDate = Date.today().addYears(-2);
    opp4.StageName = 'Posted';
    opp4.AccountId = acc.Id;
    opp4.npsp__Primary_Contact__c = con2.Id;
    opp4.Amount = 400.42;
    opp4.Cash_Batch__c = cashBatch.Id;

    insert new List<Opportunity>{ opp1, opp2, opp3, opp4 };

    npsp__General_Accounting_Unit__c gau1 = new npsp__General_Accounting_Unit__c();
    gau1.Name = 'Test GAU 1';
    gau1.npsp__Active__c = true;
    gau1.Purpose_Code__c = '123';

    npsp__General_Accounting_Unit__c gau2 = new npsp__General_Accounting_Unit__c();
    gau2.Name = 'Test GAU 2';
    gau2.npsp__Active__c = true;
    gau2.Purpose_Code__c = '456';

    insert new List<npsp__General_Accounting_Unit__c>{ gau1, gau2 };

    npsp__Allocation__c alloc1 = new npsp__Allocation__c();
    alloc1.npsp__General_Accounting_Unit__c = gau1.Id;
    alloc1.npsp__Amount__c = 40;
    alloc1.npsp__Opportunity__c = opp1.Id;

    npsp__Allocation__c alloc2 = new npsp__Allocation__c();
    alloc2.npsp__General_Accounting_Unit__c = gau2.Id;
    alloc2.npsp__Amount__c = 60;
    alloc2.npsp__Opportunity__c = opp1.Id;

    npsp__Allocation__c alloc3 = new npsp__Allocation__c();
    alloc3.npsp__General_Accounting_Unit__c = gau2.Id;
    alloc3.npsp__Amount__c = 47.42;
    alloc3.npsp__Opportunity__c = opp4.Id;

    insert new List<npsp__Allocation__c>{ alloc1, alloc2, alloc3 };
  }

  public static void createTemplateData() {
    Document_Template__c template = new Document_Template__c();
    template.Name = 'Test Receipt';
    template.Is_Active__c = true;
    template.Salesforce_Object__c = 'Account';
    template.Email_Template__c = 'Dear {!npe01__One2OneContact__r.SALUTATION} {!npe01__One2OneContact__r.FirstName} {!npe01__One2OneContact__r.LastName}, Attached is your annual receipt.Thank you, Candoris Test';
    template.Delivery_Options__c = 'PDF - Direct Download';
    insert template;

    Document_Template_Query__c primaryQuery = new Document_Template_Query__c();
    primaryQuery.SELECT_Statement__c = 'SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Name, npe01__One2OneContact__r.FirstName, npe01__One2OneContact__r.LastName, npe01__One2OneContact__r.Title';
    primaryQuery.FROM_Object__c = 'Account';
    primaryQuery.Document_Template__c = template.Id;
    primaryQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
      .get('Primary SOQL Query')
      .getRecordTypeId();
    insert primaryQuery;

    // NOTE: Deliberately made the casing of the merge fields inconsistent.
    Document_Template_Query__c aggregateQuery = new Document_Template_Query__c();
    aggregateQuery.SELECT_Statement__c = 'SELECT SUM(Amount) amount, CALENDAR_MONTH(CloseDate) month, AccountId Id';
    aggregateQuery.FROM_Object__c = 'Opportunity';
    aggregateQuery.WHERE_Clause__c =
      'WHERE AccountId IN :' +
      String.escapeSingleQuotes('{!iD}') +
      ' AND CALENDAR_YEAR(CloseDate) = ' +
      String.escapeSingleQuotes('{!closeDATE}');
    aggregateQuery.GROUP_BY_Statement__c = 'GROUP BY CALENDAR_MONTH(CloseDate), AccountId';
    aggregateQuery.ORDER_BY_Statement__c = 'CALENDAR_MONTH(CloseDate)';
    aggregateQuery.Document_Template__c = template.Id;
    aggregateQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
      .get('Aggregate SOQL Query')
      .getRecordTypeId();
    aggregateQuery.Query_Execution_Order__c = 2;
    aggregateQuery.Primary_Query_Correlation__c = 'Id';
    aggregateQuery.Correlating_Query_Field__c = 'Id';
    insert aggregateQuery;

    Document_Template_Question__c question = new Document_Template_Question__c();
    question.Question__c = 'Receipt Year?';
    question.Document_Template__c = template.Id;
    question.Query_Merge_Field__c = '{!closeDatE}';
    question.Question_Order__c = 1;
    question.URL_Parameter__c = 'year';
    insert question;

    Document_Post_Generation_Method__c postMethod = new Document_Post_Generation_Method__c();
    postMethod.Document_Template__c = template.Id;
    postMethod.Object__c = 'Task';
    postMethod.Method_Execution_Order__c = 1;
    postMethod.Delivery_Options__c = 'PDF - Direct Download';
    postMethod.Data_to_Insert_Update__c = '{"WhatId": "{!Id}", "Subject": "Test Receipt Completed", "Status": "Completed", "ActivityDate": "{!TODAY}"}';
    insert postMethod;

    Document_Template_Question_Option__c option = new Document_Template_Question_Option__c();
    option.Default_Option__c = true;
    option.Document_Template__c = template.Id;
    option.Document_Template_Question__c = question.Id;
    option.Option_Value__c = String.valueOf(Date.today().year());
    insert option;
  }
}