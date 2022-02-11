@IsTest
private class DocumentGenerationCSVService_Test {
  @IsTest
  static void testFetchTemplateQueries() {
    Document_Template__c docTemp = new Document_Template__c();
    docTemp.Name = 'Test Template';
    docTemp.Salesforce_Object__c = 'Account';
    insert docTemp;

    Document_Template_Query__c templateQuery = new Document_Template_Query__c();
    templateQuery.Name = 'Test Template Query';
    templateQuery.SELECT_Statement__c = 'SELECT Id';
    templateQuery.FROM_Object__c = 'Account';
    templateQuery.Document_Template__c = docTemp.Id;
    insert templateQuery;

    Test.startTest();
    List<Document_Template_Query__c> results = DocumentTemplateBuilderController.fetchTemplateQueries(
      docTemp.Id
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assertEquals(templateQuery.Name, results[0].Name);
    System.assertEquals('SELECT Id\nFROM Account', results[0].SOQL_Query__c);
  }

  // This is primarily to test subquery logic
  @IsTest
  static void testAutomateCSVHeaderBuild() {
    Document_Template__c docTemp = new Document_Template__c();
    docTemp.Name = 'Test Template';
    docTemp.Salesforce_Object__c = 'Account';
    insert docTemp;

    Document_Template_Query__c templateQuery = new Document_Template_Query__c();
    templateQuery.Name = 'Account Primary SOQL Query';
    templateQuery.SELECT_Statement__c = 'SELECT Name, (SELECT CloseDate, Amount, npsp__Primary_Contact__r.Name FROM Opportunities)';
    templateQuery.FROM_Object__c = 'Account';
    templateQuery.Document_Template__c = docTemp.Id;
    templateQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
      .get('Primary SOQL Query')
      .getRecordTypeId();
    insert templateQuery;

    DocumentGenerationCSVService csvService = new DocumentGenerationCSVService();

    Test.startTest();
    List<DocumentTemplateColumnConfig> results = csvService.automateCSVHeaderBuild(docTemp.Id);
    Test.stopTest();

    System.assertEquals(2, results.size());

    System.assertEquals(0, results[0].columnNum);
    System.assertEquals('Name', results[0].field);
    System.assertEquals('Name', results[0].apiName);
    System.assertEquals('Account Name', results[0].label);
    System.assertEquals('', results[0].groupingValue);

    System.assertEquals(1, results[1].columnNum);
    System.assertEquals('Opportunities Subquery', results[1].field);
    System.assertEquals('Subquery', results[1].apiName);
    System.assertEquals(null, results[1].label);
    System.assertEquals(null, results[1].groupingValue);

    System.assertEquals(1, results[1].subColumns[0].columnNum);
    System.assertEquals('CloseDate', results[1].subColumns[0].field);
    System.assertEquals('Opportunities[0].CloseDate', results[1].subColumns[0].apiName);
    System.assertEquals('Opportunities[0] Close Date', results[1].subColumns[0].label);
    System.assertEquals('0', results[1].subColumns[0].groupingValue);
    System.assertEquals('date', results[1].subColumns[0].formatting);
    System.assertEquals('', results[1].subColumns[0].altValue);

    System.assertEquals(2, results[1].subColumns[1].columnNum);
    System.assertEquals('Amount', results[1].subColumns[1].field);
    System.assertEquals('Opportunities[0].Amount', results[1].subColumns[1].apiName);
    // System.assertEquals('Opportunities[0] Amount (USD)', results[1].subColumns[1].label);
    System.assertEquals('0', results[1].subColumns[1].groupingValue);
    System.assertEquals('currency', results[1].subColumns[1].formatting);
    System.assertEquals('$0.00', results[1].subColumns[1].altValue);

    System.assertEquals(3, results[1].subColumns[2].columnNum);
    System.assertEquals('npsp__Primary_Contact__r.Name', results[1].subColumns[2].field);
    System.assertEquals(
      'Opportunities[0].npsp__Primary_Contact__r.Name',
      results[1].subColumns[2].apiName
    );
    System.assertEquals(
      'Opportunities[0] Primary Contact Full Name',
      results[1].subColumns[2].label
    );
    System.assertEquals('0', results[1].subColumns[2].groupingValue);
  }

  /*
        This test is for the scenario where a user predefines the columns but the keys need to be created
        in the DocumentGenerationCSVService using the aliases.
     */
  @IsTest
  static void testCompleteCSVColumnProperties() {
    Document_Template__c docTemp = new Document_Template__c();
    docTemp.Name = 'Test Template';
    docTemp.Salesforce_Object__c = 'Account';
    insert docTemp;

    Document_Template_Query__c templateQuery = new Document_Template_Query__c();
    templateQuery.Name = 'Account Primary SOQL Query';
    // Alias a field so that the service class splits the string in the service class
    templateQuery.SELECT_Statement__c =
      'SELECT Name Account, ' +
      '(SELECT CloseDate, Amount, npsp__Primary_Contact__r.Name Contact  FROM Opportunities)';
    templateQuery.FROM_Object__c = 'Account';
    templateQuery.Document_Template__c = docTemp.Id;
    templateQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
      .get('Primary SOQL Query')
      .getRecordTypeId();
    insert templateQuery;

    List<DocumentTemplateColumnConfig> colList = new List<DocumentTemplateColumnConfig>();

    DocumentTemplateColumnConfig col0 = new DocumentTemplateColumnConfig();
    col0.columnNum = 0;
    col0.queryId = templateQuery.Id;
    col0.field = 'Name Account';
    col0.label = 'Account';
    colList.add(col0);

    DocumentTemplateColumnConfig col1 = new DocumentTemplateColumnConfig();
    col1.columnNum = 1;
    col1.queryId = templateQuery.Id;
    col1.field = 'CloseDate';
    col1.label = 'Opportunities[0] Close Date';
    colList.add(col1);

    DocumentTemplateColumnConfig col2 = new DocumentTemplateColumnConfig();
    col2.columnNum = 2;
    col2.queryId = templateQuery.Id;
    col2.field = 'Amount';
    col2.label = 'Opportunities[0] Amount';
    colList.add(col2);

    DocumentTemplateColumnConfig col3 = new DocumentTemplateColumnConfig();
    col3.columnNum = 3;
    col3.queryId = templateQuery.Id;
    col3.field = 'npsp__Primary_Contact__r.Name Contact';
    col3.label = 'Opportunities[0] Contact';
    colList.add(col3);

    String csvColumnJSON = JSON.serialize(colList);
    DocumentGenerationCSVService csvService = new DocumentGenerationCSVService();

    Test.startTest();
    String result = csvService.completeCSVColumnProperties(csvColumnJSON);
    Test.stopTest();

    List<DocumentTemplateColumnConfig> resultColumns = new List<DocumentTemplateColumnConfig>();
    resultColumns = (List<DocumentTemplateColumnConfig>) JSON.deserialize(
      result,
      List<DocumentTemplateColumnConfig>.class
    );

    System.assertEquals(4, resultColumns.size());

    System.assertEquals(0, resultColumns[0].columnNum);
    System.assertEquals('Name Account', resultColumns[0].field);
    System.assertEquals('Account', resultColumns[0].apiName);
    System.assertEquals(col0.queryId.toLowerCase() + '_account', resultColumns[0].key);

    System.assertEquals(1, resultColumns[1].columnNum);
    System.assertEquals('CloseDate', resultColumns[1].field);
    System.assertEquals('CloseDate', resultColumns[1].apiName);
    System.assertEquals(col0.queryId.toLowerCase() + '_closedate', resultColumns[1].key);

    System.assertEquals(2, resultColumns[2].columnNum);
    System.assertEquals('Amount', resultColumns[2].field);
    System.assertEquals('Amount', resultColumns[2].apiName);
    System.assertEquals(col0.queryId.toLowerCase() + '_amount', resultColumns[2].key);

    System.assertEquals(3, resultColumns[3].columnNum);
    System.assertEquals('npsp__Primary_Contact__r.Name Contact', resultColumns[3].field);
    System.assertEquals('Contact', resultColumns[3].apiName);
    System.assertEquals(col0.queryId.toLowerCase() + '_contact', resultColumns[3].key);
  }
}