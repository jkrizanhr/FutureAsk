public without sharing class ContactTriggerHandler extends TriggerHandler {
  public override void beforeInsert() {
    Utils.setUserRegion(Trigger.new, 'Region_Category__c');
  }

  public override void afterInsert() {
    ContactService.rollupDeceasedContactsToHousehold((Contact[]) Trigger.new, null);
    new ContactRecalculateNamingOrder((Map<Id, Contact>) Trigger.newMap, null).run();
  }

  public override void afterUpdate() {
    ContactService.rollupDeceasedContactsToHousehold(
      (Contact[]) Trigger.new,
      (Map<Id, Contact>) Trigger.oldMap
    );
    new ContactRecalculateNamingOrder(
        (Map<Id, Contact>) Trigger.newMap,
        (Map<Id, Contact>) Trigger.oldMap
      )
      .run();
  }

  public override void afterDelete() {
    ContactService.rollupDeceasedContactsToHousehold((Contact[]) Trigger.old, null);
  }

  public override void afterUndelete() {
    ContactService.rollupDeceasedContactsToHousehold((Contact[]) Trigger.new, null);
    new ContactRecalculateNamingOrder((Map<Id, Contact>) Trigger.newMap, null).run();
  }
}