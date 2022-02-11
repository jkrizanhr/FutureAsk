public without sharing class QuarterlyReportUpload_Ctrl {
  
  @AuraEnabled
  public static String getReports(String recordId) {
    List<Quarterly_Report__c> reports = [SELECT Report_File_Id__c FROM Quarterly_Report__c WHERE Id = :recordId];
    return reports.isEmpty() ? null : reports[0].Report_File_Id__c;
  }

  @AuraEnabled
  public static void saveFileId(String recordId, String contentId) {
    if(recordId != null && contentId != null) {
      
      Quarterly_Report__c qr = [
        SELECT Id, Quarter__c, Year__c 
        FROM Quarterly_Report__c
        WHERE Id = :recordId
        LIMIT 1
      ];
      
      if (qr != null){
        qr.Report_File_Id__c = contentId;
        update qr;
      }
      
    } else {
      System.debug('Record Id or Content Id missing');
    }
  }
}