public class RecurringDonationTriggerHandler extends TriggerHandler {
    
  public override void beforeInsert() {
    Utils.setUserRegion(Trigger.new, 'Region_Category__c');
  }
  public override void afterInsert() {
    RecurringDonationService.recurringDonationSustainerRollup(Trigger.new, null);
  }
  public override void afterUpdate() {
    RecurringDonationService.recurringDonationSustainerRollup(Trigger.new, (Map<Id, npe03__Recurring_Donation__c>) Trigger.oldMap);
  }
  public override void afterDelete() {
    RecurringDonationService.recurringDonationSustainerRollup(Trigger.old, null);
  }
  public override void afterUndelete() {
    RecurringDonationService.recurringDonationSustainerRollup(Trigger.new, null);
  }

}