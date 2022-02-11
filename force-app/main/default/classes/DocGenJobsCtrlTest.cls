@IsTest
private class DocGenJobsCtrlTest {
  @IsTest
  static void testDeleteOldJobLogs() {
    DocumentGenerationTestHelper.createTemplateData();
    Document_Template__c template = [SELECT Id FROM Document_Template__c];

    Document_Generation_Job_Log__c jobLog = new Document_Generation_Job_Log__c();
    jobLog.Async_Apex_Job_Id__c = '123';
    jobLog.Document_Template__c = template.Id;
    insert jobLog;

    Test.setCreatedDate(jobLog.Id, Date.today().addDays(-40));

    Test.startTest();
    DocGenJobsController.deleteOldJobLogs();
    Test.stopTest();

    System.assertEquals(0, [SELECT COUNT() FROM Document_Generation_Job_Log__c]);
  }

  @IsTest
  static void testFetchJobLogs() {
    DocumentGenerationTestHelper.createTemplateData();
    Document_Template__c template = [SELECT Id FROM Document_Template__c];

    Document_Generation_Job_Log__c jobLog1 = new Document_Generation_Job_Log__c();
    jobLog1.Async_Apex_Job_Id__c = '123';
    jobLog1.Document_Template__c = template.Id;

    Document_Generation_Job_Log__c jobLog2 = new Document_Generation_Job_Log__c();
    jobLog2.Async_Apex_Job_Id__c = '456';
    jobLog2.Document_Template__c = template.Id;

    insert new List<Document_Generation_Job_Log__c>{jobLog1, jobLog2};

    Test.setCreatedDate(jobLog1.Id, Date.today().addDays(-30));

    Test.startTest();
    List<Document_Generation_Job_Log__c> results = DocGenJobsController.fetchJobLogs();
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assertEquals(jobLog2.Id, results[0].Id);
  }

  @IsTest
  static void testFetchApexJobs() {
    DocumentGenerationTestHelper.createTemplateData();
    Document_Template__c template = [SELECT Delivery_Options__c, Id FROM Document_Template__c];

    Map<String, String> questionAnswerMap = new Map<String, String>();

    Test.startTest();
    Id jobId = Database.executeBatch(
      new DocumentGenerationBatchJob(
        template.Id,
        template.Delivery_Options__c,
        false,
        questionAnswerMap
      )
    );
    Test.stopTest();

    List<AsyncApexJob> results = DocGenJobsController.fetchApexJobs(new List<String>{jobId});
    System.assertEquals(1, results.size());
  }

  @IsTest
  static void testAbortBatchJob() {
    DocumentGenerationTestHelper.createTemplateData();
    Document_Template__c template = [SELECT Delivery_Options__c, Id FROM Document_Template__c];

    Map<String, String> questionAnswerMap = new Map<String, String>();

    Test.startTest();
    Id jobId = Database.executeBatch(
      new DocumentGenerationBatchJob(
        template.Id,
        template.Delivery_Options__c,
        false,
        questionAnswerMap
      )
    );
    Boolean res = DocGenJobsController.abortBatchJob(jobId);
    Test.stopTest();

    System.assertEquals(true, res);
  }

  @IsTest
  static void testFetchContentVersions() {
    DocumentGenerationTestHelper.createTemplateData();
    Document_Template__c template = [SELECT Id FROM Document_Template__c];

    Document_Generation_Job_Log__c jobLog = new Document_Generation_Job_Log__c();
    jobLog.Async_Apex_Job_Id__c = '123';
    jobLog.Document_Template__c = template.Id;
    insert jobLog;

    ContentVersion cv = new ContentVersion();
    cv.Title = 'Test';
    cv.VersionData = Blob.valueOf('Some Text.');
    cv.PathOnClient = 'Test.PDF';
    insert cv;

    ContentDocumentLink link = new ContentDocumentLink();
    link.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
    link.LinkedEntityId = jobLog.Id;
    link.ShareType = 'V';
    insert link;

    Test.startTest();
    List<ContentVersion> results = DocGenJobsController.fetchContentVersions(jobLog.Id);
    Test.stopTest();

    System.assertEquals(cv.Id, results[0].Id);
  }
}