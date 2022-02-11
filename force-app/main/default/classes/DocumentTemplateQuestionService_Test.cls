@IsTest
private class DocumentTemplateQuestionService_Test {
  @IsTest
  static void testSetName() {
    Document_Template__c template = new Document_Template__c();
    template.Name = 'Test Receipt';
    template.Is_Active__c = true;
    template.Salesforce_Object__c = 'Account';
    template.Delivery_Options__c = 'PDF - Direct Download';
    insert template;

    Document_Template_Query__c primaryQuery = new Document_Template_Query__c();
    primaryQuery.SELECT_Statement__c = 'SELECT Id, BillingStreet, BillingCity, BillingState,BillingPostalCode, BillingCountry, Name, npe01__One2OneContact__r.FirstName, npe01__One2OneContact__r.LastName, npe01__One2OneContact__r.Title';
    primaryQuery.FROM_Object__c = 'Account';
    primaryQuery.Document_Template__c = template.Id;
    primaryQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();
    insert primaryQuery;

    Document_Template_Query__c aggregateQuery = new Document_Template_Query__c();
    aggregateQuery.SELECT_Statement__c = 'SELECT SUM(Amount) amount, CALENDAR_MONTH(CloseDate) month';
    aggregateQuery.FROM_Object__c = 'Opportunity';
    aggregateQuery.Primary_Query_Correlation__c = '{!Id}';
    aggregateQuery.WHERE_Clause__c = 'WHERE AccountId = ' + String.escapeSingleQuotes('{!Id}') + ' AND CALENDAR_YEAR(CloseDate) = ' + String.escapeSingleQuotes('{!CloseDate}');
    aggregateQuery.GROUP_BY_Statement__c = 'GROUP BY ROLLUP(CALENDAR_MONTH(CloseDate))';
    aggregateQuery.Document_Template__c = template.Id;
    aggregateQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Aggregate SOQL Query').getRecordTypeId();
    aggregateQuery.Query_Execution_Order__c = 2;
    insert aggregateQuery;

    Document_Template_Question__c question1 = new Document_Template_Question__c();
    question1.Question__c = 'Receipt aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa Year???';
    question1.Document_Template__c = template.Id;
    question1.Query_Merge_Field__c = '{!CloseDate}';
    question1.Question_Order__c = 1;
    question1.URL_Parameter__c = 'year';

    Document_Template_Question__c question2 = new Document_Template_Question__c();
    question2.Question__c = 'Is this a test?';
    question2.Document_Template__c = template.Id;
    question2.Query_Merge_Field__c = '{!testQuestion}';
    question2.Question_Order__c = 2;
    question2.URL_Parameter__c = 'test';

    Test.startTest();
    insert question1;
    insert question2;
    Test.stopTest();

    List<Document_Template_Question__c> results = [
        SELECT
            Id,
            Name
        FROM Document_Template_Question__c
        ORDER BY Id
    ];

    System.assertEquals(2, results.size());
    System.assertEquals(
        'Receipt aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa Y...',
        results[0].Name
    );
    System.assertEquals('Is this a test?', results[1].Name);
  }

  @IsTest
  static void testValidateDistinctQueryMergeFields() {
    Document_Template__c template = new Document_Template__c();
    template.Name = 'Test Receipt';
    template.Is_Active__c = true;
    template.Salesforce_Object__c = 'Account';
    template.Delivery_Options__c = 'PDF - Direct Download';
    insert template;

    Document_Template_Query__c primaryQuery = new Document_Template_Query__c();
    primaryQuery.SELECT_Statement__c = 'SELECT Id, BillingStreet, BillingCity, BillingState,BillingPostalCode, BillingCountry, Name, npe01__One2OneContact__r.FirstName, npe01__One2OneContact__r.LastName, npe01__One2OneContact__r.Title';
    primaryQuery.FROM_Object__c = 'Account';
    primaryQuery.Document_Template__c = template.Id;
    primaryQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();
    insert primaryQuery;

    Document_Template_Query__c aggregateQuery = new Document_Template_Query__c();
    aggregateQuery.SELECT_Statement__c = 'SELECT SUM(Amount) amount, CALENDAR_MONTH(CloseDate) month';
    aggregateQuery.FROM_Object__c = 'Opportunity';
    aggregateQuery.WHERE_Clause__c = 'WHERE AccountId = ' + String.escapeSingleQuotes('{!Id}') + ' AND CALENDAR_YEAR(CloseDate) = ' + String.escapeSingleQuotes('{!CloseDate}');
    aggregateQuery.GROUP_BY_Statement__c = 'GROUP BY ROLLUP(CALENDAR_MONTH(CloseDate))';
    aggregateQuery.Document_Template__c = template.Id;
    aggregateQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Aggregate SOQL Query').getRecordTypeId();
    aggregateQuery.Query_Execution_Order__c = 2;
    insert aggregateQuery;

    Document_Template_Question__c question1 = new Document_Template_Question__c();
    question1.Question__c = 'Receipt aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa Year???';
    question1.Document_Template__c = template.Id;
    question1.Query_Merge_Field__c = '{!CloseDate}';
    question1.Question_Order__c = 1;
    question1.URL_Parameter__c = 'year';

    Document_Template_Question__c question2 = new Document_Template_Question__c();
    question2.Question__c = 'Is this a test?';
    question2.Document_Template__c = template.Id;
    question2.Query_Merge_Field__c = '{!testQuestion}';
    question2.Question_Order__c = 2;
    question2.URL_Parameter__c = 'test';

    Boolean errorThrown = false;

    Test.startTest();
    insert new List<Document_Template_Question__c>{
        question1, question2
    };
    question2.Query_Merge_Field__c = '{!CloseDate}';
    try {
      update question2;
    } catch (Exception e) {
      errorThrown = true;
    }
    Test.stopTest();

    List<Document_Template_Question__c> results = [
        SELECT Id,
            Query_Merge_Field__c
        FROM Document_Template_Question__c
        ORDER BY Id
    ];
    // Commented out because we are not validating the merge fields anymore
//        System.assertEquals('{!CloseDate}', results[0].Query_Merge_Field__c);
//        System.assertEquals('{!testQuestion}', results[1].Query_Merge_Field__c);
//        System.assertEquals(true, errorThrown);
  }

  @IsTest
  static void testValidateDistinctURLParameterFields() {
    Document_Template__c template1 = new Document_Template__c();
    template1.Name = 'Test Receipt';
    template1.Is_Active__c = true;
    template1.Salesforce_Object__c = 'Account';
    template1.Delivery_Options__c = 'PDF - Direct Download';

    Document_Template__c template2 = new Document_Template__c();
    template2.Name = 'Test Receipt 2';
    template2.Is_Active__c = true;
    template2.Salesforce_Object__c = 'Account';
    template2.Delivery_Options__c = 'CSV - Direct Download';

    insert new List<Document_Template__c>{
        template1, template2
    };

    Document_Template_Query__c primaryQuery1 = new Document_Template_Query__c();
    primaryQuery1.SELECT_Statement__c = 'SELECT Id, Name';
    primaryQuery1.FROM_Object__c = 'Account';
    primaryQuery1.Document_Template__c = template1.Id;
    primaryQuery1.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();

    Document_Template_Query__c primaryQuery2 = new Document_Template_Query__c();
    primaryQuery2.SELECT_Statement__c = 'SELECT Id, Amount, CloseDate';
    primaryQuery2.FROM_Object__c = 'Opportunity';
    primaryQuery2.WHERE_Clause__c = 'WHERE CALENDAR_YEAR(CloseDate) = {!closeDateYear}';
    primaryQuery2.Document_Template__c = template2.Id;
    primaryQuery2.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();

    Document_Template_Query__c aggregateQuery = new Document_Template_Query__c();
    aggregateQuery.SELECT_Statement__c = 'SELECT SUM(Amount) amount, CALENDAR_MONTH(CloseDate) month';
    aggregateQuery.FROM_Object__c = 'Opportunity';
    aggregateQuery.WHERE_Clause__c = 'WHERE AccountId = ' + String.escapeSingleQuotes('{!Id}') + ' AND CALENDAR_YEAR(CloseDate) = ' + String.escapeSingleQuotes('{!CloseDate}');
    aggregateQuery.GROUP_BY_Statement__c = 'GROUP BY ROLLUP(CALENDAR_MONTH(CloseDate))';
    aggregateQuery.Document_Template__c = template1.Id;
    aggregateQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Aggregate SOQL Query').getRecordTypeId();
    aggregateQuery.Query_Execution_Order__c = 2;

    insert new List<Document_Template_Query__c>{
        primaryQuery1, primaryQuery2, aggregateQuery
    };

    Document_Template_Question__c question1 = new Document_Template_Question__c();
    question1.Question__c = 'Question A';
    question1.Document_Template__c = template1.Id;
    question1.Document_Template_Query__c = aggregateQuery.Id;
    question1.Query_Merge_Field__c = '{!CloseDate}';
    question1.Question_Order__c = 1;
    question1.URL_Parameter__c = 'year';

    Document_Template_Question__c question2 = new Document_Template_Question__c();
    question2.Question__c = 'Question B';
    question2.Document_Template__c = template1.Id;
    question2.Document_Template_Query__c = aggregateQuery.Id;
    question2.Query_Merge_Field__c = '{!testQuestion}';
    question2.Question_Order__c = 2;
    question2.URL_Parameter__c = 'closeDateYear';

    Document_Template_Question__c question3 = new Document_Template_Question__c();
    question3.Question__c = 'Question C';
    question3.Document_Template__c = template2.Id;
    question3.Document_Template_Query__c = primaryQuery2.Id;
    question3.Query_Merge_Field__c = '{!testQuestion}';
    question3.Question_Order__c = 1;
    question3.URL_Parameter__c = 'closeDateYear';

    Boolean errorThrown1 = false;
    Boolean errorThrown2 = false;

    Test.startTest();
    insert new List<Document_Template_Question__c>{
        question1, question2
    };
    question2.URL_Parameter__c = 'year';
    try {
      update question2;
    } catch (Exception e) {
      errorThrown1 = true;
    }
    try {
      insert question3;
    } catch (Exception e) {
      errorThrown2 = true;
    }
    Test.stopTest();

    List<Document_Template_Question__c> results = [
        SELECT
            Id,
            URL_Parameter__c
        FROM Document_Template_Question__c
        ORDER BY Name
    ];
    // Commented out because we are not validating the merge fields anymore
//        System.assertEquals('year', results[0].URL_Parameter__c);
//        System.assertEquals('closeDateYear', results[1].URL_Parameter__c);
//        System.assertEquals('closeDateYear', results[2].URL_Parameter__c);
//        System.assertEquals(true, errorThrown1);
//        System.assertEquals(false, errorThrown2);
  }
}