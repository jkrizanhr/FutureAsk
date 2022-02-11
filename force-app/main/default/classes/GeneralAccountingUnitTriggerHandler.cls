public class GeneralAccountingUnitTriggerHandler extends TriggerHandler {
  
  public override void beforeInsert() {
    Utils.setUserRegion(Trigger.new, 'Region_Category__c');
  }
  public override void afterInsert() {
    GeneralAccountingUnitService.setGauLookupOnProject(Trigger.new, null);
  }
  public override void afterUpdate() {
    GeneralAccountingUnitService.setGauLookupOnProject(Trigger.new, (Map<Id, npsp__General_Accounting_Unit__c>) Trigger.oldMap);
  }
  public override void afterUndelete() {
    GeneralAccountingUnitService.setGauLookupOnProject(Trigger.new, null);
  }
}