trigger GeneralAccountingUnitTrigger on npsp__General_Accounting_Unit__c (
  before insert,
  after insert,
  before update,
  after update,
  before delete,
  after delete,
  after undelete
) {
  new GeneralAccountingUnitTriggerHandler().run();
}