@IsTest
private class DocumentGenerationEngine_Test {
  @IsTest
  static void testBehavior() {
    DocumentGenerationTestHelper.createSampleTestData();

    DocGenSettings__c docGenSettings = new DocGenSettings__c();
    docGenSettings.Email_Service__c = 'StandardSalesforce';
    insert docGenSettings;

    Document_Template__c template = new Document_Template__c();
    template.Name = 'Test Receipt';
    template.Is_Active__c = true;
    template.Salesforce_Object__c = 'Opportunity';
    template.Email_Template__c = 'Dear {!Account.npsp__One2OneContact__r.SALUTATION} {!Account.npsp__One2OneContact__r.FirstName} {!Account.npsp__One2OneContact__r.LastName}, Attached is your annual receipt.Thank you, Candoris Test';
    template.Delivery_Options__c = 'CSV - Direct Download';
    template.Email_Recipient_Field_Path__c = 'Account.npe01__One2OneContact__r.Email';
    template.FROM_Address__c = 'test@test.com';
    insert template;

    Document_Template_Query__c primaryQuery = new Document_Template_Query__c();
    primaryQuery.SELECT_Statement__c = 'SELECT Id, Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode';
    primaryQuery.SELECT_Statement__c += ', Account.BillingCountry, Name, Account.npe01__One2OneContact__r.FirstName, Account.npe01__One2OneContact__r.LastName, Account.npe01__One2OneContact__r.Title';
    primaryQuery.SELECT_Statement__c += ', CloseDate, Amount, (SELECT Id, npsp__Amount__c FROM npsp__Allocations__r)';
    primaryQuery.FROM_Object__c = 'Opportunity';
    primaryQuery.Document_Template__c = template.Id;
    primaryQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
      .get('Primary SOQL Query')
      .getRecordTypeId();

    // NOTE: Deliberately made the casing of the merge fields inconsistent.
    Document_Template_Query__c aggregateQuery = new Document_Template_Query__c();
    aggregateQuery.SELECT_Statement__c = 'SELECT SUM(npsp__Amount__c) amountSUM, CALENDAR_MONTH(npsp__Opportunity__r.CloseDate) month, npsp__Opportunity__c Id';
    aggregateQuery.FROM_Object__c = 'npsp__Allocation__c';
    aggregateQuery.WHERE_Clause__c =
      'WHERE npsp__Opportunity__c IN :' +
      String.escapeSingleQuotes('{!iD}') +
      ' AND CALENDAR_YEAR(npsp__Opportunity__r.CloseDate) = ' +
      String.escapeSingleQuotes('{!closeDATE}');
    aggregateQuery.GROUP_BY_Statement__c = 'GROUP BY CALENDAR_MONTH(npsp__Opportunity__r.CloseDate), npsp__Opportunity__c';
    aggregateQuery.ORDER_BY_Statement__c = 'CALENDAR_MONTH(npsp__Opportunity__r.CloseDate)';
    aggregateQuery.Document_Template__c = template.Id;
    aggregateQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
      .get('Aggregate SOQL Query')
      .getRecordTypeId();
    aggregateQuery.Query_Execution_Order__c = 2;
    aggregateQuery.Primary_Query_Correlation__c = 'Id';
    aggregateQuery.Correlating_Query_Field__c = 'Id';

    insert new List<Document_Template_Query__c>{primaryQuery, aggregateQuery};

    template.Primary_Query__c = primaryQuery.Id;
    update template;

    Document_Template_Question__c question1 = new Document_Template_Question__c();
    question1.Question__c = 'Receipt Year?';
    question1.Document_Template__c = template.Id;
    question1.Query_Merge_Field__c = '{!closeDatE}';
    question1.Question_Order__c = 1;
    question1.URL_Parameter__c = 'year';

    Document_Template_Question__c question2 = new Document_Template_Question__c();
    question2.Question__c = 'Major Donors Only?';
    question2.Document_Template__c = template.Id;
    question2.Query_Merge_Override__c = 'Append';
    question2.Document_Template_Query__c = aggregateQuery.Id;
    question2.Question_Order__c = 2;

    Document_Template_Question__c question3 = new Document_Template_Question__c();
    question3.Question__c = 'All Years?';
    question3.Document_Template__c = template.Id;
    question3.Query_Merge_Override__c = 'Replace';
    question3.Document_Template_Query__c = aggregateQuery.Id;
    question3.Question_Order__c = 3;

    insert new List<Document_Template_Question__c>{question1, question2, question3};

    Document_Post_Generation_Method__c postMethod = new Document_Post_Generation_Method__c();
    postMethod.Document_Template__c = template.Id;
    postMethod.Object__c = 'Task';
    postMethod.Method_Execution_Order__c = 1;
    postMethod.Delivery_Options__c = template.Delivery_Options__c;
    postMethod.Data_to_Insert_Update__c = '{"OwnerId": "{!UserInfo.getUserID()}", "Subject": "Test Receipt Emailed", "Status": "Completed", "ActivityDate": "{!TODAY}"}';
    insert postMethod;

    Document_Template_Question_Option__c option1 = new Document_Template_Question_Option__c();
    option1.Default_Option__c = true;
    option1.Document_Template__c = template.Id;
    option1.Document_Template_Question__c = question1.Id;
    option1.Option_Value__c = String.valueOf(Date.today().year());

    Document_Template_Question_Option__c option2 = new Document_Template_Question_Option__c();
    option2.Default_Option__c = true;
    option2.Document_Template__c = template.Id;
    option2.Document_Template_Question__c = question2.Id;
    option2.Option_Value__c = 'npsp__Opportunity__r.Amount > 10000';

    Document_Template_Question_Option__c option3 = new Document_Template_Question_Option__c();
    option3.Default_Option__c = true;
    option3.Document_Template__c = template.Id;
    option3.Document_Template_Question__c = question3.Id;
    option3.Option_Value__c = 'WHERE npsp__Opportunity__c IN :' + String.escapeSingleQuotes('{!iD}');

    insert new List<Document_Template_Question_Option__c>{option1, option2, option3};

    Map<String, String> questionIdAnswerMap = new Map<String, String>();
    questionIdAnswerMap.put(question1.Id, option1.Option_Value__c);
    questionIdAnswerMap.put(question2.Id, option2.Option_Value__c);
    questionIdAnswerMap.put(question3.Id, option3.Option_Value__c);

    List<String> recordIds = new List<String>();
    List<Opportunity> opps = [SELECT Id FROM Opportunity];
    for (Opportunity opp : opps) {
      recordIds.add(opp.Id);
    }

    DocumentGenerationEngine engine = new DocumentGenerationEngine(
      recordIds,
      template.Id,
      template.Delivery_Options__c,
      false,
      false
    );

    Test.startTest();
    engine.initDocumentTemplateData();
    engine.initDocumentQuestionMaps(questionIdAnswerMap);
    engine.initDocumentTemplateQueries();
    engine.initDocumentGenerationHandler();
    String primaryQueryString = engine.buildPrimarySOQLQueryString();
    List<SObject> records = engine.getSObjectRecords(primaryQueryString);
    engine.setRecordList(records);
    engine.handleDocumentGeneration();
    Test.stopTest();

    // Can't assert results because we can only have 1 job enqueued from a unit test
  }

  @IsTest
  static void testPDFEmail() {
    DocumentGenerationTestHelper.createSampleTestData();

    DocGenSettings__c docGenSettings = new DocGenSettings__c();
    docGenSettings.Email_Service__c = 'StandardSalesforce';
    insert docGenSettings;

    Document_Template__c template = new Document_Template__c();
    template.Name = 'Test Receipt';
    template.Is_Active__c = true;
    template.Salesforce_Object__c = 'Opportunity';
    template.Email_Template__c = 'Dear {!Account.npsp__One2OneContact__r.SALUTATION} {!Account.npsp__One2OneContact__r.FirstName} {!Account.npsp__One2OneContact__r.LastName}, Attached is your annual receipt.Thank you, Candoris Test';
    template.Delivery_Options__c = 'PDF - Email';
    template.Email_Recipient_Field_Path__c = 'Account.npe01__One2OneContact__r.Email';
    template.FROM_Address__c = 'test@test.com';
    insert template;

    Document_Template_Query__c primaryQuery = new Document_Template_Query__c();
    primaryQuery.SELECT_Statement__c = 'SELECT Id, Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode';
    primaryQuery.SELECT_Statement__c += ', Account.BillingCountry, Name, Account.npe01__One2OneContact__r.FirstName, Account.npe01__One2OneContact__r.LastName, Account.npe01__One2OneContact__r.Title';
    primaryQuery.SELECT_Statement__c += ', CloseDate, Amount, (SELECT Id, npsp__Amount__c FROM npsp__Allocations__r)';
    primaryQuery.FROM_Object__c = 'Opportunity';
    primaryQuery.Document_Template__c = template.Id;
    primaryQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
      .get('Primary SOQL Query')
      .getRecordTypeId();

    // NOTE: Deliberately made the casing of the merge fields inconsistent.
    Document_Template_Query__c aggregateQuery = new Document_Template_Query__c();
    aggregateQuery.SELECT_Statement__c = 'SELECT SUM(npsp__Amount__c) amountSUM, CALENDAR_MONTH(npsp__Opportunity__r.CloseDate) month, npsp__Opportunity__c Id';
    aggregateQuery.FROM_Object__c = 'npsp__Allocation__c';
    aggregateQuery.WHERE_Clause__c =
      'WHERE npsp__Opportunity__c IN :' +
      String.escapeSingleQuotes('{!iD}') +
      ' AND CALENDAR_YEAR(npsp__Opportunity__r.CloseDate) = ' +
      String.escapeSingleQuotes('{!closeDATE}');
    aggregateQuery.GROUP_BY_Statement__c = 'GROUP BY CALENDAR_MONTH(npsp__Opportunity__r.CloseDate), npsp__Opportunity__c';
    aggregateQuery.ORDER_BY_Statement__c = 'CALENDAR_MONTH(npsp__Opportunity__r.CloseDate)';
    aggregateQuery.Document_Template__c = template.Id;
    aggregateQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
      .get('Aggregate SOQL Query')
      .getRecordTypeId();
    aggregateQuery.Query_Execution_Order__c = 2;
    aggregateQuery.Primary_Query_Correlation__c = 'Id';

    insert new List<Document_Template_Query__c>{primaryQuery, aggregateQuery};

    Document_Template_Question__c question1 = new Document_Template_Question__c();
    question1.Question__c = 'Receipt Year?';
    question1.Document_Template__c = template.Id;
    question1.Query_Merge_Field__c = '{!closeDatE}';
    question1.Question_Order__c = 1;
    question1.URL_Parameter__c = 'year';

    Document_Template_Question__c question2 = new Document_Template_Question__c();
    question2.Question__c = 'Major Donors Only?';
    question2.Document_Template__c = template.Id;
    question2.Query_Merge_Override__c = 'Append';
    question2.Document_Template_Query__c = aggregateQuery.Id;
    question2.Question_Order__c = 2;

    Document_Template_Question__c question3 = new Document_Template_Question__c();
    question3.Question__c = 'All Years?';
    question3.Document_Template__c = template.Id;
    question3.Query_Merge_Override__c = 'Replace';
    question3.Document_Template_Query__c = aggregateQuery.Id;
    question3.Question_Order__c = 3;

    insert new List<Document_Template_Question__c>{question1, question2, question3};

    Document_Post_Generation_Method__c postMethod1 = new Document_Post_Generation_Method__c();
    postMethod1.Document_Template__c = template.Id;
    postMethod1.Object__c = 'Task';
    postMethod1.Method_Execution_Order__c = 1;
    postMethod1.Delivery_Options__c = template.Delivery_Options__c;
    postMethod1.Data_to_Insert_Update__c = '{"OwnerId": "{!UserInfo.getUserID()}", "Subject": "Test Receipt Emailed", "Status": "Completed", "ActivityDate": "{!TODAY}"}';

    Document_Post_Generation_Method__c postMethod2 = new Document_Post_Generation_Method__c();
    postMethod2.Document_Template__c = template.Id;
    postMethod2.Object__c = 'Opportunity';
    postMethod2.Method_Execution_Order__c = 2;
    postMethod2.Delivery_Options__c = template.Delivery_Options__c;
    postMethod2.Data_to_Insert_Update__c = '{"Id": "{!Id}", "npsp__Acknowledgment_Date__c": "{!TODAY}"}';

    insert new List<Document_Post_Generation_Method__c>{postMethod1, postMethod2};

    Document_Template_Question_Option__c option1 = new Document_Template_Question_Option__c();
    option1.Default_Option__c = true;
    option1.Document_Template__c = template.Id;
    option1.Document_Template_Question__c = question1.Id;
    option1.Option_Value__c = String.valueOf(Date.today().year());

    Document_Template_Question_Option__c option2 = new Document_Template_Question_Option__c();
    option2.Default_Option__c = true;
    option2.Document_Template__c = template.Id;
    option2.Document_Template_Question__c = question2.Id;
    option2.Option_Value__c = 'npsp__Opportunity__r.Amount > 10000';

    Document_Template_Question_Option__c option3 = new Document_Template_Question_Option__c();
    option3.Default_Option__c = true;
    option3.Document_Template__c = template.Id;
    option3.Document_Template_Question__c = question3.Id;
    option3.Option_Value__c = 'WHERE npsp__Opportunity__c IN :' + String.escapeSingleQuotes('{!iD}');

    insert new List<Document_Template_Question_Option__c>{option1, option2, option3};

    Map<String, String> questionIdAnswerMap = new Map<String, String>();
    questionIdAnswerMap.put(question1.Id, option1.Option_Value__c);
    questionIdAnswerMap.put(question2.Id, option2.Option_Value__c);
    questionIdAnswerMap.put(question3.Id, option3.Option_Value__c);

    DocumentGenerationEngine engine = new DocumentGenerationEngine(
      null,
      template.Id,
      template.Delivery_Options__c,
      false,
      false
    );

    Test.startTest();
    engine.initDocumentTemplateData();
    engine.initDocumentQuestionMaps(questionIdAnswerMap);
    engine.initDocumentTemplateQueries();
    engine.initDocumentGenerationHandler();
    String primarySOQLQueryString = engine.buildPrimarySOQLQueryString();
    List<SObject> records = engine.getSObjectRecords(primarySOQLQueryString);
    engine.setRecordList(records);
    engine.handleDocumentGeneration();
    Test.stopTest();

    // Can't assert results because we can only have 1 job enqueued from a unit test
  }
}