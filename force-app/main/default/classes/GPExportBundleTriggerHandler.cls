public without sharing class GPExportBundleTriggerHandler extends TriggerHandler {
  
  public override void beforeInsert() {
    Utils.setUserRegion(Trigger.new, 'Region_Category__c');
  }
  
  public override void afterInsert() {
    GPExportBundleTriggerService.bundleBatches(Trigger.new);
    GPExportBundleTriggerService.bundleTransfers(Trigger.new);
  }

  public override void beforeUpdate() {
    GPExportBundleTriggerService.manageValidationErrorCheckbox(Trigger.new);
    GPExportBundleTriggerService.sendEmailNotifications(
      Trigger.new,
      (Map<Id, GP_Export_Bundle__c>) Trigger.oldMap
    );
  }
}