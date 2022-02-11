public without sharing class ResourceOrderItemTriggerHandler extends TriggerHandler {
     
  public override void beforeInsert() {
    system.debug('beforeInsert');
    ResourceOrderItemService.copyShippingAddressFromAccount(Trigger.new, null);
  }
  public override void afterInsert() {
    ResourceOrderItemService.rollupResourceOrderLineItems(Trigger.new, null);
  }
  public override void beforeUpdate() {
    system.debug('beforeUpdate');
    ResourceOrderItemService.copyShippingAddressFromAccount(Trigger.new, (Map<Id, Resource_Order_Item__c>)Trigger.oldMap);
  }
  public override void afterUpdate() {
    ResourceOrderItemService.rollupResourceOrderLineItems(Trigger.new, (Map<Id, Resource_Order_Item__c>)Trigger.oldMap);
  }
  public override void afterDelete() {
    ResourceOrderItemService.rollupResourceOrderLineItems(Trigger.old, null);
  }
  public override void afterUndelete() {
    ResourceOrderItemService.rollupResourceOrderLineItems(Trigger.new, null);
  }

}