trigger ResourceOrderTrigger on Resource_Order__c(
  before insert,
  after insert,
  before update,
  after update,
  before delete,
  after delete,
  after undelete
) {
  new ResourceOrderTriggerHandler().run();
}