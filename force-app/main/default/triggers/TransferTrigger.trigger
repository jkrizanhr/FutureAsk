trigger TransferTrigger on Transfer__c(
  before insert,
  after insert,
  after update
) {
  new TransferTriggerHandler().run();
}