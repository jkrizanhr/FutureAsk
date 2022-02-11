@IsTest
private class DocumentTemplatePreviewController_Test {
    @IsTest
    static void testBehavior() {
        Document_Template__c template = new Document_Template__c();
        template.Name = 'Test Receipt';
        template.Is_Active__c = true;
        template.Salesforce_Object__c = 'Account';
        template.Email_Template__c = 'Dear {!npe01__One2OneContact__r.SALUTATION} {!npe01__One2OneContact__r.FirstName} {!npe01__One2OneContact__r.LastName}, Attached is your annual receipt.Thank you, Candoris Test';
        template.Delivery_Options__c = 'PDF - Direct Download';
        insert template;

        Test.startTest();
            Document_Template__c documentTemplate = DocumentTemplatePreviewController.fetchTemplate(template.Id);
            List<SObject> results = DocumentTemplatePreviewController.fetchTestRecords('Account');
        Test.stopTest();

    }
}