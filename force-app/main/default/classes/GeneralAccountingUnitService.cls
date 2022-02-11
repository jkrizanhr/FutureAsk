public without sharing class GeneralAccountingUnitService {
    
  public static void setGauLookupOnProject(List<npsp__General_Accounting_Unit__c> gauList, Map<Id, npsp__General_Accounting_Unit__c> oldMap) {
    Map<Id, Id> projectToGauMap = new Map<Id, Id>();

    for (npsp__General_Accounting_Unit__c gau : gauList){
      if (oldMap != null){
        npsp__General_Accounting_Unit__c old = oldMap.get(gau.Id) != null ? oldMap.get(gau.Id) : null;
        if (old.Project__c != gau.Project__c){
          if (gau.Project__c != null){ projectToGauMap.put(gau.Project__c, gau.Id); }
          if (old.Project__c != null){ projectToGauMap.put(old.Project__c, null); }
        }
      } else {
        if (gau.Project__c != null){
          projectToGauMap.put(gau.Project__c, gau.Id);
        }
      }
    }

    List<Project__c> projectsToUpdate = new List<Project__c>();
    if (!projectToGauMap.isEmpty()){
      for (Project__c proj : [SELECT Id, General_Accounting_Unit__c FROM Project__c WHERE Id IN :projectToGauMap.keySet()]){
        proj.General_Accounting_Unit__c = projectToGauMap.get(proj.Id);
        projectsToUpdate.add(proj);
      }

      if (!projectsToUpdate.isEmpty()){
        update projectsToUpdate;
      }
    }
  }
}