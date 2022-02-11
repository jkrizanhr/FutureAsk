public class ResultTriggerHandler extends TriggerHandler {
  
  public override void afterInsert() {
    ResultService.resultSnapshotRollup(Trigger.new);
  }
  public override void afterDelete() {
    ResultService.resultSnapshotRollup(Trigger.old);
  }
  public override void afterUndelete() {
    ResultService.resultSnapshotRollup(Trigger.new);
  }     
}