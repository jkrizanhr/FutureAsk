@IsTest
private class DocumentGenerationCSVHandler_Test {
  @IsTest
  static void testCSVEmail() {
    DocumentGenerationTestHelper.createSampleTestData();
    DocGenSettings__c docGenSettings = new DocGenSettings__c();
    docGenSettings.Email_Service__c = 'StandardSalesforce';
    insert docGenSettings;

    Document_Template__c template = new Document_Template__c();
    template.Name = 'Test Receipt';
    template.Is_Active__c = true;
    template.Salesforce_Object__c = 'Opportunity';
    template.Email_Template__c = 'Dear {!Account.npsp__One2OneContact__r.SALUTATION} {!Account.npsp__One2OneContact__r.FirstName} {!Account.npsp__One2OneContact__r.LastName}, Attached is your annual receipt.Thank you, Candoris Test';
    template.Delivery_Options__c = 'CSV - Email';
    template.FROM_Address__c = 'test@test.com';
    insert template;

    Document_Template_Query__c primaryQuery = new Document_Template_Query__c();
    primaryQuery.SELECT_Statement__c = 'SELECT Id, Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode';
    primaryQuery.SELECT_Statement__c += ', Account.BillingCountry, Name, Account.npe01__One2OneContact__r.FirstName, Account.npe01__One2OneContact__r.LastName, Account.npe01__One2OneContact__r.Title';
    primaryQuery.SELECT_Statement__c += ', CloseDate, Amount, SELECT(Id, npsp__Amount__c FROM npsp__Allocations__r)';
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

    Document_Template_Question__c question1 = new Document_Template_Question__c();
    question1.Question__c = 'Receipt Year?';
    question1.Document_Template__c = template.Id;
    question1.Query_Merge_Field__c = '{!closeDatE}';
    question1.Question_Order__c = 1;
    question1.URL_Parameter__c = 'year';
    question1.Available_for__c = 'Both';
    question1.Question_Field_Type__c = 'Text';

    Document_Template_Question__c question2 = new Document_Template_Question__c();
    question2.Question__c = 'Major Donors Only?';
    question2.Document_Template__c = template.Id;
    question2.Query_Merge_Override__c = 'Append';
    question2.Document_Template_Query__c = aggregateQuery.Id;
    question2.Question_Order__c = 2;
    question2.Available_for__c = 'Both';
    question2.Question_Field_Type__c = 'Text';

    Document_Template_Question__c question3 = new Document_Template_Question__c();
    question3.Question__c = 'All Years?';
    question3.Document_Template__c = template.Id;
    question3.Query_Merge_Override__c = 'Replace';
    question3.Document_Template_Query__c = aggregateQuery.Id;
    question3.Question_Order__c = 3;
    question3.Available_for__c = 'Both';
    question3.Question_Field_Type__c = 'Text';

    insert new List<Document_Template_Question__c>{question1, question2, question3};

    Document_Post_Generation_Method__c postMethod = new Document_Post_Generation_Method__c();
    postMethod.Document_Template__c = template.Id;
    postMethod.Object__c = 'Task';
    postMethod.Method_Execution_Order__c = 1;
    postMethod.Delivery_Options__c = 'CSV - Email';
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
    option3.Document_Template_Question__c = question2.Id;
    option3.Option_Value__c = 'WHERE npsp__Opportunity__c IN :' + String.escapeSingleQuotes('{!iD}');

    insert new List<Document_Template_Question_Option__c>{option1, option2, option3};

    List<Opportunity> oppList = [
      SELECT
        Id,
        AccountId,
        Name,
        (
          SELECT Id, npsp__Amount__c, npsp__Opportunity__c, npsp__General_Accounting_Unit__r.Name
          FROM npsp__Allocations__r
        )
      FROM Opportunity
    ];

    Map<Id, List<AggregateResult>> aggregateResultMap = new Map<Id, List<AggregateResult>>();

    List<AggregateResult> aggregateResults = [
      SELECT SUM(npsp__Amount__c) amount, npsp__Opportunity__c Id
      FROM npsp__Allocation__c
      GROUP BY npsp__Opportunity__c
    ];

    aggregateResultMap.put(aggregateQuery.Id, aggregateResults);

    // DocumentGeneratorModel docGenModel = new DocumentGeneratorModel('CSV - Email', DocumentGenerationTestHelper.stationVar, template.Id, false, false);
    DocumentGeneratorModel docGenModel = new DocumentGeneratorModel('CSV - Email', template.Id, false, false);
    docGenModel.docTemp = template;
    docGenModel.docTempQueryList = [
      SELECT
        Document_Template__c,
        FROM_Object__c,
        GROUP_BY_Statement__c,
        HAVING_Statement__c,
        Id,
        LIMIT__c,
        Name,
        ORDER_BY_Statement__c,
        Primary_Query_Correlation__c,
        Query_Execution_Order__c,
        RecordTypeId,
        RecordType.Name,
        SELECT_Statement__c,
        SOQL_Query__c,
        WHERE_Clause__c
      FROM Document_Template_Query__c
    ];
    docGenModel.docTempQuestionList.add(question1);
    docGenModel.docTempQuestionList.add(question2);
    docGenModel.docTempQuestionList.add(question3);
    docGenModel.docTempOptionList.add(option1);
    docGenModel.docTempOptionList.add(option2);
    docGenModel.docTempOptionList.add(option3);
    docGenModel.docTempPrimaryQuery = primaryQuery;
    docGenModel.docTempAggregateQueryList.add(aggregateQuery);
    docGenModel.questionIdAnswerMap.put(question1.Id, option1.Option_Value__c);
    docGenModel.questionIdAnswerMap.put(question2.Id, option2.Option_Value__c);
    docGenModel.questionIdAnswerMap.put(question3.Id, option3.Option_Value__c);
    docGenModel.mergeFieldAnswerMap.put(
      question1.Query_Merge_Field__c.toLowerCase(),
      String.valueOf(Date.today().year())
    );

    DocumentGenerationCSVHandler csvHandler = new DocumentGenerationCSVHandler();

    Test.startTest();
    csvHandler.init(docGenModel);
    Boolean result1 = csvHandler.handleDocumentGeneration(oppList);
    Boolean result2 = csvHandler.completeDocumentGeneration();
    Test.stopTest();

    System.assertEquals(true, result1);
    System.assertEquals(true, result2);
  }

  @IsTest
  static void testCSVDirectDownload() {
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
    template.CSV_Columns__c = 'Name, npsp__Allocations__r[0].npsp__Amount__c, npsp__Allocations__r[0].npsp__General_Accounting_Unit__r.Name, npsp__Allocations__r[1].npsp__Amount__c, npsp__Allocations__r[1].npsp__General_Accounting_Unit__r.Name, amountSum';
    template.FROM_Address__c = 'test@test.com';
    template.Filename__c = 'Test Receipt';
    insert template;

    Document_Template_Query__c primaryQuery = new Document_Template_Query__c();
    primaryQuery.SELECT_Statement__c = 'SELECT Id, Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode';
    primaryQuery.SELECT_Statement__c += ', Account.BillingCountry, Name, Account.npe01__One2OneContact__r.FirstName, Account.npe01__One2OneContact__r.LastName, Account.npe01__One2OneContact__r.Title';
    primaryQuery.SELECT_Statement__c += ', CloseDate, Amount';
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
    question1.Available_for__c = 'Both';
    question1.Question_Field_Type__c = 'Text';

    Document_Template_Question__c question2 = new Document_Template_Question__c();
    question2.Question__c = 'Major Donors Only?';
    question2.Document_Template__c = template.Id;
    question2.Query_Merge_Override__c = 'Append';
    question2.Document_Template_Query__c = aggregateQuery.Id;
    question2.Question_Order__c = 2;
    question2.Available_for__c = 'Both';
    question2.Question_Field_Type__c = 'Text';

    Document_Template_Question__c question3 = new Document_Template_Question__c();
    question3.Question__c = 'All Years?';
    question3.Document_Template__c = template.Id;
    question3.Query_Merge_Override__c = 'Replace';
    question3.Document_Template_Query__c = aggregateQuery.Id;
    question3.Question_Order__c = 3;
    question3.Available_for__c = 'Both';
    question3.Question_Field_Type__c = 'Text';

    insert new List<Document_Template_Question__c>{question1, question2, question3};

    Document_Post_Generation_Method__c postMethod = new Document_Post_Generation_Method__c();
    postMethod.Document_Template__c = template.Id;
    postMethod.Object__c = 'Task';
    postMethod.Method_Execution_Order__c = 1;
    postMethod.Delivery_Options__c = 'CSV - Direct Download';
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
    option3.Document_Template_Question__c = question2.Id;
    option3.Option_Value__c = 'WHERE npsp__Opportunity__c IN :' + String.escapeSingleQuotes('{!iD}');

    insert new List<Document_Template_Question_Option__c>{option1, option2, option3};

    List<Opportunity> oppList = [
      SELECT
        Id,
        AccountId,
        Name,
        (
          SELECT Id, npsp__Amount__c, npsp__Opportunity__c, npsp__General_Accounting_Unit__r.Name
          FROM npsp__Allocations__r
        )
      FROM Opportunity
    ];

    Map<Id, List<AggregateResult>> aggregateResultMap = new Map<Id, List<AggregateResult>>();

    List<AggregateResult> aggregateResults = [
      SELECT SUM(npsp__Amount__c) amount, npsp__Opportunity__c Id
      FROM npsp__Allocation__c
      GROUP BY npsp__Opportunity__c
    ];

    aggregateResultMap.put(aggregateQuery.Id, aggregateResults);

    DocumentGeneratorModel docGenModel = new DocumentGeneratorModel(
      'CSV - Direct Download',
      //   DocumentGenerationTestHelper.stationVar,
      template.Id,
      false,
      false
    );
    docGenModel.docTemp = template;
    docGenModel.docTempQueryList = [
      SELECT
        Document_Template__c,
        FROM_Object__c,
        GROUP_BY_Statement__c,
        HAVING_Statement__c,
        Id,
        LIMIT__c,
        Name,
        ORDER_BY_Statement__c,
        Primary_Query_Correlation__c,
        Query_Execution_Order__c,
        RecordTypeId,
        RecordType.Name,
        SELECT_Statement__c,
        SOQL_Query__c,
        WHERE_Clause__c
      FROM Document_Template_Query__c
    ];
    docGenModel.docTempQuestionList.add(question1);
    docGenModel.docTempQuestionList.add(question2);
    docGenModel.docTempQuestionList.add(question3);
    docGenModel.docTempOptionList.add(option1);
    docGenModel.docTempOptionList.add(option2);
    docGenModel.docTempOptionList.add(option3);
    docGenModel.docTempPrimaryQuery = primaryQuery;
    docGenModel.docTempAggregateQueryList.add(aggregateQuery);
    docGenModel.questionIdAnswerMap.put(question1.Id, option1.Option_Value__c);
    docGenModel.questionIdAnswerMap.put(question2.Id, option2.Option_Value__c);
    docGenModel.questionIdAnswerMap.put(question3.Id, option3.Option_Value__c);
    docGenModel.mergeFieldAnswerMap.put(
      question1.Query_Merge_Field__c.toLowerCase(),
      String.valueOf(Date.today().year())
    );

    DocumentGenerationCSVHandler csvHandler = new DocumentGenerationCSVHandler();

    Test.startTest();
    csvHandler.init(docGenModel);
    Boolean result1 = csvHandler.handleDocumentGeneration(oppList);
    Boolean result2 = csvHandler.completeDocumentGeneration();
    Test.stopTest();

    System.assertEquals(true, result1);

    // False because there are no records, and therefore mo data for the file
    System.assertEquals(false, result2);
  }
}