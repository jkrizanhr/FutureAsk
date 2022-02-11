public class AccountTeamTriggerHandler extends TriggerHandler {
  
  public override void afterInsert() {
    AccountTeamService.assignAccountTeamRoles(Trigger.new);
  }
  public override void afterUpdate() {
    AccountTeamService.updateAccountTeamRoles(
    (Map<Id, Account_Team__c>)Trigger.newMap, (Map<Id, Account_Team__c>) Trigger.oldMap);
  }
  public override void afterDelete() {
    AccountTeamService.removeAccountTeamRoles(Trigger.old);
  }
  
}