@IsTest
private class DocumentGenerationController_Test {
  /*
    Tests:
    - WHERE IN clause is changed to WHERE =
    - Whether aggregate result works correctly or needs to have an Id
    to the result of the primary query
    - Case sensitivity for merge fields
    - alias fields
    - End to end test
   */

  @IsTest
  static void testEdgeCaseFieldMerging_OneOffPDFDownload() {
    DocumentGenerationTestHelper.createSampleTestData();
    DocumentGenerationTestHelper.createTemplateData();
    DocGenSettings__c docGenSettings = new DocGenSettings__c();
    docGenSettings.Email_Service__c = 'StandardSalesforce';
    insert docGenSettings;

    List<Document_Template__c> templateList = [SELECT Id FROM Document_Template__c];

    List<Document_Template_Question__c> questionList = [
      SELECT Id
      FROM Document_Template_Question__c
    ];

    Map<String, String> questionIdAnswerMap = new Map<String, String>();
    questionIdAnswerMap.put(questionList[0].Id, String.valueOf(Date.today().year()));

    Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

    User testUser = new User();
    testUser.Alias = 'sysAdmin';
    testUser.Email = 'sysAdminUser@example.com';
    testUser.EmailEncodingKey = 'UTF-8';
    testUser.LastName = 'Testing';
    testUser.LanguageLocaleKey = 'en_US';
    testUser.LocaleSidKey = 'en_US';
    testUser.ProfileId = sysAdminProfile.Id;
    testUser.TimeZoneSidKey = 'America/Los_Angeles';
    testUser.Username = 'sysAdminUser@example.com';
    insert testUser;

    List<Account> accList = [SELECT Id FROM Account WHERE Name = 'Test Organization'];

    Test.startTest();
    System.runAs(testUser) {
      ApexPages.currentPage().getParameters().put('templateId', templateList[0].Id);
      ApexPages.currentPage().getParameters().put('deliveryOption', 'PDF - Direct Download');
      ApexPages.currentPage()
        .getParameters()
        .put(questionList[0].Id, String.valueOf(Date.today().year()));
      ApexPages.currentPage().getParameters().put('recordIds', accList[0].Id);
      DocumentGenerationController controller = new DocumentGenerationController();
      controller.templateId = templateList[0].Id;
      controller.isTestMode = false;
      controller.recordIds = new List<String>{ accList[0].Id };
      controller.deliveryOption = 'PDF - Direct Download';
      controller.questionIdAnswerMap = questionIdAnswerMap;
      controller.processDocuments();
    }
    Test.stopTest();

    System.assertEquals(1, [SELECT Id FROM Task].size());
  }
}