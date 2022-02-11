public class TriggerHandlerService {
  public static void changeAllocationTrigger(List<npsp__Trigger_Handler__c> triggers) {
    for (npsp__Trigger_Handler__c th : triggers) {
      if (th.npsp__Object__c == 'Allocation__c' && th.npsp__Class__c == 'ALLO_Allocations_TDTM') {
        List<String> triggerActions = th.npsp__Trigger_Action__c.split(';');
        if (triggerActions.contains('BeforeInsert')) {
          triggerActions.remove(triggerActions.indexOf('BeforeInsert'));
        }
        if (triggerActions.contains('BeforeUpdate')) {
          triggerActions.remove(triggerActions.indexOf('BeforeUpdate'));
        }
        System.debug(triggerActions);
        th.npsp__Trigger_Action__c = String.join(triggerActions, ';');
      }
    }
  }
}