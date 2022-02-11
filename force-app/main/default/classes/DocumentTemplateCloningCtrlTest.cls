@IsTest
private class DocumentTemplateCloningCtrlTest {
  @IsTest
  static void testClone() {
    /* Create Test Data */
    Document_Template__c template = new Document_Template__c();
    template.Name = 'Test Template';
    template.Available_For__c = 'Bulk';
    template.Is_Active__c = true;
    template.Salesforce_Object__c = 'Account';
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

    template.Primary_Query__c = primaryQuery.Id;
    update template;

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
    aggregateQuery.Correlating_Query_Field__c = 'Id';
    insert aggregateQuery;

    Document_Template_Question__c question = new Document_Template_Question__c();
    question.Question__c = 'Receipt Year?';
    question.Document_Template__c = template.Id;
    question.Question_Order__c = 1;
    question.URL_Parameter__c = 'year';
    question.Question_Field_Type__c = 'Text';
    question.Available_for__c = 'Both';
    question.Query_Merge_Override__c = 'Append';
    question.Document_Template_Query__c = aggregateQuery.Id;
    insert question;

    Document_Post_Generation_Method__c postMethod = new Document_Post_Generation_Method__c();
    postMethod.Document_Template__c = template.Id;
    postMethod.Object__c = 'Task';
    postMethod.Method_Execution_Order__c = 1;
    postMethod.Delivery_Options__c = 'CSV - Direct Download';
    postMethod.Data_to_Insert_Update__c = '{"OwnerId": "{!UserInfo.getUserID()}", "Subject": "Test Receipt Emailed", "Status": "Completed", "ActivityDate": "{!TODAY}"}';
    insert postMethod;

    Document_Template_Question_Option__c option = new Document_Template_Question_Option__c();
    option.Default_Option__c = true;
    option.Document_Template__c = template.Id;
    option.Document_Template_Question__c = question.Id;
    option.Name = '2020';
    option.Option_Value__c = 'AND CALENDAR_YEAR(CloseDate) = 2020';
    insert option;

    List<DocumentTemplateColumnConfig> docColumnHeaders = new List<DocumentTemplateColumnConfig>();

    DocumentTemplateColumnConfig primaryQueryCol1 = new DocumentTemplateColumnConfig();
    primaryQueryCol1.altValue = '';
    primaryQueryCol1.apiName = 'Name';
    primaryQueryCol1.columnNum = 0;
    primaryQueryCol1.field = 'Name';
    primaryQueryCol1.formatting = '';
    primaryQueryCol1.groupingValue = '';
    primaryQueryCol1.index = 0;
    primaryQueryCol1.key = primaryQuery.Id + '_Name';
    primaryQueryCol1.label = 'Name';
    primaryQueryCol1.queryId = primaryQuery.Id;
    primaryQueryCol1.selectIndex = 0;
    primaryQueryCol1.selectSource = 'Primary';
    docColumnHeaders.add(primaryQueryCol1);

    DocumentTemplateColumnConfig aggregateQueryCol1 = new DocumentTemplateColumnConfig();
    aggregateQueryCol1.altValue = '';
    aggregateQueryCol1.apiName = 'Aggregate';
    aggregateQueryCol1.columnNum = 10;
    aggregateQueryCol1.field = 'Opportunity Aggregate';
    aggregateQueryCol1.formatting = '';
    aggregateQueryCol1.groupingValue = '';
    aggregateQueryCol1.index = 8;
    aggregateQueryCol1.key = aggregateQuery.Id + '_Opportunity';
    aggregateQueryCol1.label = '';
    aggregateQueryCol1.queryId = aggregateQuery.Id;
    aggregateQueryCol1.selectIndex = 0;
    aggregateQueryCol1.selectSource = 'Opportunity Aggregate';
    aggregateQueryCol1.subColumns = new List<DocumentTemplateColumnConfig>();
    docColumnHeaders.add(aggregateQueryCol1);

    DocumentTemplateColumnConfig aggregateQuerySubCol1 = new DocumentTemplateColumnConfig();
    aggregateQuerySubCol1.altValue = '$0.00';
    aggregateQuerySubCol1.apiName = 'amount';
    aggregateQuerySubCol1.columnNum = 10;
    aggregateQuerySubCol1.field = 'SUM(Amount) amount';
    aggregateQuerySubCol1.formatting = 'currency';
    aggregateQuerySubCol1.groupingValue = String.valueOf(Date.today().month());
    aggregateQuerySubCol1.index = 8;
    aggregateQuerySubCol1.key = aggregateQueryCol1.queryId + '_amount';
    aggregateQuerySubCol1.label = 'Amount';
    aggregateQuerySubCol1.parentIndex = aggregateQueryCol1.index;
    aggregateQuerySubCol1.queryId = aggregateQuery.Id;
    aggregateQuerySubCol1.selectIndex = 0;
    aggregateQuerySubCol1.selectSource = 'Opportunity Aggregate';
    aggregateQueryCol1.subColumns.add(aggregateQuerySubCol1);

    template.CSV_Columns__c = JSON.serialize(docColumnHeaders);
    update template;

    /* Execute Code to Test */
    Test.startTest();
    Id resultTemplateId = DocumentTemplateCloningCtrl.clone(template.Id);
    Test.stopTest();

    /* Retrieve Document Template Results */
    List<Document_Template__c> resultTemplates = [
      SELECT
        CSV_Columns__c,
        Delivery_Options__c,
        Email_Template__c,
        FROM_Address__c,
        Id,
        Is_Active__c,
        Name,
        Primary_Query__c,
        Salesforce_Object__c
      FROM Document_Template__c
      ORDER BY Id
    ];

    /* Document Template Assertions */
    System.assertEquals(2, resultTemplates.size());
    // The original document template
    System.assertEquals(template.Id, resultTemplates[0].Id);

    // The new document template copy
    System.assertEquals(false, resultTemplates[1].CSV_Columns__c.contains(primaryQuery.Id));
    System.assertEquals(false, resultTemplates[1].CSV_Columns__c.contains(aggregateQuery.Id));
    System.assertEquals('CSV - Direct Download', resultTemplates[1].Delivery_Options__c);
    System.assertEquals(null, resultTemplates[1].Email_Template__c);
    System.assertEquals('test@test.com', resultTemplates[1].FROM_Address__c);
    System.assertEquals(resultTemplateId, resultTemplates[1].Id);
    System.assertEquals(true, resultTemplates[1].Is_Active__c);
    System.assertEquals('Test Template(1)', resultTemplates[1].Name);
    System.assertEquals('Account', resultTemplates[1].Salesforce_Object__c);

    /* Retrieve Document Template Query Results */
    List<Document_Template_Query__c> resultTemplateQueries = [
      SELECT
        Correlating_Query_Field__c,
        Document_Template__c,
        FROM_Object__c,
        GROUP_BY_Statement__c,
        Id,
        ORDER_BY_Statement__c,
        Primary_Query_Correlation__c,
        Query_Execution_Order__c,
        RecordType.Name,
        SELECT_Statement__c,
        WHERE_Clause__c
      FROM Document_Template_Query__c
      ORDER BY Document_Template__c, Query_Execution_Order__c
    ];

    /* Primary Query Lookup Updated Assertion */
    System.assertEquals(resultTemplateQueries[2].Id, resultTemplates[1].Primary_Query__c);

    /* CSV Columns Assertion */
    String resultCSVColumns = JSON.serialize(docColumnHeaders)
      .replaceAll(primaryQuery.Id, resultTemplateQueries[2].Id)
      .replaceAll(aggregateQuery.Id, resultTemplateQueries[3].Id);
    System.assertEquals(resultCSVColumns, resultTemplates[1].CSV_Columns__c);

    /* Document Template Query Assertions */
    System.assertEquals(4, resultTemplateQueries.size());

    // The original document template queries
    System.assertEquals(primaryQuery.Id, resultTemplateQueries[0].Id);
    System.assertEquals(template.Id, resultTemplateQueries[0].Document_Template__c);
    System.assertEquals(aggregateQuery.Id, resultTemplateQueries[1].Id);
    System.assertEquals(template.Id, resultTemplateQueries[1].Document_Template__c);

    // The document template query copies
    System.assertEquals(null, resultTemplateQueries[2].Correlating_Query_Field__c);
    System.assertEquals(resultTemplateId, resultTemplateQueries[2].Document_Template__c);
    System.assertEquals('Account', resultTemplateQueries[2].FROM_Object__c);
    System.assertEquals(null, resultTemplateQueries[2].GROUP_BY_Statement__c);
    System.assertEquals(null, resultTemplateQueries[2].ORDER_BY_Statement__c);
    System.assertEquals(null, resultTemplateQueries[2].Primary_Query_Correlation__c);
    System.assertEquals(1, resultTemplateQueries[2].Query_Execution_Order__c);
    System.assertEquals('Primary SOQL Query', resultTemplateQueries[2].RecordType.Name);
    System.assertEquals(
      'SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Name, npe01__One2OneContact__r.FirstName, npe01__One2OneContact__r.LastName, npe01__One2OneContact__r.Title',
      resultTemplateQueries[2].SELECT_Statement__c
    );
    System.assertEquals(null, resultTemplateQueries[2].WHERE_Clause__c);

    System.assertEquals('Id', resultTemplateQueries[3].Correlating_Query_Field__c);
    System.assertEquals(resultTemplateId, resultTemplateQueries[3].Document_Template__c);
    System.assertEquals('Opportunity', resultTemplateQueries[3].FROM_Object__c);
    System.assertEquals(
      'GROUP BY CALENDAR_MONTH(CloseDate), AccountId',
      resultTemplateQueries[3].GROUP_BY_Statement__c
    );
    System.assertEquals(
      'ORDER BY CALENDAR_MONTH(CloseDate)',
      resultTemplateQueries[3].ORDER_BY_Statement__c
    );
    System.assertEquals('Id', resultTemplateQueries[3].Primary_Query_Correlation__c);
    System.assertEquals(2, resultTemplateQueries[3].Query_Execution_Order__c);
    System.assertEquals('Aggregate SOQL Query', resultTemplateQueries[3].RecordType.Name);
    System.assertEquals(
      'SELECT SUM(Amount) amount, CALENDAR_MONTH(CloseDate) month, AccountId Id',
      resultTemplateQueries[3].SELECT_Statement__c
    );
    System.assertEquals(
      'WHERE AccountId IN :' + String.escapeSingleQuotes('{!iD}'),
      resultTemplateQueries[3].WHERE_Clause__c
    );

    /* Retrieve Document Template Question Results */
    List<Document_Template_Question__c> resultTemplateQuestions = [
      SELECT
        Available_For__c,
        Document_Template__c,
        Document_Template_Query__c,
        Id,
        Question_Field_Type__c,
        Query_Merge_Field__c,
        Query_Merge_Override__c,
        Question__c,
        Question_Order__c,
        URL_Parameter__c
      FROM Document_Template_Question__c
      ORDER BY Document_Template__c
    ];

    /* Document Template Question Assertions */
    System.assertEquals(2, resultTemplateQuestions.size());

    // The original document template question
    System.assertEquals(template.Id, resultTemplateQuestions[0].Document_Template__c);

    // The document template question copy
    System.assertEquals('Both', resultTemplateQuestions[1].Available_For__c);
    System.assertEquals(resultTemplateId, resultTemplateQuestions[1].Document_Template__c);
    System.assertEquals(
      resultTemplateQueries[3].Id,
      resultTemplateQuestions[1].Document_Template_Query__c
    );
    System.assertEquals('Text', resultTemplateQuestions[1].Question_Field_Type__c);
    System.assertEquals(null, resultTemplateQuestions[1].Query_Merge_Field__c);
    System.assertEquals('Append', resultTemplateQuestions[1].Query_Merge_Override__c);
    System.assertEquals('Receipt Year?', resultTemplateQuestions[1].Question__c);
    System.assertEquals(1, resultTemplateQuestions[1].Question_Order__c);
    System.assertEquals('year', resultTemplateQuestions[1].URL_Parameter__c);

    /* Retrieve Document Template Question Options */
    List<Document_Template_Question_Option__c> resultQuestionOptions = [
      SELECT
        Default_Option__c,
        Document_Template__c,
        Document_Template_Question__c,
        Id,
        Name,
        Option_Value__c
      FROM Document_Template_Question_Option__c
      ORDER BY Document_Template_Question__r.Document_Template__c
    ];

    /* Document Template Question Option Assertions */
    System.assertEquals(2, resultQuestionOptions.size());

    // The original document template question option
    System.assertEquals(template.Id, resultQuestionOptions[0].Document_Template__c);

    // The document template question option copy
    System.assertEquals(true, resultQuestionOptions[1].Default_Option__c);
    System.assertEquals(resultTemplateId, resultQuestionOptions[1].Document_Template__c);
    System.assertEquals(
      resultTemplateQuestions[1].Id,
      resultQuestionOptions[1].Document_Template_Question__c
    );
    System.assertEquals('2020', resultQuestionOptions[1].Name);
    System.assertEquals(
      'AND CALENDAR_YEAR(CloseDate) = 2020',
      resultQuestionOptions[1].Option_Value__c
    );

    /* Retrieve Document Post Generation Method Results */
    List<Document_Post_Generation_Method__c> resultPostGenMethods = [
      SELECT
        Data_to_Insert_Update__c,
        Delivery_Options__c,
        Document_Template__c,
        Id,
        Method_Execution_Order__c,
        Object__c
      FROM Document_Post_Generation_Method__c
      ORDER BY Document_Template__c, Method_Execution_Order__c
    ];

    /* Document Post Generation Method Results */
    System.assertEquals(2, resultPostGenMethods.size());

    // The original document post generation method
    System.assertEquals(template.Id, resultPostGenMethods[0].Document_Template__c);

    // The document post generation method copy
    System.assertEquals(
      '{"OwnerId": "{!UserInfo.getUserID()}", "Subject": "Test Receipt Emailed", "Status": "Completed", "ActivityDate": "{!TODAY}"}',
      resultPostGenMethods[1].Data_to_Insert_Update__c
    );
    System.assertEquals('CSV - Direct Download', resultPostGenMethods[1].Delivery_Options__c);
    System.assertEquals(resultTemplateId, resultPostGenMethods[1].Document_Template__c);
    System.assertEquals(1, resultPostGenMethods[1].Method_Execution_Order__c);
    System.assertEquals('Task', resultPostGenMethods[1].Object__c);
  }
}