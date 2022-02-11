@IsTest
private class DocumentGenerationJobTriggerTest {
  @IsTest
  static void testBehavior() {
    DocumentGenerationTestHelper.createTemplateData();
    Document_Template__c template = [SELECT Id FROM Document_Template__c];

    Document_Generation_Job_Log__c jobLog = new Document_Generation_Job_Log__c();
    jobLog.Async_Apex_Job_Id__c = '123';
    jobLog.Document_Template__c = template.Id;
    insert jobLog;

    Document_Generation_Error__c error = new Document_Generation_Error__c();
    error.Document_Generation_Job_Log__c = jobLog.Id;
    error.Error_Message__c = 'Some error message';
    error.Apex_Class_Name__c = 'Some apex class name';
    error.Apex_Method_Name__c = 'Some apex method name';
    insert error;

    Test.startTest();
    delete jobLog;
    Test.stopTest();

    Integer result = [SELECT COUNT() FROM Document_Generation_Error__c];

    System.assertEquals(1, result);
  }

  @IsTest
  static void testDocumentGenerationErrorEvent() {
    DocumentGenerationTestHelper.createTemplateData();
    Document_Template__c template = [SELECT Id FROM Document_Template__c];

    Document_Generation_Job_Log__c jobLog = new Document_Generation_Job_Log__c();
    jobLog.Async_Apex_Job_Id__c = '123';
    jobLog.Document_Template__c = template.Id;
    insert jobLog;

    Document_Generation_Error_Event__e errorEvent = new Document_Generation_Error_Event__e();
    errorEvent.Document_Generation_Job_Id__c = jobLog.Id;
    errorEvent.Error_Message__c = 'Some error message';
    errorEvent.Apex_Class_Name__c = 'Some apex class name';
    errorEvent.Apex_Method_Name__c = 'Some apex method name';

    Test.startTest();
    EventBus.publish(errorEvent);
    Test.getEventBus().deliver();
    Test.stopTest();

    Integer result = [SELECT COUNT() FROM Document_Generation_Error__c];

    System.assertEquals(0, result);
  }
}