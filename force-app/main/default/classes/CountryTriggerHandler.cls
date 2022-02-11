public class CountryTriggerHandler extends TriggerHandler {
  
  public override void afterInsert() {
    CountryService.countryRollupToProject(Trigger.new, null);    
  }
  public override void afterUpdate() {
    CountryService.countryRollupToProject(Trigger.new, (Map<Id, Country__c>) Trigger.oldMap);   
  }
  public override void afterDelete() {
    CountryService.countryRollupToProject(Trigger.old, null);   
  }
  public override void afterUndelete() {
    CountryService.countryRollupToProject(Trigger.new, null);
  }
}