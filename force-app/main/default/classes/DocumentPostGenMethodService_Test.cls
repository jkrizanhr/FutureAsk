@IsTest
private class DocumentPostGenMethodService_Test {
  /* NOTE: This is not a full test of the DocumentPostGenMethodService class. */
  @IsTest
  static void testSpecialCharacterReplaceAndDataInsert() {
    Account a = new Account();
    a.Name = 'Test Account';
    a.BillingStreet = '123 Test Street';
    a.BillingCity = 'Test City';
    a.BillingState = 'Pennsylvania';
    a.BillingCountry = 'United States';
    a.BillingPostalCode = '17011-1111';
    insert a;

    Document_Template__c docTemp = new Document_Template__c();
    docTemp.Name = 'Test Template';
    insert docTemp;

    Document_Post_Generation_Method__c postGen = new Document_Post_Generation_Method__c();
    postGen.Name = 'Create Task';
    postGen.Object__c = 'Task';
    postGen.Data_to_Insert_Update__c = '{"WhatId": "{!Id}", "Subject": "Test Receipt Emailed", "Status": "Completed", "ActivityDate": "{!TODAY}", "Description": "Type: {!deliveryOption}\\r\\n{!Account.npo02__Formal_Greeting__c}\\r\\n{!Account.BillingStreet}\\r\\n{!Account.BillingCity}, {!Account.BillingState} {!Account.BillingPostalCode}"}';
    postGen.Delivery_Options__c = 'PDF - Direct Download';
    postGen.Method_Execution_Order__c = 1;
    postGen.Document_Template__c = docTemp.Id;
    insert postGen;

    List<SObject> records = new List<SObject>{a};

    Map<String, String> mergeFieldAnswerMap = new Map<String, String>();

    Test.startTest();
    DocumentPostGenMethodService service = new DocumentPostGenMethodService(
      new List<Document_Post_Generation_Method__c>{postGen},
      postGen.Delivery_Options__c,
      mergeFieldAnswerMap,
      null
    );
    List<DocumentGeneratorModel.PostGenContainer> results = service.processRecords(records);
    DocumentPostGenMethodService.executePostGenContainerMethods(results, null);
    Test.stopTest();

    System.assertEquals(1, results.size());
  }
}