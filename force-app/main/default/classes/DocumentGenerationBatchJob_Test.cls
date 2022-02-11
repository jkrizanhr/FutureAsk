@IsTest
private class DocumentGenerationBatchJob_Test {
  @IsTest
  static void testDirectDownloadBehavior() {
    DocumentGenerationTestHelper.createSampleTestData();
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
    aggregateQuery.SELECT_Statement__c = 'SELECT SUM(Amount) amount, CALENDAR_MONTH(CloseDate) month, AccountId iD';
    aggregateQuery.FROM_Object__c = 'Opportunity';
    //        aggregateQuery.WHERE_Clause__c = 'WHERE AccountId IN :' + String.escapeSingleQuotes('{!id}') + ' AND CALENDAR_YEAR(CloseDate) = ' + String.escapeSingleQuotes('{!closeDATE}');
    aggregateQuery.WHERE_Clause__c = 'WHERE AccountId IN :' + String.escapeSingleQuotes('{!id}');
    aggregateQuery.GROUP_BY_Statement__c = 'GROUP BY AccountId, CALENDAR_MONTH(CloseDate)';
    aggregateQuery.ORDER_BY_Statement__c = 'AccountId, CALENDAR_MONTH(CloseDate)';
    aggregateQuery.Document_Template__c = template.Id;
    aggregateQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
      .get('Aggregate SOQL Query')
      .getRecordTypeId();
    aggregateQuery.Query_Execution_Order__c = 2;
    aggregateQuery.Primary_Query_Correlation__c = 'Id';
    insert aggregateQuery;

    List<DocumentTemplateColumnConfig> docColumnHeaders = new List<DocumentTemplateColumnConfig>();

    DocumentTemplateColumnConfig c0 = new DocumentTemplateColumnConfig();
    c0.index = 0;
    c0.queryId = primaryQuery.Id;
    c0.key = 'Name';
    c0.field = 'Name';
    c0.apiName = 'Name';
    c0.label = 'Name';
    c0.formatting = '';
    c0.groupingValue = '';
    c0.altValue = '';
    docColumnHeaders.add(c0);

    DocumentTemplateColumnConfig c1 = new DocumentTemplateColumnConfig();
    c1.index = 1;
    c1.queryId = primaryQuery.Id;
    c1.key = 'BillingStreet';
    c1.field = 'BillingStreet';
    c1.apiName = 'BillingStreet';
    c1.label = 'Billing Street';
    c1.formatting = '';
    c1.groupingValue = '';
    c1.altValue = '';
    docColumnHeaders.add(c1);

    DocumentTemplateColumnConfig c2 = new DocumentTemplateColumnConfig();
    c2.index = 2;
    c2.queryId = primaryQuery.Id;
    c2.key = 'BillingCity';
    c2.field = 'BillingCity';
    c2.apiName = 'BillingCity';
    c2.label = 'Billing City';
    c2.formatting = '';
    c2.groupingValue = '';
    c2.altValue = '';
    docColumnHeaders.add(c2);

    DocumentTemplateColumnConfig c3 = new DocumentTemplateColumnConfig();
    c3.index = 3;
    c3.queryId = primaryQuery.Id;
    c3.key = 'BillingState';
    c3.field = 'BillingState';
    c3.apiName = 'BillingState';
    c3.label = 'Billing State';
    c3.formatting = '';
    c3.groupingValue = '';
    c3.altValue = '';
    docColumnHeaders.add(c3);

    template.CSV_Columns__c = JSON.serialize(docColumnHeaders);
    update template;

    Document_Template_Question__c question = new Document_Template_Question__c();
    question.Question__c = 'Receipt This Year?';
    question.Document_Template__c = template.Id;
    question.Document_Template_Query__c = aggregateQuery.Id;
    question.Query_Merge_Override__c = 'Append';
    question.Question_Order__c = 1;
    question.URL_Parameter__c = 'year';
    insert question;

    Document_Template_Question_Option__c option = new Document_Template_Question_Option__c();
    option.Default_Option__c = true;
    option.Document_Template__c = template.Id;
    option.Document_Template_Question__c = question.Id;
    option.Name = 'Yes';
    option.Option_Value__c = 'CloseDate = THIS_YEAR';
    insert option;

    Document_Post_Generation_Method__c postMethod = new Document_Post_Generation_Method__c();
    postMethod.Document_Template__c = template.Id;
    postMethod.Object__c = 'Task';
    postMethod.Method_Execution_Order__c = 1;
    postMethod.Delivery_Options__c = 'CSV - Direct Download';
    postMethod.Data_to_Insert_Update__c = '{"WhatId": "{!Id}", "Subject": "Test Receipt Complete", "Status": "Completed", "ActivityDate": "{!TODAY}"}';
    insert postMethod;

    Map<String, String> questionAnswerMap = new Map<String, String>();
    questionAnswerMap.put(question.Id, option.Option_Value__c);

    Test.startTest();
    Database.executeBatch(
      new DocumentGenerationBatchJob(
        template.Id,
        template.Delivery_Options__c,
        // DocumentGenerationTestHelper.stationVar,
        false,
        questionAnswerMap
      )
    );
    Test.stopTest();

    System.assertNotEquals(0, [SELECT Id FROM ContentVersion].size());
  }

  @IsTest
  static void testEmailCSVBehavior() {
    DocumentGenerationTestHelper.createSampleTestData();
    DocGenSettings__c docGenSettings = new DocGenSettings__c();
    docGenSettings.Email_Service__c = 'StandardSalesforce';
    insert docGenSettings;

    Document_Template__c template = new Document_Template__c();
    template.Name = 'Test Receipt';
    template.Is_Active__c = true;
    template.Salesforce_Object__c = 'Account';
    template.Email_Template__c = 'Dear {!npe01__One2OneContact__r.SALUTATION} {!npe01__One2OneContact__r.FirstName} {!npe01__One2OneContact__r.LastName}, Attached is your annual receipt.Thank you, Candoris Test';
    template.CSV_Columns__c = 'Name, Opportunities[0].month, Opportunities[0].amount, Opportunities[1].month, Opportunities[1].amount, Opportunities[2].month, Opportunities[2].amount';
    template.Delivery_Options__c = 'CSV - Email';
    template.FROM_Address__c = 'test@test.com';
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
    aggregateQuery.SELECT_Statement__c = 'SELECT SUM(Amount) amount, CALENDAR_MONTH(CloseDate) month, AccountId iD';
    aggregateQuery.FROM_Object__c = 'Opportunity';
    aggregateQuery.WHERE_Clause__c =
      'WHERE AccountId IN :' +
      String.escapeSingleQuotes('{!id}') +
      ' AND CALENDAR_YEAR(CloseDate) = ' +
      String.escapeSingleQuotes('{!closeDATE}');
    aggregateQuery.GROUP_BY_Statement__c = 'GROUP BY AccountId, CALENDAR_MONTH(CloseDate)';
    aggregateQuery.ORDER_BY_Statement__c = 'AccountId, CALENDAR_MONTH(CloseDate)';
    aggregateQuery.Document_Template__c = template.Id;
    aggregateQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
      .get('Aggregate SOQL Query')
      .getRecordTypeId();
    aggregateQuery.Query_Execution_Order__c = 2;
    insert aggregateQuery;

    Document_Template_Question__c question = new Document_Template_Question__c();
    question.Question__c = 'Receipt Year?';
    question.Document_Template__c = template.Id;
    question.Query_Merge_Field__c = '{!CloseDate}';
    question.Question_Order__c = 1;
    question.URL_Parameter__c = 'year';
    insert question;

    Document_Post_Generation_Method__c postMethod = new Document_Post_Generation_Method__c();
    postMethod.Document_Template__c = template.Id;
    postMethod.Object__c = 'Task';
    postMethod.Method_Execution_Order__c = 1;
    postMethod.Delivery_Options__c = 'CSV - Email;CSV - Direct Download';
    postMethod.Data_to_Insert_Update__c = '{"WhatId": "{!Id}", "Subject": "Test Receipt Emailed", "Status": "Completed", "ActivityDate": "{!TODAY}"}';
    insert postMethod;

    Document_Post_Generation_Method__c postMethod2 = new Document_Post_Generation_Method__c();
    postMethod2.Document_Template__c = template.Id;
    postMethod2.Object__c = 'Account';
    postMethod2.Method_Execution_Order__c = 2;
    postMethod2.Delivery_Options__c = 'CSV - Email;CSV - Direct Download';
    postMethod2.Data_to_Insert_Update__c = '{"Id": "{!Id}", "Name": "Hello"}';
    insert postMethod2;

    Map<String, String> questionAnswerMap = new Map<String, String>();
    questionAnswerMap.put(question.Id, String.valueOf(Date.today().year()));

    Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

    User testUser = new User(
      Alias = 'sysAdmin',
      Email = 'sysAdminUser@example.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = profile.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      Username = 'sysAdminUser@example.com'
    );
    insert testUser;

    Test.startTest();
    System.runAs(testUser) {
      Database.executeBatch(new DocumentGenerationBatchJob(template.Id, 'CSV - Email', false, questionAnswerMap));
    }
    Test.stopTest();
    // Can't assert results because we can only have 1 job enqueued from a unit test
  }
}