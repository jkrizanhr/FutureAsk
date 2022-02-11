@IsTest
private class RecordProfilePicture_Test {
    @IsTest
    static void testProfilePicture() {
        Contact con = new Contact();
        con.LastName = 'test';
        insert con;

        ContentVersion cv = new ContentVersion();
        cv.Title = 'test';
        cv.VersionData = Blob.valueOf('This is a test');
        cv.ContentLocation = 'S';
        cv.PathOnClient = 'test.txt';
        insert cv;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = con.Id;
        cdl.ShareType = 'V';
        insert cdl;


        RecordProfilePicture.saveProfileId(con.Id, cdl.ContentDocumentId, 'Description', 'Contact');
        RecordProfilePicture.getProfilePicture(con.Id, 'Description', 'Contact');

        Contact conResult = [SELECT description FROM Contact WHERE ID = :con.Id];
        System.assertEquals(cdl.ContentDocumentId, conResult.description, 'Profile picture should have id of document');
    }
}