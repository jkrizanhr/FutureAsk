@IsTest
private class DocumentGenerationPDFHandler_Test {
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
    template.Email_Template__c = 'Dear {!Account.npe01__One2OneContact__r.SALUTATION} {!Account.npe01__One2OneContact__r.FirstName} {!Account.npe01__One2OneContact__r.LastName}, Attached is your annual receipt.Thank you, Candoris Test';
    template.Delivery_Options__c = 'PDF - Direct Download';
    template.CSV_Columns__c = 'Name, npsp__Allocations__r[0].npsp__Amount__c, npsp__Allocations__r[0].npsp__General_Accounting_Unit__r.Name, npsp__Allocations__r[1].npsp__Amount__c, npsp__Allocations__r[1].npsp__General_Accounting_Unit__r.Name, amountSum';
    template.FROM_Address__c = 'test@test.com';
    template.Email_Recipient_Field_Path__c = 'Account.npe01__One2OneContact__r.Email';
    insert template;

    Document_Template_Query__c primaryQuery = new Document_Template_Query__c();
    primaryQuery.SELECT_Statement__c = 'SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Name, npe01__One2OneContact__r.FirstName, npe01__One2OneContact__r.LastName, npe01__One2OneContact__r.Title';
    primaryQuery.FROM_Object__c = 'Opportunity';
    primaryQuery.Document_Template__c = template.Id;
    primaryQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
      .get('Primary SOQL Query')
      .getRecordTypeId();

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

    Document_Post_Generation_Method__c postMethod = new Document_Post_Generation_Method__c();
    postMethod.Document_Template__c = template.Id;
    postMethod.Object__c = 'Task';
    postMethod.Method_Execution_Order__c = 1;
    postMethod.Delivery_Options__c = 'PDF - Direct Download';
    postMethod.Data_to_Insert_Update__c = '{"OwnerId": "{!UserInfo.getUserID()}", "Subject": "Test Receipt Generation Done", "Status": "Completed", "ActivityDate": "{!TODAY}"}';
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
    option2.Option_Value__c = 'Amount > 10000';

    Document_Template_Question_Option__c option3 = new Document_Template_Question_Option__c();
    option3.Default_Option__c = true;
    option3.Document_Template__c = template.Id;
    option3.Document_Template_Question__c = question2.Id;
    option3.Option_Value__c = 'WHERE AccountId IN :' + String.escapeSingleQuotes('{!iD}');

    insert new List<Document_Template_Question_Option__c>{option1, option2, option3};

    List<Opportunity> oppList = [
      SELECT
        Id,
        AccountId,
        Name,
        Amount,
        Account.npe01__One2OneContact__r.Email,
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
      template.Delivery_Options__c,
      // DocumentGenerationTestHelper.stationVar,
      template.Id,
      false,
      false
    );
    docGenModel.docTemp = template;
    docGenModel.docTempQueryList.add(primaryQuery);
    docGenModel.docTempQueryList.add(aggregateQuery);
    docGenModel.docTempQuestionList.add(question1);
    docGenModel.docTempQuestionList.add(question2);
    docGenModel.docTempQuestionList.add(question3);
    docGenModel.docTempOptionList.add(option1);
    docGenModel.docTempOptionList.add(option2);
    docGenModel.docTempOptionList.add(option3);
    docGenModel.docTempPrimaryQuery = primaryQuery;
    docGenModel.docTempAggregateQueryList.add(aggregateQuery);
    docGenModel.questionIdAnswerMap.put(question2.Id, option2.Option_Value__c);
    docGenModel.questionIdAnswerMap.put(question1.Id, option1.Option_Value__c);
    docGenModel.questionIdAnswerMap.put(question3.Id, option3.Option_Value__c);

    Document_Generation_Job_Log__c jobLog = new Document_Generation_Job_Log__c();
    jobLog.Async_Apex_Job_Id__c = '123';
    // jobLog.Station_Brand__c = DocumentGenerationTestHelper.stationVar;
    jobLog.Delivery_Option__c = template.Delivery_Options__c;
    jobLog.Document_Template__c = template.Id;
    jobLog.Question_Answer_JSON__c = JSON.serialize(docGenModel.questionIdAnswerMap);
    insert jobLog;

    docGenModel.jobLog = jobLog;

    DocumentGenerationPDFHandler pdfHandler = new DocumentGenerationPDFHandler();
    pdfHandler.init(docGenModel);

    Test.startTest();
    Boolean result = pdfHandler.handleDocumentGeneration(oppList);
    Test.stopTest();

    System.assertEquals(true, result);
  }
}