public without sharing class UserTriggerHandler extends TriggerHandler {
  public override void afterInsert() {
    UserService.setCommunityUserLookupOnContact(Trigger.new, null);
  }

  public override void afterUpdate() {
    UserService.setCommunityUserLookupOnContact(Trigger.new, (Map<Id, User>) Trigger.oldMap);
  }
}