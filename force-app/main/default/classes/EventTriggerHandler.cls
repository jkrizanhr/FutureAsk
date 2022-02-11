public class EventTriggerHandler extends TriggerHandler {

  public override void beforeInsert() {
    EventService.setStageOnEvent(Trigger.new);
  }
}