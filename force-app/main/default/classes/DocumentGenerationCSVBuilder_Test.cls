@IsTest
private class DocumentGenerationCSVBuilder_Test {
  @IsTest
  static void testBuildCSVString() {
    DocumentGenerationTestHelper.createSampleTestData();

    DocGenSettings__c docGenSettings = new DocGenSettings__c();
    docGenSettings.Email_Service__c = 'StandardSalesforce';
    docGenSettings.CSV_File_Extension__c = 'CSV';
    docGenSettings.Max_Batch_Size__c = 100;
    insert docGenSettings;

    Document_Template__c template = new Document_Template__c();
    template.Name = 'Test Receipt';
    template.Is_Active__c = true;
    template.Salesforce_Object__c = 'Account';
    template.Email_Template__c = 'Dear {!npe01__One2OneContact__r.SALUTATION} {!npe01__One2OneContact__r.FirstName} {!npe01__One2OneContact__r.LastName}, Attached is your annual receipt.Thank you, Candoris Test';
    template.Delivery_Options__c = 'CSV - Direct Download';
    template.FROM_Address__c = 'test@test.com';
    template.Show_Headers__c = true;
    insert template;

    Document_Template_Query__c primaryQuery = new Document_Template_Query__c();
    primaryQuery.Name = 'Account Primary Query';
    primaryQuery.SELECT_Statement__c = 'SELECT Id, BillingStreet, Name';
    primaryQuery.SELECT_Statement__c += ', npe01__One2OneContact__r.FirstName, npe01__One2OneContact__r.LastName, npe01__One2OneContact__r.Title';
    primaryQuery.SELECT_Statement__c += ', (SELECT npsp__MailingStreet__c, npsp__MailingCity__c, npsp__MailingState__c FROM npsp__Addresses__r)';
    primaryQuery.FROM_Object__c = 'Account';
    primaryQuery.Document_Template__c = template.Id;
    primaryQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
      .get('Primary SOQL Query')
      .getRecordTypeId();
    primaryQuery.ORDER_BY_Statement__c = 'ORDER BY Name';

    Document_Template_Query__c secondaryQuery = new Document_Template_Query__c();
    secondaryQuery.Name = 'Contact Secondary Query';
    secondaryQuery.SELECT_Statement__c = 'SELECT Id, AccountId, FirstName, LastName, Email';
    secondaryQuery.FROM_Object__c = 'Contact';
    secondaryQuery.Document_Template__c = template.Id;
    secondaryQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
      .get('Secondary SOQL Query')
      .getRecordTypeId();
    secondaryQuery.ORDER_BY_Statement__c = 'ORDER BY AccountId, FirstName';
    secondaryQuery.Primary_Query_Correlation__c = 'Id';
    secondaryQuery.Correlating_Query_Field__c = 'AccountId';
    secondaryQuery.Query_Execution_Order__c = 2;

    // NOTE: Deliberately made the casing of the merge fields inconsistent.
    Document_Template_Query__c aggregateQuery = new Document_Template_Query__c();
    aggregateQuery.Name = 'Opportunity Aggregate Query';
    aggregateQuery.SELECT_Statement__c = 'SELECT SUM(Amount) amount, CALENDAR_MONTH(CloseDate) month, AccountId Id';
    aggregateQuery.FROM_Object__c = 'Opportunity';
    aggregateQuery.WHERE_Clause__c = 'WHERE AccountId IN :' + String.escapeSingleQuotes('{!iD}');
    aggregateQuery.GROUP_BY_Statement__c = 'GROUP BY CALENDAR_MONTH(CloseDate), AccountId';
    aggregateQuery.ORDER_BY_Statement__c = 'CALENDAR_MONTH(CloseDate)';
    aggregateQuery.Document_Template__c = template.Id;
    aggregateQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
      .get('Aggregate SOQL Query')
      .getRecordTypeId();
    aggregateQuery.Query_Execution_Order__c = 3;
    aggregateQuery.Primary_Query_Correlation__c = 'Id';
    aggregateQuery.Correlating_Query_Field__c = 'Id';

    // Document_Template_Query__c customMetadataQuery = new Document_Template_Query__c();
    // customMetadataQuery.Name = 'Station Variable Custom Metadata Query';
    // customMetadataQuery.SELECT_Statement__c = 'SELECT Id, Manager__c';
    // customMetadataQuery.FROM_Object__c = 'Station_Variable__mdt';
    // // customMetadataQuery.WHERE_Clause__c = 'WHERE Station__c = \'{!stationVar}\'';
    // customMetadataQuery.Document_Template__c = template.Id;
    // customMetadataQuery.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
    //   .get('Custom Metadata SOQL Query')
    //   .getRecordTypeId();
    // customMetadataQuery.Query_Execution_Order__c = 4;
    // customMetadataQuery.Primary_Query_Correlation__c = '';
    // customMetadataQuery.Correlating_Query_Field__c = '';

    insert new List<Document_Template_Query__c>{ primaryQuery, secondaryQuery, aggregateQuery };

    List<DocumentTemplateColumnConfig> docColumnHeaders = new List<DocumentTemplateColumnConfig>();

    // Primary Query Columns
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

    DocumentTemplateColumnConfig primaryQueryCol2 = new DocumentTemplateColumnConfig();
    primaryQueryCol2.altValue = '';
    primaryQueryCol2.apiName = 'Id';
    primaryQueryCol2.columnNum = 1;
    primaryQueryCol2.field = 'Id';
    primaryQueryCol2.formatting = '';
    primaryQueryCol2.groupingValue = '';
    primaryQueryCol2.index = 1;
    primaryQueryCol2.key = primaryQuery.Id + '_Id';
    primaryQueryCol2.label = 'Id';
    primaryQueryCol2.queryId = primaryQuery.Id;
    primaryQueryCol2.selectIndex = 0;
    primaryQueryCol2.selectSource = 'Primary';
    docColumnHeaders.add(primaryQueryCol2);

    DocumentTemplateColumnConfig primaryQueryCol3 = new DocumentTemplateColumnConfig();
    primaryQueryCol3.altValue = '';
    primaryQueryCol3.apiName = 'BillingStreet';
    primaryQueryCol3.columnNum = 2;
    primaryQueryCol3.field = 'BillingStreet';
    primaryQueryCol3.formatting = '';
    primaryQueryCol3.groupingValue = '';
    primaryQueryCol3.index = 2;
    primaryQueryCol3.key = primaryQuery.Id + '_BillingStreet';
    primaryQueryCol3.label = 'BillingStreet';
    primaryQueryCol3.queryId = primaryQuery.Id;
    primaryQueryCol3.selectIndex = 0;
    primaryQueryCol3.selectSource = 'Primary';
    docColumnHeaders.add(primaryQueryCol3);

    // Primary Query related object columns
    DocumentTemplateColumnConfig relatedObjectCol1 = new DocumentTemplateColumnConfig();
    relatedObjectCol1.altValue = '';
    relatedObjectCol1.apiName = 'npe01__One2OneContact__r.FirstName';
    relatedObjectCol1.columnNum = 3;
    relatedObjectCol1.field = 'npe01__One2OneContact__r.FirstName';
    relatedObjectCol1.formatting = '';
    relatedObjectCol1.groupingValue = '';
    relatedObjectCol1.index = 3;
    relatedObjectCol1.key = primaryQuery.Id + '_npe01__One2OneContact__r.FirstName';
    relatedObjectCol1.label = 'Primary Contact First Name';
    relatedObjectCol1.queryId = primaryQuery.Id;
    relatedObjectCol1.selectIndex = 0;
    relatedObjectCol1.selectSource = 'Primary';
    docColumnHeaders.add(relatedObjectCol1);

    DocumentTemplateColumnConfig relatedObjectCol2 = new DocumentTemplateColumnConfig();
    relatedObjectCol2.altValue = '';
    relatedObjectCol2.apiName = 'npe01__One2OneContact__r.LastName';
    relatedObjectCol2.columnNum = 4;
    relatedObjectCol2.field = 'npe01__One2OneContact__r.LastName';
    relatedObjectCol2.formatting = '';
    relatedObjectCol2.groupingValue = '';
    relatedObjectCol2.index = 4;
    relatedObjectCol2.key = primaryQuery.Id + '_npe01__One2OneContact__r.LastName';
    relatedObjectCol2.label = 'Primary Contact Last Name';
    relatedObjectCol2.queryId = primaryQuery.Id;
    relatedObjectCol2.selectIndex = 0;
    relatedObjectCol2.selectSource = 'Primary';
    docColumnHeaders.add(relatedObjectCol2);

    DocumentTemplateColumnConfig relatedObjectCol3 = new DocumentTemplateColumnConfig();
    relatedObjectCol3.altValue = '';
    relatedObjectCol3.apiName = 'npe01__One2OneContact__r.Title';
    relatedObjectCol3.columnNum = 5;
    relatedObjectCol3.field = 'npe01__One2OneContact__r.Title';
    relatedObjectCol3.formatting = '';
    relatedObjectCol3.groupingValue = '';
    relatedObjectCol3.index = 5;
    relatedObjectCol3.key = primaryQuery.Id + '_npe01__One2OneContact__r.Title';
    relatedObjectCol3.label = 'Primary Contact Title';
    relatedObjectCol3.queryId = primaryQuery.Id;
    relatedObjectCol3.selectIndex = 0;
    relatedObjectCol3.selectSource = 'Primary';
    docColumnHeaders.add(relatedObjectCol3);

    // Subquery Columns
    DocumentTemplateColumnConfig subQueryCol1 = new DocumentTemplateColumnConfig();
    subQueryCol1.altValue = '';
    subQueryCol1.apiName = 'Subquery';
    subQueryCol1.columnNum = 6;
    subQueryCol1.field = 'npsp__Addresses__r Subquery';
    subQueryCol1.formatting = '';
    subQueryCol1.groupingValue = '';
    subQueryCol1.index = 6;
    subQueryCol1.key = primaryQuery.Id + '_npsp__Addresses__r';
    subQueryCol1.label = '';
    subQueryCol1.queryId = primaryQuery.Id;
    subQueryCol1.selectIndex = 1; // Second SELECT statement (so index 1) in the primary query
    subQueryCol1.selectSource = 'npsp__Addresses__r Secondary';
    subQueryCol1.subColumns = new List<DocumentTemplateColumnConfig>();
    docColumnHeaders.add(subQueryCol1);

    DocumentTemplateColumnConfig subQueryCol1SubCol1 = new DocumentTemplateColumnConfig();
    subQueryCol1SubCol1.altValue = '';
    subQueryCol1SubCol1.apiName = 'npsp__Addresses__r[0].npsp__MailingStreet__c';
    subQueryCol1SubCol1.columnNum = 6;
    subQueryCol1SubCol1.field = 'npsp__MailingStreet__c';
    subQueryCol1SubCol1.formatting = '';
    subQueryCol1SubCol1.groupingValue = '0';
    subQueryCol1SubCol1.index = 0;
    subQueryCol1SubCol1.key = primaryQuery.Id + '_npsp__Addresses__r[0].npsp__MailingStreet__c';
    subQueryCol1SubCol1.label = 'npsp__Addresses__r[0] Mailing Street';
    subQueryCol1SubCol1.parentIndex = subQueryCol1.index;
    subQueryCol1SubCol1.queryId = primaryQuery.Id;
    subQueryCol1SubCol1.selectIndex = 1;
    subQueryCol1SubCol1.selectSource = subQueryCol1.selectSource;
    subQueryCol1.subColumns.add(subQueryCol1SubCol1);

    DocumentTemplateColumnConfig subQueryCol1SubCol2 = new DocumentTemplateColumnConfig();
    subQueryCol1SubCol2.altValue = '';
    subQueryCol1SubCol2.apiName = 'npsp__Addresses__r[0].npsp__MailingCity__c';
    subQueryCol1SubCol2.columnNum = 7;
    subQueryCol1SubCol2.field = 'npsp__MailingCity__c';
    subQueryCol1SubCol2.formatting = '';
    subQueryCol1SubCol2.groupingValue = '0';
    subQueryCol1SubCol2.index = 1;
    subQueryCol1SubCol2.key = primaryQuery.Id + '_npsp__Addresses__r[0].npsp__MailingCity__c';
    subQueryCol1SubCol2.label = 'npsp__Addresses__r[0] Mailing City';
    subQueryCol1SubCol2.parentIndex = subQueryCol1.index;
    subQueryCol1SubCol2.queryId = primaryQuery.Id;
    subQueryCol1SubCol2.selectIndex = 1;
    subQueryCol1SubCol2.selectSource = subQueryCol1.selectSource;
    subQueryCol1.subColumns.add(subQueryCol1SubCol2);

    // Secondary Query Columns
    DocumentTemplateColumnConfig secondaryQueryCol1 = new DocumentTemplateColumnConfig();
    secondaryQueryCol1.altValue = '';
    secondaryQueryCol1.apiName = 'Secondary';
    secondaryQueryCol1.columnNum = 8;
    secondaryQueryCol1.field = 'Contact Secondary';
    secondaryQueryCol1.formatting = '';
    secondaryQueryCol1.groupingValue = '';
    secondaryQueryCol1.index = 7;
    secondaryQueryCol1.key = secondaryQuery.Id + '_Contact';
    secondaryQueryCol1.label = '';
    secondaryQueryCol1.queryId = secondaryQuery.Id;
    secondaryQueryCol1.selectIndex = 0;
    secondaryQueryCol1.selectSource = 'Contact Secondary';
    secondaryQueryCol1.subColumns = new List<DocumentTemplateColumnConfig>();
    docColumnHeaders.add(secondaryQueryCol1);

    DocumentTemplateColumnConfig secondaryQuerySubCol1 = new DocumentTemplateColumnConfig();
    secondaryQuerySubCol1.altValue = '';
    secondaryQuerySubCol1.apiName = 'FirstName';
    secondaryQuerySubCol1.columnNum = 8;
    secondaryQuerySubCol1.field = 'FirstName';
    secondaryQuerySubCol1.formatting = '';
    secondaryQuerySubCol1.groupingValue = '0';
    secondaryQuerySubCol1.index = 0;
    secondaryQuerySubCol1.key = secondaryQuery.Id + '_FirstName';
    secondaryQuerySubCol1.label = 'First Name';
    secondaryQuerySubCol1.parentIndex = secondaryQueryCol1.index;
    secondaryQuerySubCol1.queryId = secondaryQuery.Id;
    secondaryQuerySubCol1.selectIndex = 0;
    secondaryQuerySubCol1.selectSource = secondaryQueryCol1.selectSource;
    secondaryQueryCol1.subColumns.add(secondaryQuerySubCol1);

    DocumentTemplateColumnConfig secondaryQuerySubCol2 = new DocumentTemplateColumnConfig();
    secondaryQuerySubCol2.altValue = '';
    secondaryQuerySubCol2.apiName = 'Email';
    secondaryQuerySubCol2.columnNum = 9;
    secondaryQuerySubCol2.field = 'Email';
    secondaryQuerySubCol2.formatting = '';
    secondaryQuerySubCol2.groupingValue = '0';
    secondaryQuerySubCol2.index = 1;
    secondaryQuerySubCol2.key = secondaryQuery.Id + '_Email';
    secondaryQuerySubCol2.label = 'Email';
    secondaryQuerySubCol2.parentIndex = secondaryQueryCol1.index;
    secondaryQuerySubCol2.queryId = secondaryQuery.Id;
    secondaryQuerySubCol2.selectIndex = 0;
    secondaryQuerySubCol2.selectSource = secondaryQueryCol1.selectSource;
    secondaryQueryCol1.subColumns.add(secondaryQuerySubCol2);

    // Aggregate Query Columns
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

    // // Custom Metadta Query Columns
    // DocumentTemplateColumnConfig customMetadataQueryCol1 = new DocumentTemplateColumnConfig();
    // customMetadataQueryCol1.altValue = '';
    // customMetadataQueryCol1.apiName = 'Manager__c';
    // customMetadataQueryCol1.columnNum = 11;
    // customMetadataQueryCol1.field = 'Manager__c';
    // customMetadataQueryCol1.formatting = '';
    // customMetadataQueryCol1.groupingValue = '';
    // customMetadataQueryCol1.index = 9;
    // customMetadataQueryCol1.key = customMetadataQuery.Id + '_Manager__c';
    // customMetadataQueryCol1.label = 'Manager';
    // customMetadataQueryCol1.queryId = customMetadataQuery.Id;
    // customMetadataQueryCol1.selectIndex = 0;
    // customMetadataQueryCol1.selectSource = 'Custom Metadata';
    // docColumnHeaders.add(customMetadataQueryCol1);

    template.CSV_Columns__c = JSON.serialize(docColumnHeaders);
    update template;

    Document_Post_Generation_Method__c postMethod = new Document_Post_Generation_Method__c();
    postMethod.Document_Template__c = template.Id;
    postMethod.Object__c = 'Task';
    postMethod.Method_Execution_Order__c = 1;
    postMethod.Delivery_Options__c = 'CSV - Direct Download';
    postMethod.Data_to_Insert_Update__c = '{"OwnerId": "{!UserInfo.getUserID()}", "Subject": "Test Receipt Emailed", "Status": "Completed", "ActivityDate": "{!TODAY}"}';
    insert postMethod;

    List<Account> accounts = [
      SELECT
        Id,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingPostalCode,
        BillingCountry,
        Name,
        npe01__One2OneContact__r.FirstName,
        npe01__One2OneContact__r.LastName,
        npe01__One2OneContact__r.Title,
        RecordType.Name,
        (SELECT npsp__MailingStreet__c, npsp__MailingCity__c FROM npsp__Addresses__r)
      FROM Account
      ORDER BY Name
    ];

    List<String> recordIds = new List<String>();
    for (Account acc : accounts) {
      recordIds.add(acc.Id);
    }

    // Create documents
    DocumentGenerationEngine engine = new DocumentGenerationEngine(
      recordIds,
      template.Id,
      template.Delivery_Options__c,
      false,
      false
    );
    engine.initDocumentTemplateData();
    engine.initDocumentQuestionMaps(null);
    engine.initDocumentTemplateQueries();
    engine.initDocumentGenerationHandler();
    String primarySOQLQueryString = engine.buildPrimarySOQLQueryString();
    List<SObject> records = engine.getSObjectRecords(primarySOQLQueryString);
    engine.setRecordList(records);
    List<DocumentGeneratorModel.Doc> documents = engine.buildDocumentModels();

    DocumentGeneratorModel docGenModel = new DocumentGeneratorModel(
      'CSV - Email',
      template.Id,
      false,
      false
    );
    docGenModel.docTemp = template;
    docGenModel.docTempQueryList.add(primaryQuery);
    docGenModel.docTempQueryList.add(secondaryQuery);
    docGenModel.docTempQueryList.add(aggregateQuery);
    // docGenModel.docTempQueryList.add(customMetadataQuery);
    docGenModel.docTempPrimaryQuery = primaryQuery;
    docGenModel.docTempSecondaryQueryList.add(secondaryQuery);
    docGenModel.docTempAggregateQueryList.add(aggregateQuery);
    // docGenModel.docTempCustomMetadataQueryList.add(customMetadataQuery);

    Test.startTest();
    DocumentGenerationCSVBuilder csvBuilder = new DocumentGenerationCSVBuilder(
      docGenModel,
      documents
    );
    List<String> results = csvBuilder.buildCSVRows();
    Test.stopTest();

    // NOTE: buildCSVRows does not include the header row.
    // The CSVHandler will join the rows with the header if needed.
    System.assertEquals(3, results.size());

    String expected0 =
      '"Contact1 Household","' +
      accounts[0].Id +
      '","123 Test Street","Test","Contact1","Test Title 1","123 Test Street","Test City","Test","testcontact1@test.com","$0.00"';
    String expected1 =
      '"Contact2 Household","' +
      accounts[1].Id +
      '","321 Test Street","Test","Contact2","Test Title 2","321 Test Street","Test City","Test","testcontact2@test.com","$0.00"';
    String expected2 =
      '"Test Organization","' +
      accounts[2].Id +
      '","789 Test Street","Test","Contact1","Test Title 1","","","","","$1,000.42"';
    //  '","789 Test Street","Test","Contact1","Test Title 1","","","","","$0.00"';
      

    System.assertEquals(expected0, results[0]);
    System.assertEquals(expected1, results[1]);
    System.assertEquals(expected2, results[2]);
  }
}