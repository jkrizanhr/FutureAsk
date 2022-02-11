@IsTest
private class DocumentTemplateQueryService_Test {
    @IsTest
    static void testValidateNumPrimaryQueries() {
        Document_Template__c template = new Document_Template__c();
        template.Name = 'Test Receipt';
        template.Is_Active__c = true;
        insert template;

        Document_Template_Query__c query1 = new Document_Template_Query__c();
        query1.SELECT_Statement__c = 'Id, BillingStreet';
        query1.FROM_Object__c = 'Account';
        query1.Document_Template__c = template.Id;
        query1.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();
        insert query1;

        Document_Template_Query__c query2 = new Document_Template_Query__c();
        query2.SELECT_Statement__c = 'Id, BillingStreet, npe01__One2OneContact__r.FirstName';
        query2.FROM_Object__c = 'Account';
        query2.Document_Template__c = template.Id;
        query2.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Aggregate SOQL Query').getRecordTypeId();
        insert query2;

        Document_Template_Query__c query3 = new Document_Template_Query__c();
        query3.SELECT_Statement__c = 'Id, BillingStreet, npe01__One2OneContact__r.FirstName';
        query3.FROM_Object__c = 'Account';
        query3.Document_Template__c = template.Id;
        query3.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();

        Boolean errorThrown = false;
        Test.startTest();
        try {
            query2.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();
            update query2;
            insert query3;
        } catch (Exception e) {
            System.debug(e.getMessage());
            errorThrown = true;
        }
        Test.stopTest();

        List<Document_Template_Query__c> results = [
                SELECT Id, Document_Template__c, RecordType.Name
                FROM Document_Template_Query__c
                ORDER BY Id
        ];

        // Assertions
        System.assertEquals(true, errorThrown);
        System.assertEquals(2, results.size());
        System.assertEquals(query1.Id, results[0].Id);
        System.assertEquals('Primary SOQL Query', results[0].RecordType.Name);
        System.assertEquals(query2.Id, results[1].Id);
        System.assertEquals('Aggregate SOQL Query', results[1].RecordType.Name);
    }

    @IsTest
    static void testAssignPrimaryQuery() {
        Document_Template__c template = new Document_Template__c();
        template.Name = 'Test Receipt';
        template.Is_Active__c = true;
        insert template;

        Document_Template_Query__c query = new Document_Template_Query__c();
        query.SELECT_Statement__c = 'Id, BillingStreet, npe01__One2OneContact__r.FirstName';
        query.FROM_Object__c = 'Account';
        query.Document_Template__c = template.Id;
        query.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();

        Test.startTest();
        insert query;
        Test.stopTest();

        List<Document_Template__c> results = [
                SELECT Id, Primary_Query__c
                FROM Document_Template__c
        ];

        System.assertEquals(query.Id, results[0].Primary_Query__c);
    }

    @IsTest
    static void testBuildQuery() {
        Document_Template__c template = new Document_Template__c();
        template.Name = 'Test Receipt';
        template.Is_Active__c = true;
        template.Salesforce_Object__c = 'Account';
        template.Email_Template__c = 'Dear {!npe01__One2OneContact__r.Salutation} {!npe01__One2OneContact__r.FirstName} {!npe01__One2OneContact__r.LastName}, Attached is your annual receipt.Thank you, Candoris Test';
        template.Delivery_Options__c = 'PDF - Direct Download';
        insert template;

        Document_Template_Query__c primaryQuery = new Document_Template_Query__c();
        primaryQuery.SELECT_Statement__c = 'Id, BillingStreet, npe01__One2OneContact__r.FirstName';
        primaryQuery.FROM_Object__c = 'Account';
        primaryQuery.Document_Template__c = template.Id;
        primaryQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();
        primaryQuery.LIMIT__c = 100;

        Document_Template_Query__c aggregateQuery = new Document_Template_Query__c();
        aggregateQuery.SELECT_Statement__c = 'SELECT SUM(Amount) amount, CALENDAR_MONTH(CloseDate) month';
        aggregateQuery.FROM_Object__c = 'Opportunity';
        aggregateQuery.WHERE_Clause__c = 'WHERE AccountId = ' + String.escapeSingleQuotes('{!Id}');
        aggregateQuery.GROUP_BY_Statement__c = 'GROUP BY ROLLUP(CALENDAR_MONTH(CloseDate))';
        aggregateQuery.HAVING_Statement__c = 'HAVING SUM(Amount) > 0';
        aggregateQuery.ORDER_BY_Statement__c = 'AccountId';
        aggregateQuery.Document_Template__c = template.Id;
        aggregateQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Aggregate SOQL Query').getRecordTypeId();
        aggregateQuery.Query_Execution_Order__c = 2;
        aggregateQuery.LIMIT__c = 100;

        Test.startTest();
        insert primaryQuery;
        template.Primary_Query__c = primaryQuery.Id;
        update template;
        insert aggregateQuery;
        Test.stopTest();

        List<Document_Template_Query__c> queryResults = [
                SELECT
                        Id,
                        SELECT_Statement__c,
                        FROM_Object__c,
                        WHERE_Clause__c,
                        GROUP_BY_Statement__c,
                        HAVING_Statement__c,
                        ORDER_BY_Statement__c,
                        LIMIT__c,
                        SOQL_Query__c
                FROM Document_Template_Query__c
                ORDER BY Id
        ];

        System.assertEquals('SELECT ' + primaryQuery.SELECT_Statement__c, queryResults[0].SELECT_Statement__c);
        System.assertEquals(
                aggregateQuery.SELECT_Statement__c + '\n' +
                        'FROM ' + aggregateQuery.FROM_Object__c + '\n' +
                        aggregateQuery.WHERE_Clause__c + '\n' +
                        aggregateQuery.GROUP_BY_Statement__c + '\n' +
                        aggregateQuery.HAVING_Statement__c + '\n' +
                        'ORDER BY ' + aggregateQuery.ORDER_BY_Statement__c + '\n' +
                        'LIMIT ' + aggregateQuery.LIMIT__c,
                queryResults[1].SOQL_Query__c
        );
    }

    @IsTest
    static void testEdgeCases() {
        Document_Template__c template = new Document_Template__c();
        template.Name = 'Test Receipt';
        template.Is_Active__c = true;
        template.Salesforce_Object__c = 'Account';
        template.Email_Template__c = 'Dear {!npe01__One2OneContact__r.Salutation} {!npe01__One2OneContact__r.FirstName} {!npe01__One2OneContact__r.LastName}, Attached is your annual receipt.Thank you, Candoris Test';
        template.Delivery_Options__c = 'PDF - Direct Download';
        insert template;

        Document_Template_Query__c primaryQuery = new Document_Template_Query__c();
        primaryQuery.SELECT_Statement__c = 'Id, BillingStreet, npe01__One2OneContact__r.FirstName';
        primaryQuery.FROM_Object__c = 'Account';
        primaryQuery.Document_Template__c = template.Id;
        primaryQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();
        primaryQuery.LIMIT__c = 100;

        Document_Template_Query__c aggregateQuery = new Document_Template_Query__c();
        aggregateQuery.SELECT_Statement__c = 'SELECT SUM(Amount) amount, CALENDAR_MONTH(CloseDate) month';
        aggregateQuery.FROM_Object__c = 'Opportunity';
        aggregateQuery.WHERE_Clause__c = 'WHERE';
        aggregateQuery.GROUP_BY_Statement__c = 'GROUP BY ROLLUP(CALENDAR_MONTH(CloseDate))';
        aggregateQuery.HAVING_Statement__c = 'HAVING SUM(Amount) > 0';
        aggregateQuery.ORDER_BY_Statement__c = 'AccountId';
        aggregateQuery.Document_Template__c = template.Id;
        aggregateQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Aggregate SOQL Query').getRecordTypeId();
        aggregateQuery.Query_Execution_Order__c = 1;
        aggregateQuery.LIMIT__c = 100;

        Test.startTest();
        insert primaryQuery;
        template.Primary_Query__c = primaryQuery.Id;
        update template;
        insert aggregateQuery;
        Test.stopTest();

        List<Document_Template_Query__c> queryResults = [
                SELECT
                        Id,
                        SELECT_Statement__c,
                        FROM_Object__c,
                        WHERE_Clause__c,
                        GROUP_BY_Statement__c,
                        HAVING_Statement__c,
                        ORDER_BY_Statement__c,
                        LIMIT__c,
                        SOQL_Query__c
                FROM Document_Template_Query__c
                ORDER BY Id
        ];

        System.assertEquals('SELECT ' + primaryQuery.SELECT_Statement__c, queryResults[0].SELECT_Statement__c);
        System.assertEquals(
                aggregateQuery.SELECT_Statement__c + '\n' +
                        'FROM ' + aggregateQuery.FROM_Object__c + '\n' +
                        aggregateQuery.GROUP_BY_Statement__c + '\n' +
                        aggregateQuery.HAVING_Statement__c + '\n' +
                        'ORDER BY ' + aggregateQuery.ORDER_BY_Statement__c + '\n' +
                        'LIMIT ' + aggregateQuery.LIMIT__c,
                queryResults[1].SOQL_Query__c
        );
    }
}