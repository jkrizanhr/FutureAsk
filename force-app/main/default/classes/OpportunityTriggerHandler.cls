public class OpportunityTriggerHandler extends TriggerHandler {
  public override void beforeInsert() {
    Utils.setUserRegion(Trigger.new, 'Region_Category__c');
    OpportunityService.handleCurrencyConversion(Trigger.new);
    OpportunityService.ensureBatchIsEditable(Trigger.new, null);
    OpportunityService.batchIncomingDonationsHandler(Trigger.new);
  }
  public override void afterInsert() {
    OpportunityService.createOpportuntityContactRolesFromFutureGift(Trigger.new);
    OpportunityService.assignAccountSoftCredits(Trigger.new);
    OpportunityService.rollupBatchedOpps(Trigger.new, null);
    OpportunityService.futureGiftRollups(Trigger.new, null);
  }
  public override void beforeUpdate() {
    OpportunityService.handleCurrencyConversionBeforeUpdate(Trigger.new,(Map<Id, Opportunity>) Trigger.oldMap);
    OpportunityService.ensureBatchIsEditable(Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
    OpportunityService.batchIncomingDonationsHandler(Trigger.new);
    OpportunityService.updateAmountOnSoftCredit(Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
  }
  public override void afterUpdate() {
    OpportunityService.rollupBatchedOpps(Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
    OpportunityService.futureGiftRollups(Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
  }
  public override void beforeDelete() {
    OpportunityService.ensureBatchIsEditable(Trigger.old, null);
  }
  public override void afterDelete() {
    OpportunityService.rollupBatchedOpps(Trigger.old, null);
    OpportunityService.futureGiftRollups(Trigger.old, null);
  }
  public override void afterUndelete() {
    OpportunityService.ensureBatchIsEditable(Trigger.new, null);
    OpportunityService.rollupBatchedOpps(Trigger.new, null);
    OpportunityService.futureGiftRollups(Trigger.new, null);
  }
}