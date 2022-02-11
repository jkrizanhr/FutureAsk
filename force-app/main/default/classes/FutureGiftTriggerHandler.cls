public class FutureGiftTriggerHandler extends TriggerHandler {
    
  public override void beforeInsert() {
    Utils.setUserRegion(Trigger.new, 'Region_Category__c');
    FutureGiftService.handleCurrencyConversionTargetAsk(Trigger.new);
    FutureGiftService.handleCurrencyConversionActualAsk(Trigger.new);
  }
  public override void afterInsert() {
    FutureGiftService.futureGiftRollupsToAccount(Trigger.new, null);
    FutureGiftService.createFutureGiftStageHistoryRecord(Trigger.new, null);
    FutureGiftService.createFutureGiftRoleForDonorRelationshipManager(Trigger.new);
  }
  public override void beforeUpdate() {
    FutureGiftService.handleCurrencyConversionBeforeUpdate(Trigger.new, (Map<Id, Future_Gift__c>) Trigger.oldMap);
    FutureGiftService.validateAllocationsOnStageChange(Trigger.new, (Map<Id, Future_Gift__c>) Trigger.oldMap);
  }
  public override void afterUpdate() {
    FutureGiftService.futureGiftRollupsToAccount(Trigger.new, (Map<Id, Future_Gift__c>) Trigger.oldMap);
    FutureGiftService.createFutureGiftStageHistoryRecord(Trigger.new, (Map<Id, Future_Gift__c>) Trigger.oldMap);
  }
  public override void afterDelete() {
    FutureGiftService.futureGiftRollupsToAccount(Trigger.old, null);
  }
  public override void afterUndelete() {
    FutureGiftService.futureGiftRollupsToAccount(Trigger.new, null);
  }
}