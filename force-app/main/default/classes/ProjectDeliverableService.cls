public inherited sharing class ProjectDeliverableService {

  public static void projectDeliverableRollupToProject(List<Project_Deliverable__c> projDelivs, Map<Id, Project_Deliverable__c> oldMap) {
    Map<Id, Project__c> projectMap = new Map<Id, Project__c>();

    for (Project_Deliverable__c pd : projDelivs){
      Project_Deliverable__c old = oldMap != null 
        ? oldMap.get(pd.Id)
        : null;
      if (old == null){
        Project__c temp = new Project__c(
          Id = pd.Project__c
        );
        projectMap.put(pd.Project__c, temp);
      }
      else if (old != null && old.Resource__c != pd.Resource__c){
        Project__c temp = new Project__c(
          Id = pd.Project__c
        );
        projectMap.put(pd.Project__c, temp);
      }
    }

    if (!projectMap.isEmpty()){
      for (Project__c proj : [
        SELECT Id, Resources__c, 
          (SELECT Resource__r.Name, Target_Date__c 
           FROM Project_Deliverables__r 
           WHERE Resource__c != null
           ORDER BY Target_Date__c ASC NULLS LAST, Resource__r.Name ASC) 
        FROM Project__c WHERE Id IN :projectMap.keySet()]
      ){
        Set<String> tempResourceSet = new Set<String>();
        if (!proj.Project_Deliverables__r.isEmpty()){
          for (Integer i = 0; i < proj.Project_Deliverables__r.size(); i++){
            tempResourceSet.add(proj.Project_Deliverables__r[i].Resource__r.Name);
          }
        }
        proj.Resources__c = !tempResourceSet.isEmpty()
          ? String.join((Iterable<String>)tempResourceSet, '; ')
          : null;
        projectMap.put(proj.Id, proj);
      }
    }

    if (!projectMap.isEmpty()){
      update projectMap.values();
    }
  }
}