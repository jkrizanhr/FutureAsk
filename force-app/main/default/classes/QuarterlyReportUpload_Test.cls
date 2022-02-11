@isTest
private class QuarterlyReportUpload_Test {
    
  @IsTest
  static void testProjectPictureCtrl() {
    Quarterly_Report__c qr = new Quarterly_Report__c(
      Year__c = '2020',
      Quarter__c = '4th Quarter'
    );
    insert qr;

    ContentVersion cv = new ContentVersion(); 
    cv.Title = 'Test'; 
    cv.PathOnClient = '/' + cv.Title + '.pdf'; 
    Blob bodyBlob = Blob.valueOf('Test ContentVersion Body'); 
    cv.VersionData = bodyBlob; 
    cv.origin = 'H';
    insert cv;

    String contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.LinkedEntityId = qr.Id;
    cdl.ContentDocumentId = contentDocumentId;
    cdl.shareType = 'V';
    insert cdl;

    Test.startTest();
    String fileId = QuarterlyReportUpload_Ctrl.getReports(qr.Id);
    QuarterlyReportUpload_Ctrl.saveFileId(qr.Id, contentDocumentId);
    String fileIdAfter = QuarterlyReportUpload_Ctrl.getReports(qr.Id);
    Test.stopTest();

    System.assertEquals(null, fileId);
    Quarterly_Report__c res = [SELECT Report_File_Id__c FROM Quarterly_Report__c WHERE Id = :qr.Id];
    System.assertNotEquals(res.Report_File_Id__c, null);
    System.assertEquals(contentDocumentId, fileIdAfter);
  }
}