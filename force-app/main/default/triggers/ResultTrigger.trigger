trigger ResultTrigger on DS360oi__DonorSearch_del_del__c(
  before insert,
  after insert,
  before update,
  after update,
  before delete,
  after delete,
  after undelete
) {
  new ResultTriggerHandler().run();
}