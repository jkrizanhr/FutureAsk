public without sharing class FutureGiftAllocationTriggerHandler extends TriggerHandler {
  public override void beforeInsert() {
    FutureGiftAllocationService.allocationAmountNotToExceedFutureGift(Trigger.new, null);
  }
  public override void beforeUpdate(){
    FutureGiftAllocationService.allocationAmountNotToExceedFutureGift(Trigger.new, (Map<Id, Future_Gift_Allocation__c>)Trigger.oldMap);
  }
  
  
 public override void afterInsert(){ 
 //this method is added to the class in order to keep the code simplier in calculating remaining balance to be raised on a project jkrizan 2-4-22
     FutureGiftAllocationService.calcprojectsum();
 }   
 
    public override void afterUpdate(){ 
 
     FutureGiftAllocationService.calcprojectsum();
 }   
 
 
}//ends class