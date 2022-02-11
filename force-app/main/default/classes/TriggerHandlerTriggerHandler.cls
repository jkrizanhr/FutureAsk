public class TriggerHandlerTriggerHandler extends TriggerHandler {
  public override void beforeInsert() {
    TriggerHandlerService.changeAllocationTrigger(Trigger.new);
  }

  public override void beforeUpdate() {
    TriggerHandlerService.changeAllocationTrigger(Trigger.new);
  }
}