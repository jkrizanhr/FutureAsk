trigger ProjectDeliverableTrigger on Project_Deliverable__c(
  before insert,
  after insert,
  before update,
  after update,
  before delete,
  after delete,
  after undelete
) {
  new ProjectDeliverableTriggerHandler().run();
}