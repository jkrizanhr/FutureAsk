@IsTest
private class DocumentTemplateBuilderController_Test {
    /* NOTE: This test method is for code coverage */
    @IsTest
    static void testFetchObjects() {
        Test.startTest();
            Map<String, String> results = DocumentTemplateBuilderController.fetchSObjects();
        Test.stopTest();

        System.assertEquals(false, results.isEmpty());
    }

    /* NOTE: This test method is for code coverage */
    @IsTest
    static void testFetchVisualForcePages() {
        Test.startTest();
            List<ApexPage> results = DocumentTemplateBuilderController.fetchVisualForcePages();
        Test.stopTest();
    }

    @IsTest
    static void testFetchDocumentTemplates() {
        Document_Template__c docTemp = new Document_Template__c();
        docTemp.Name = 'Test Template';
        docTemp.Salesforce_Object__c = 'Account';
        insert docTemp;

        Test.startTest();
            List<Document_Template__c> results = DocumentTemplateBuilderController.fetchDocumentTemplates(docTemp.Id);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(docTemp.Name, results[0].Name);
    }

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
            List<Document_Template_Query__c> results
                = DocumentTemplateBuilderController.fetchTemplateQueries(docTemp.Id);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(templateQuery.Name, results[0].Name);
        System.assertEquals('SELECT Id\nFROM Account', results[0].SOQL_Query__c);
    }

    /* NOTE: This test method is for code coverage. The actual testing of the logic in the
     DocumentGenerationCSVService will be tested in another test class.
     */
    @IsTest
    static void testFetchDefaultCSVConfig() {
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
            List<DocumentTemplateColumnConfig> results
                = DocumentTemplateBuilderController.fetchDefaultCSVConfig(docTemp.Id);
        Test.stopTest();
    }

    @IsTest
    static void testSaveDocumentTemplate() {
        Document_Template__c template = new Document_Template__c();
        template.Name = 'Test Template';
        template.Salesforce_Object__c = 'Account';
        insert template;

        Document_Template_Query__c primaryQuery = new Document_Template_Query__c();
        primaryQuery.SELECT_Statement__c = 'SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Name, npe01__One2OneContact__r.FirstName, npe01__One2OneContact__r.LastName, npe01__One2OneContact__r.Title';
        primaryQuery.FROM_Object__c = 'Account';
        primaryQuery.Document_Template__c = template.Id;
        primaryQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();
        primaryQuery.ORDER_BY_Statement__c = 'ORDER BY Name';

        // NOTE: Deliberately made the casing of the merge fields inconsistent.
        Document_Template_Query__c aggregateQuery = new Document_Template_Query__c();
        aggregateQuery.SELECT_Statement__c = 'SELECT SUM(Amount) amount, CALENDAR_MONTH(CloseDate) month, AccountId Id';
        aggregateQuery.FROM_Object__c = 'Opportunity';
        aggregateQuery.WHERE_Clause__c = 'WHERE AccountId IN :' + String.escapeSingleQuotes('{!iD}');
        aggregateQuery.GROUP_BY_Statement__c = 'GROUP BY CALENDAR_MONTH(CloseDate), AccountId';
        aggregateQuery.ORDER_BY_Statement__c = 'CALENDAR_MONTH(CloseDate)';
        aggregateQuery.Document_Template__c = template.Id;
        aggregateQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Aggregate SOQL Query').getRecordTypeId();
        aggregateQuery.Query_Execution_Order__c = 2;
        aggregateQuery.Primary_Query_Correlation__c = 'Id';

        List<DocumentTemplateColumnConfig> docColumnHeaders = new List<DocumentTemplateColumnConfig>();

        DocumentTemplateColumnConfig c0 = new DocumentTemplateColumnConfig();
        c0.index = 0;
        c0.columnNum = 0;
        c0.queryId = primaryQuery.Id;
        c0.key = primaryQuery.Id + '_Name';
        c0.field = 'Name';
        c0.apiName = 'Name';
        c0.label = 'Name';
        c0.formatting = '';
        c0.groupingValue = '';
        c0.altValue = '';
        c0.subColumns = new List<DocumentTemplateColumnConfig>();
        docColumnHeaders.add(c0);

        template.CSV_Columns__c = JSON.serialize(docColumnHeaders);

        String templateJSON = JSON.serialize(template);

        Test.startTest();
            Boolean result = DocumentTemplateBuilderController.updateDocumentTemplate(templateJSON);
        Test.stopTest();

        System.assertEquals(true, result);
    }
}