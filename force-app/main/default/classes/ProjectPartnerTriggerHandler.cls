public without sharing class ProjectPartnerTriggerHandler extends TriggerHandler{
       
  public override void afterInsert() {
    ProjectPartnerService.rollupNumberOfProjectsToAccount(Trigger.new, null);
  }
  public override void afterUpdate() {
    ProjectPartnerService.rollupNumberOfProjectsToAccount(Trigger.new, (Map<Id, Project_Partner__c>)Trigger.oldMap);
  }
  public override void afterDelete() {
    ProjectPartnerService.rollupNumberOfProjectsToAccount(Trigger.old, null);
  }
  public override void afterUndelete() {
    ProjectPartnerService.rollupNumberOfProjectsToAccount(Trigger.new, null);
  }

}