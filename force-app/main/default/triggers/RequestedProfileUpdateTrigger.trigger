trigger RequestedProfileUpdateTrigger on Requested_Profile_Update__c (
  after update
) {
  new RequestedProfileUpdateTriggerHandler().run();
}