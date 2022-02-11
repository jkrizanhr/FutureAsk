@IsTest
private class ContentDocumentLinkServiceTest {
  @IsTest
  static void setShareTypeTest() {
    Quarterly_Report__c qr = new Quarterly_Report__c();
    qr.Quarter__c = '1st Quarter';
    qr.Year__c = '2020';
    insert qr;
    
    ContentVersion cv = new ContentVersion(); 
    cv.Title = 'Test'; 
    cv.PathOnClient = '/' + cv.Title + '.pdf'; 
    Blob bodyBlob = Blob.valueOf('Test ContentVersion Body'); 
    cv.VersionData = bodyBlob; 
    cv.origin = 'H';
    insert cv;

    ContentDocumentLink link = new ContentDocumentLink();
    link.LinkedEntityId = qr.id;
    link.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
    link.ShareType = 'V';
    
    Test.startTest();
    insert link;
    Test.stopTest();

    ContentDocumentLink cdl = [SELECT ShareType, Visibility FROM ContentDocumentLink WHERE Id = :link.Id];
    System.assertEquals('AllUsers', cdl.Visibility);

  }
}