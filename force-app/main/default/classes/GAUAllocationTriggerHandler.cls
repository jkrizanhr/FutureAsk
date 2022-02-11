public without sharing class GAUAllocationTriggerHandler extends TriggerHandler {
  public override void beforeInsert() {
    GAUAllocationService.handleCurrencyConversion(Trigger.new);
    GAUAllocationService.copyOverheadPercentageToAllocations(Trigger.new);
    GAUAllocationService.ensureBatchIsEditable(
      Trigger.new,
      (Map<Id, npsp__Allocation__c>) Trigger.oldMap
    );
    GAUAllocationService.setDefaultFundGLAccount(Trigger.new);
    GAUAllocationService.getCampaignFromRecurringDonation(Trigger.new, false);
  }
  public override void afterInsert() {
    GAUAllocationService.taxDeductibleRollupToOpp(Trigger.new, null);
    GAUAllocationService.updateCampaignMembers(Trigger.new);
    GAUAllocationService.copyReceiptMessage(
      Trigger.new,
      (Map<Id, npsp__Allocation__c>) Trigger.oldMap
    );
  }

  public override void beforeUpdate() {
    GAUAllocationService.handleCurrencyConversionBeforeUpdate(
      Trigger.new,
      (Map<Id, npsp__Allocation__c>) Trigger.oldMap
    );
    GAUAllocationService.ensureBatchIsEditable(
      Trigger.new,
      (Map<Id, npsp__Allocation__c>) Trigger.oldMap
    );
    GAUAllocationService.getCampaignFromRecurringDonation(Trigger.new, true);
  }
  public override void afterUpdate() {
    GAUAllocationService.taxDeductibleRollupToOpp(
      Trigger.new,
      (Map<Id, npsp__Allocation__c>) Trigger.oldMap
    );
    GAUAllocationService.updateCampaignMembers(Trigger.new);
    GAUAllocationService.copyReceiptMessage(
      Trigger.new,
      (Map<Id, npsp__Allocation__c>) Trigger.oldMap
    );
  }

  public override void beforeDelete() {
    GAUAllocationService.ensureBatchIsEditable(
      Trigger.old,
      (Map<Id, npsp__Allocation__c>) Trigger.oldMap
    );
  }
  public override void afterDelete() {
    GAUAllocationService.taxDeductibleRollupToOpp(Trigger.old, null);
  }

  public override void afterUndelete() {
    GAUAllocationService.ensureBatchIsEditable(
      Trigger.new,
      (Map<Id, npsp__Allocation__c>) Trigger.oldMap
    );
    GAUAllocationService.taxDeductibleRollupToOpp(Trigger.new, null);
  }
}