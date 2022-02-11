trigger CountryTrigger on Country__c(
  before insert,
  after insert,
  before update,
  after update,
  before delete,
  after delete,
  after undelete
) {
  new CountryTriggerHandler().run();
}