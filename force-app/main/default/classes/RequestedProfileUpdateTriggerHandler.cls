public without sharing class RequestedProfileUpdateTriggerHandler extends TriggerHandler {

  public override void afterUpdate() {
    RequestedProfileUpdateService.approveRequestedProfileUpdate(
      Trigger.new, (Map<Id, Requested_Profile_Update__c>)Trigger.oldMap
    );
    RequestedProfileUpdateService.autoApproveBlankFields(
      (Map<Id, Requested_Profile_Update__c>)Trigger.newMap, (Map<Id, Requested_Profile_Update__c>)Trigger.oldMap
    );
    RequestedProfileUpdateService.createNotificationWhenProfileChanges(
      (Map<Id, Requested_Profile_Update__c>)Trigger.newMap, (Map<Id, Requested_Profile_Update__c>)Trigger.oldMap
    );
  }
}