trigger TriggerHandlerTrigger on npsp__Trigger_Handler__c(before insert, before update) {
  new TriggerHandlerTriggerHandler().run();
}