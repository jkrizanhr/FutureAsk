public class ProjectDeliverableTriggerHandler extends TriggerHandler {
  
  public override void afterInsert() {
    ProjectDeliverableService.projectDeliverableRollupToProject(Trigger.new, null);    
  }
  public override void afterUpdate() {
    ProjectDeliverableService.projectDeliverableRollupToProject(Trigger.new, (Map<Id, Project_Deliverable__c>) Trigger.oldMap);   
  }
  public override void afterDelete() {
    ProjectDeliverableService.projectDeliverableRollupToProject(Trigger.old, null);   
  }
  public override void afterUndelete() {
    ProjectDeliverableService.projectDeliverableRollupToProject(Trigger.new, null);
  }
}