public class TaskTriggerHandler extends TriggerHandler {

  public override void beforeInsert() {
    TaskService.setStageOnTask(Trigger.new);
  }
}