public class AccountTriggerHandler extends TriggerHandler {
  
  public override void beforeInsert() {
    Utils.setUserRegion(Trigger.new, 'Region_Category__c');
  }
  
  public override void afterInsert() {
    AccountService.createAccountStageHistoryRecord(Trigger.new, null);
    AccountService.createPrimaryPartnershipManager(Trigger.new);

  }
  public override void afterUpdate() {
    AccountService.createAccountStageHistoryRecord(Trigger.new, (Map<Id, Account>) Trigger.oldMap);
    AccountService.notifyRMofInvestorLevelChange(Trigger.new, (Map<Id, Account>) Trigger.oldMap);
  }
  
}