trigger ProjectPartnerTrigger on Project_Partner__c (
  before insert,
  after insert,
  before update,
  after update,
  before delete,
  after delete,
  after undelete
) {
  new ProjectPartnerTriggerHandler().run();
}