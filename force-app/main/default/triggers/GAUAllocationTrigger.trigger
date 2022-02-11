trigger GAUAllocationTrigger on npsp__Allocation__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new GAUAllocationTriggerHandler().run();
}