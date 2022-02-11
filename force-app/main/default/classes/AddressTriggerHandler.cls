public class AddressTriggerHandler extends TriggerHandler {
  
  public override void afterInsert() {
    AddressService.setAddressOnAccount(Trigger.new, null);
  }
  public override void afterUpdate() {
    AddressService.setAddressOnAccount(Trigger.new, (Map<Id, npsp__Address__c>) Trigger.oldMap);
  }
}