public class ProjectTriggerHandler extends TriggerHandler {
    
  public override void afterInsert() {
    ProjectService.setProjectLookupOnGAU(Trigger.new, null);
    ProjectService.setProjectTypeFieldOnProjectPartner(Trigger.new, null);
    System.enqueueJob(new ProjectService.createProjectInClickup(Trigger.new, null));
  }
  public override void afterUpdate() {
    ProjectService.setProjectLookupOnGAU(Trigger.new, (Map<Id, Project__c>) Trigger.oldMap);
    ProjectService.setProjectTypeFieldOnProjectPartner(Trigger.new, (Map<Id, Project__c>) Trigger.oldMap);
    System.enqueueJob(new ProjectService.createProjectInClickup(Trigger.new, (Map<Id, Project__c>) Trigger.oldMap));
  }
  public override void afterUndelete() {
    ProjectService.setProjectLookupOnGAU(Trigger.new, null);
    ProjectService.setProjectTypeFieldOnProjectPartner(Trigger.new, null);
  }

}