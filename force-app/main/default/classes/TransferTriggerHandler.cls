public without sharing class TransferTriggerHandler extends TriggerHandler {
  public override void beforeInsert() {
    TransferService.defaultFundGLAccount(Trigger.new);
  }

  public override void afterInsert() {
    TransferService.createReciprocal(Trigger.new);
  }

  public override void afterUpdate() {
    TransferService.handleUpdate(
      Trigger.new,
      (Map<Id, Transfer__c>) Trigger.oldMap
    );
  }
}