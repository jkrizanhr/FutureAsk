trigger FutureGiftAllocationTrigger on Future_Gift_Allocation__c(
  before insert,
  after insert,
  before update,
  after update,
  before delete,
  after delete,
  after undelete
) {
  new FutureGiftAllocationTriggerHandler().run();
}