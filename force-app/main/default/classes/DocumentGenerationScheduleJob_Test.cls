@IsTest
private class DocumentGenerationScheduleJob_Test {
    @TestSetup
    static void setupTest() {
        DocumentGenerationTestHelper.createSampleTestData();

        DocGenSettings__c docGenSettings = new DocGenSettings__c();
        docGenSettings.Email_Service__c = 'StandardSalesforce';
        insert docGenSettings;

        List<Document_Template__c> testTemplates = new List<Document_Template__c>();

        Document_Template__c testTemplate1 = new Document_Template__c();
        testTemplate1.Name = 'Test Template 1';
        testTemplate1.Schedule_Frequency__c = 'Hourly';
        testTemplate1.Scheduled_Delivery_Option__c = 'PDF - Direct Download';
        testTemplates.add(testTemplate1);

        Document_Template__c testTemplate2 = new Document_Template__c();
        testTemplate2.Name = 'Test Template 2';
        testTemplate2.Schedule_Frequency__c = 'Daily';
        testTemplate2.Daily_Time__c = Datetime.now().format('h a');
        testTemplate2.Scheduled_Delivery_Option__c = 'PDF - Direct Download';
        testTemplates.add(testTemplate2);

        insert testTemplates;

        Document_Template_Query__c primaryQuery1 = new Document_Template_Query__c();
        primaryQuery1.SELECT_Statement__c = 'SELECT Id, BillingStreet, BillingCity, BillingState,BillingPostalCode, BillingCountry, Name, npe01__One2OneContact__r.FirstName, npe01__One2OneContact__r.LastName, npe01__One2OneContact__r.Title';
        primaryQuery1.FROM_Object__c = 'Account';
        primaryQuery1.Document_Template__c = testTemplate1.Id;
        primaryQuery1.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();
        insert primaryQuery1;

        Document_Template_Query__c primaryQuery2 = new Document_Template_Query__c();
        primaryQuery2.SELECT_Statement__c = 'SELECT Id, BillingStreet, BillingCity, BillingState,BillingPostalCode, BillingCountry, Name, npe01__One2OneContact__r.FirstName, npe01__One2OneContact__r.LastName, npe01__One2OneContact__r.Title';
        primaryQuery2.FROM_Object__c = 'Account';
        primaryQuery2.Document_Template__c = testTemplate2.Id;
        primaryQuery2.RecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();
        insert primaryQuery2;

        Document_Template_Question__c question = new Document_Template_Question__c();
        question.Question__c = 'Receipt Year?';
        question.Document_Template__c = testTemplate1.Id;
        question.Query_Merge_Field__c = '{!CloseDate}';
        question.Question_Order__c = 1;
        question.URL_Parameter__c = 'year';
        insert question;

        Document_Template_Question_Option__c option = new Document_Template_Question_Option__c();
        option.Scheduled_Job_Default_Value__c = true;
        option.Document_Template__c = testTemplate1.Id;
        option.Document_Template_Question__c = question.Id;
        option.Option_Value__c = String.valueOf(Date.today().year());
        insert option;
    }

    @IsTest
    static void testScheduleJob() {
        Test.startTest();
        String jobId = DocumentGenerationScheduleJob.schedule(null, null);
        Test.stopTest();

        List<CronTrigger> ctList = [
            SELECT
                CreatedDate,
                CronExpression,
                CronJobDetail.JobType,
                CronJobDetail.Name,
                EndTime,
                Id,
                NextFireTime,
                StartTime,
                State
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Document Generation Schedule Job'
        ];

        System.assertNotEquals(null, jobId);
        System.assertEquals(1, ctList.size());
        System.assertEquals('0 0 13 * * ?', ctList[0].CronExpression);
        System.assertEquals('Document Generation Schedule Job', ctList[0].CronJobDetail.Name);
    }


    @IsTest
    static void testScheduleHourly() {
        Test.startTest();
        DocumentGenerationScheduleJob.scheduleHourly('Document Generation Schedule Job Test');
        Test.stopTest();

        List<AsyncApexJob> apexJobList = [
            SELECT
                ApexClassId,
                ApexClass.Name,
                CompletedDate,
                CreatedById,
                CreatedDate,
                ExtendedStatus,
                Id,
                JobItemsProcessed,
                JobType,
                LastProcessed,
                LastProcessedOffset,
                MethodName,
                NumberOfErrors,
                ParentJobId,
                Status,
                TotalJobItems
            FROM AsyncApexJob
        ];

        List<CronTrigger> ctList = [
            SELECT
                CreatedDate,
                CronExpression,
                CronJobDetail.JobType,
                CronJobDetail.Name,
                EndTime,
                Id,
                NextFireTime,
                StartTime,
                State
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Document Generation Schedule Job Test'
        ];

        System.assertEquals(false, apexJobList.isEmpty());
        System.assertEquals(1, ctList.size());
    }
}