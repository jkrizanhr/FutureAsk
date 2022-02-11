trigger ResourceOrderItemTrigger on Resource_Order_Item__c (
  before insert,
  after insert,
  before update,
  after update,
  before delete,
  after delete,
  after undelete
) {
  new ResourceOrderItemTriggerHandler().run();
}