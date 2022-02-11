public without sharing class VarianceReportsDashboardsCtrl {

  @AuraEnabled
  public static List<Embedded_Dashboard__c> fetchData(String searchKey) {
    if (searchKey != null){
      searchKey = '%' + searchKey + '%';
      return [SELECT Id, Name, iFrame_URL__c, Embed_Code__c FROM Embedded_Dashboard__c WHERE Name LIKE :searchKey ORDER BY Name ASC];
    } else {
      return [SELECT Id, Name, iFrame_URL__c, Embed_Code__c FROM Embedded_Dashboard__c ORDER BY Name ASC];
    }
  }
}