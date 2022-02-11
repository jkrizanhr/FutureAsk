@IsTest
private class DocumentStdSalesforceEmailService_Test {
    @IsTest
    static void testDocumentStdSalesforceEmailService() {
        DocumentGenerationTestHelper.createSampleTestData();
        DocumentGenerationTestHelper.createTemplateData();

        DocumentEmail de = new DocumentEmail();
        de.fileName = 'Test.txt';
        de.blobContent = Blob.valueOf('This is a test');
        de.contentType = 'text/plain';
        de.isTestMode = false;
        de.emailContent = '<h1>Test email body</h1>';
        de.emailSubject = 'Test email subject';
        de.fromAddress = 'info@example.com';
        de.toAddress = 'info1@example.com';

        List<DocumentEmail> deList = new List<DocumentEmail>();
        deList.add(de);

        Test.startTest();
            DocumentStandardSalesforceEmailService ctrl = new DocumentStandardSalesforceEmailService();
            Boolean sent = ctrl.sendEmails(deList);
        Test.stopTest();

        System.assertEquals(true, sent, 'Expect a success that the email sent');
    }
}