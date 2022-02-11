public without sharing class CashBatchTriggerHandler extends TriggerHandler {
  public override void beforeInsert() {
    Utils.setUserRegion(Trigger.new, 'Region_Category__c');
    CashBatchService.handleCurrencyConversion(Trigger.new);
    CashBatchService.ensureBatchConfigurationIsUnique(Trigger.new);
  }
  public override void beforeUpdate() {
    CashBatchService.handleCurrencyConversionBeforeUpdate(Trigger.new,(Map<Id, Cash_Batch__c>) Trigger.oldMap);
    CashBatchService.ensureBatchIsEditable(Trigger.new, (Map<Id, Cash_Batch__c>) Trigger.oldMap);
    CashBatchService.setApprovedByOnBatch(Trigger.new, (Map<Id, Cash_Batch__c>) Trigger.oldMap);
    CashBatchService.ensureBatchConfigurationIsUnique(Trigger.new);
  }
  public override void beforeDelete() {
    CashBatchService.ensureBatchIsEditable(Trigger.old, null);
  }
}