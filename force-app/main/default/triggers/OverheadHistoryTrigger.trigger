trigger OverheadHistoryTrigger on Overhead_History__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new OverheadHistoryTriggerHandler().run();
  new SupremeFieldHistoryService().run();
}