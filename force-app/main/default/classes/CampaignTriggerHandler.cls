public class CampaignTriggerHandler extends TriggerHandler {
  
  public override void beforeInsert() {
    Utils.setUserRegion(Trigger.new, 'Region_Category__c');
  }
}