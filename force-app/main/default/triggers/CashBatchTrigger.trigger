trigger CashBatchTrigger on Cash_Batch__C(before insert, after insert, before update, after update, before delete) {
  new CashBatchTriggerHandler().run();
}