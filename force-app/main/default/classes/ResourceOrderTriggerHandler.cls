public without sharing class ResourceOrderTriggerHandler extends TriggerHandler {
  public override void beforeInsert() {
    ResourceOrderService.setNameInsert(Trigger.new);
  }

  public override void beforeUpdate() {
    ResourceOrderService.setNameUpdate(Trigger.new, (Map<Id, Resource_Order__c>) Trigger.oldMap);
  }

  public override void afterInsert() {
    ResourceOrderService.rollupResourceOrdersToAccount(Trigger.new, null);
    ResourceOrderService.createTasksForResourceOrders(Trigger.new, null);
  }

  public override void afterUpdate() {
    ResourceOrderService.rollupResourceOrdersToAccount(
      Trigger.new,
      (Map<Id, Resource_Order__c>) Trigger.oldMap
    );
    ResourceOrderService.updateProjectRollups(
      Trigger.new,
      (Map<Id, Resource_Order__c>) Trigger.oldMap
    );
    ResourceOrderService.createTasksForResourceOrders(
      Trigger.new,
      (Map<Id, Resource_Order__c>) Trigger.oldMap
    );
  }

  public override void afterDelete() {
    ResourceOrderService.rollupResourceOrdersToAccount(Trigger.old, null);
  }

  public override void afterUndelete() {
    ResourceOrderService.rollupResourceOrdersToAccount(Trigger.new, null);
  }
}