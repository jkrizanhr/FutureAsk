@IsTest
private class DocumentGeneratorCompController_Test {
  @IsTest
  static void testQueries() {
    Document_Template__c template = new Document_Template__c();
    template.Name = 'Test Receipt';
    template.Is_Active__c = true;
    template.Salesforce_Object__c = 'Account';
    template.Email_Template__c = 'Dear {!npe01__One2OneContact__r.SALUTATION} {!npe01__One2OneContact__r.FirstName} {!npe01__One2OneContact__r.LastName}, Attached is your annual receipt.Thank you, Candoris Test';
    template.Delivery_Options__c = 'PDF - Direct Download';
    template.Available_For__c = 'Both';
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
    insert aggregateQuery;

    Document_Template_Question__c question = new Document_Template_Question__c();
    question.Question__c = 'Receipt Year?';
    question.Document_Template__c = template.Id;
    question.Query_Merge_Field__c = '{!closeDatE}';
    question.Question_Order__c = 1;
    question.URL_Parameter__c = 'year';
    question.Question_Field_Type__c = 'Text';
    question.Available_for__c = 'Both';
    insert question;

    Document_Post_Generation_Method__c postMethod = new Document_Post_Generation_Method__c();
    postMethod.Document_Template__c = template.Id;
    postMethod.Object__c = 'Task';
    postMethod.Method_Execution_Order__c = 1;
    postMethod.Delivery_Options__c = 'PDF - Direct Download';
    postMethod.Data_to_Insert_Update__c = '{"OwnerId": "{!UserInfo.getUserID()}", "Subject": "Test Receipt Emailed", "Status": "Completed", "ActivityDate": "{!TODAY}"}';
    insert postMethod;

    Document_Template_Question_Option__c option = new Document_Template_Question_Option__c();
    option.Default_Option__c = true;
    option.Document_Template__c = template.Id;
    option.Document_Template_Question__c = question.Id;
    option.Option_Value__c = String.valueOf(Date.today().year());
    insert option;

    Test.startTest();

    List<Document_Template__c> result1 = DocumentGeneratorComponentController.fetchDocumentTemplates(
      'Account',
      false
    );

    List<Document_Template_Query__c> result2 = DocumentGeneratorComponentController.fetchTemplateQueries(
      template.Id
    );

    List<Document_Template_Question__c> result3 = DocumentGeneratorComponentController.fetchQuestions(
      template.Id,
      true
    );

    List<Document_Template_Question_Option__c> result4 = DocumentGeneratorComponentController.fetchQuestionOptions(
      template.Id,
      true
    );
    Test.stopTest();

    System.assertEquals(1, result1.size());
    System.assertEquals(2, result2.size());
    System.assertEquals(1, result3.size());
    System.assertEquals(1, result4.size());
  }

  @IsTest
  static void testValidatePrimaryQuery() {
    Account a = new Account();
    a.Name = 'Test Organization';
    insert a;

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
    insert aggregateQuery;

    Document_Template_Question__c question = new Document_Template_Question__c();
    question.Question__c = 'Receipt Year?';
    question.Document_Template__c = template.Id;
    question.Query_Merge_Field__c = '{!closeDatE}';
    question.Question_Order__c = 1;
    question.URL_Parameter__c = 'year';
    question.Question_Field_Type__c = 'Text';
    question.Available_for__c = 'Both';
    insert question;

    Document_Post_Generation_Method__c postMethod = new Document_Post_Generation_Method__c();
    postMethod.Document_Template__c = template.Id;
    postMethod.Object__c = 'Task';
    postMethod.Method_Execution_Order__c = 1;
    postMethod.Delivery_Options__c = 'PDF - Direct Download';
    postMethod.Data_to_Insert_Update__c = '{"OwnerId": "{!UserInfo.getUserID()}", "Subject": "Test Receipt Emailed", "Status": "Completed", "ActivityDate": "{!TODAY}"}';
    insert postMethod;

    Document_Template_Question_Option__c option = new Document_Template_Question_Option__c();
    option.Default_Option__c = true;
    option.Document_Template__c = template.Id;
    option.Document_Template_Question__c = question.Id;
    option.Option_Value__c = String.valueOf(Date.today().year());
    insert option;

    Map<String, String> questionAnswerMap = new Map<String, String>();
    questionAnswerMap.put(question.Id, String.valueOf(Date.today().year()));

    DocumentGeneratorModel.Params paramModel = new DocumentGeneratorModel.Params();
    paramModel.isTestMode = false;
    paramModel.deliveryOption = 'PDF - Direct Download';
    paramModel.questionAnswerMapJSON = JSON.serialize(questionAnswerMap);
    paramModel.templateId = template.Id;

    String paramJSON = JSON.serialize(paramModel);

    Test.startTest();
    String resultString = DocumentGeneratorComponentController.validatePrimaryQuery(paramJSON);
    Test.stopTest();

    DocumentGeneratorModel.PrimaryQueryValidator result = (DocumentGeneratorModel.PrimaryQueryValidator) JSON.deserialize(
      resultString,
      DocumentGeneratorModel.PrimaryQueryValidator.class
    );
    System.assertEquals(true, result.isValid);
  }

  @IsTest
  static void testInitSingleDocumentEmail() {
    DocumentGenerationTestHelper.createSampleTestData();

    DocGenSettings__c docGenSettings = new DocGenSettings__c();
    docGenSettings.Email_Service__c = 'StandardSalesforce';
    insert docGenSettings;

    Document_Template__c template = new Document_Template__c();
    template.Name = 'Test Receipt';
    template.Is_Active__c = true;
    template.Salesforce_Object__c = 'Account';
    template.Email_Template__c = 'Dear {!npe01__One2OneContact__r.SALUTATION} {!npe01__One2OneContact__r.FirstName} {!npe01__One2OneContact__r.LastName}, Attached is your annual receipt.Thank you, Candoris Test';
    template.Delivery_Options__c = 'PDF - Email';
    template.Attach_PDF_to_Primary_Record__c = true;
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
    insert aggregateQuery;

    Document_Template_Question__c question = new Document_Template_Question__c();
    question.Question__c = 'Receipt Year?';
    question.Document_Template__c = template.Id;
    question.Query_Merge_Field__c = '{!closeDatE}';
    question.Question_Order__c = 1;
    question.URL_Parameter__c = 'year';
    question.Question_Field_Type__c = 'Text';
    question.Available_for__c = 'Both';
    insert question;

    Document_Post_Generation_Method__c postMethod = new Document_Post_Generation_Method__c();
    postMethod.Document_Template__c = template.Id;
    postMethod.Object__c = 'Task';
    postMethod.Method_Execution_Order__c = 1;
    postMethod.Delivery_Options__c = 'PDF - Email';
    postMethod.Data_to_Insert_Update__c = '{"OwnerId": "{!UserInfo.getUserID()}", "Subject": "Test Receipt Emailed", "Status": "Completed", "ActivityDate": "{!TODAY}"}';
    insert postMethod;

    Document_Template_Question_Option__c option = new Document_Template_Question_Option__c();
    option.Default_Option__c = true;
    option.Document_Template__c = template.Id;
    option.Document_Template_Question__c = question.Id;
    option.Option_Value__c = String.valueOf(Date.today().year());
    insert option;

    List<Account> accList = [SELECT Id FROM Account WHERE Name = 'Test Organization'];

    Map<String, String> questionIdAnswerMap = new Map<String, String>();
    questionIdAnswerMap.put(question.Id, String.valueOf(Date.today().year()));

    DocumentGeneratorModel.Params paramModel = new DocumentGeneratorModel.Params();
    paramModel.templateId = template.Id;
    paramModel.recordId = accList[0].Id;
    paramModel.isTestMode = false;
    paramModel.questionAnswerMapJSON = JSON.serialize(questionIdAnswerMap);
    paramModel.deliveryOption = template.Delivery_Options__c;

    Test.startTest();
    DocumentGeneratorComponentController.initSingleDocumentEmail(JSON.serialize(paramModel));
    Test.stopTest();

    // NOTE: This test is for code coverage
  }

  @IsTest
  static void testProcessMassDocumentsAndFetchBatchProgress() {
    DocumentGenerationTestHelper.createSampleTestData();

    DocGenSettings__c docGenSettings = new DocGenSettings__c();
    docGenSettings.Email_Service__c = 'StandardSalesforce';
    insert docGenSettings;

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
    aggregateQuery.WHERE_Clause__c = 'WHERE AccountId IN :' + String.escapeSingleQuotes('{!iD}');
    aggregateQuery.GROUP_BY_Statement__c = 'GROUP BY CALENDAR_MONTH(CloseDate), AccountId';
    aggregateQuery.ORDER_BY_Statement__c = 'CALENDAR_MONTH(CloseDate)';
    aggregateQuery.Document_Template__c = template.Id;
    aggregateQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
      .get('Aggregate SOQL Query')
      .getRecordTypeId();
    aggregateQuery.Query_Execution_Order__c = 2;
    aggregateQuery.Primary_Query_Correlation__c = 'Id';
    insert aggregateQuery;

    Document_Template_Question__c question = new Document_Template_Question__c();
    question.Question__c = 'This Year?';
    question.Document_Template__c = template.Id;
    question.Question_Order__c = 1;
    question.URL_Parameter__c = 'year';
    question.Available_for__c = 'Both';
    question.Query_Merge_Override__c = 'Append';
    insert question;

    Document_Post_Generation_Method__c postMethod = new Document_Post_Generation_Method__c();
    postMethod.Document_Template__c = template.Id;
    postMethod.Object__c = 'Task';
    postMethod.Method_Execution_Order__c = 1;
    postMethod.Delivery_Options__c = 'PDF - Email';
    postMethod.Data_to_Insert_Update__c = '{"WhatId": "{!Id}", "Subject": "Test Receipt Completed", "Status": "Completed", "ActivityDate": "{!TODAY}"}';
    insert postMethod;

    Document_Template_Question_Option__c option = new Document_Template_Question_Option__c();
    option.Default_Option__c = true;
    option.Document_Template__c = template.Id;
    option.Document_Template_Question__c = question.Id;
    option.Name = 'Yes';
    option.Option_Value__c = 'CloseDate = THIS YEAR';
    insert option;

    Map<String, String> questionIdAnswerMap = new Map<String, String>();
    questionIdAnswerMap.put(question.Id, option.Option_Value__c);

    DocumentGeneratorModel.Params paramModel = new DocumentGeneratorModel.Params();
    paramModel.templateId = template.Id;
    paramModel.deliveryOption = 'PDF - Email';
    paramModel.isTestMode = false;
    paramModel.questionAnswerMapJSON = JSON.serialize(questionIdAnswerMap);

    Test.startTest();
    DocumentGeneratorComponentController.processMassDocuments(JSON.serialize(paramModel));
    // AsyncApexJob res = DocumentGeneratorComponentController.fetchBatchProgress(jobId);
    Test.stopTest();

    // System.assertNotEquals(null, jobId);
    // System.assertNotEquals(null, res);
  }

  @IsTest
  static void testAbortBatchJob() {
    DocumentGenerationTestHelper.createSampleTestData();

    DocGenSettings__c docGenSettings = new DocGenSettings__c();
    docGenSettings.Email_Service__c = 'StandardSalesforce';
    insert docGenSettings;

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
    insert aggregateQuery;

    Document_Template_Question__c question = new Document_Template_Question__c();
    question.Question__c = 'Receipt Year?';
    question.Document_Template__c = template.Id;
    question.Query_Merge_Field__c = '{!closeDatE}';
    question.Question_Order__c = 1;
    question.URL_Parameter__c = 'year';
    question.Question_Field_Type__c = 'Text';
    question.Available_for__c = 'Both';
    insert question;

    Document_Post_Generation_Method__c postMethod = new Document_Post_Generation_Method__c();
    postMethod.Document_Template__c = template.Id;
    postMethod.Object__c = 'Task';
    postMethod.Method_Execution_Order__c = 1;
    postMethod.Delivery_Options__c = 'PDF - Direct Download';
    postMethod.Data_to_Insert_Update__c = '{"OwnerId": "{!UserInfo.getUserID()}", "Subject": "Test Receipt Emailed", "Status": "Completed", "ActivityDate": "{!TODAY}"}';
    insert postMethod;

    Document_Template_Question_Option__c option = new Document_Template_Question_Option__c();
    option.Default_Option__c = true;
    option.Document_Template__c = template.Id;
    option.Document_Template_Question__c = question.Id;
    option.Option_Value__c = String.valueOf(Date.today().year());
    insert option;

    Map<String, String> questionIdAnswerMap = new Map<String, String>();
    questionIdAnswerMap.put(question.Id, String.valueOf(Date.today().year()));

    Test.startTest();
    String jobId = Database.executeBatch(
      new DocumentGenerationBatchJob(template.Id, 'PDF - Email', false, questionIdAnswerMap),
      200
    );
    // Boolean result = DocumentGeneratorComponentController.abortBatchJob(jobId);
    Test.stopTest();

    // System.assertEquals(true, result);
  }

  @IsTest
  static void testFetchContentVersionId() {
    ContentVersion cv = new ContentVersion();
    cv.Title = 'Test File';
    cv.VersionData = Blob.valueOf('Here is some test data.');
    cv.PathOnClient = cv.Title;
    cv.Apex_Batch_Job_Id__c = 'some batch Id';
    insert cv;

    Test.startTest();
    // List<ContentVersion> results = DocumentGeneratorComponentController.fetchContentVersionId(cv.Apex_Batch_Job_Id__c);
    Test.stopTest();

    // System.assertEquals(cv.Id, results[0].Id);
  }
}