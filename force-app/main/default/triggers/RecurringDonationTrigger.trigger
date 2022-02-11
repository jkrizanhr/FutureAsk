trigger RecurringDonationTrigger on npe03__Recurring_Donation__c (
  before insert,
  after insert,
  before update,
  after update,
  before delete,
  after delete,
  after undelete
) {
  new RecurringDonationTriggerHandler().run();
}