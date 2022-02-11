public without sharing class OverheadHistoryTriggerHandler extends TriggerHandler {
  public override void afterInsert() {
    OverheadHistoryService.copyOverheadPercentageToGAU(Trigger.new);
  }
}