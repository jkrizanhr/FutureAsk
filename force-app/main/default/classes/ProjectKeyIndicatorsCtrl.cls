public without sharing class ProjectKeyIndicatorsCtrl {

  @AuraEnabled
  public static Project__c fetchData(Id recordId) {
    return [SELECT Id, Actual_Received__c, Total_Funding_Need__c, Number_of_Active_Deliverables__c, Number_of_Complete_Deliverables__c, 
      (SELECT Id, Total_Completed_Tasks__c, Total_Tasks__c FROM Clickup_Status_Snapshots__r ORDER BY CreatedDate DESC LIMIT 1)
      FROM Project__c WHERE Id = :recordId LIMIT 1];
  }

}