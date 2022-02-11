public without sharing class DigitalResourceOrdersCtrl {   
  @AuraEnabled
  public static Account fetchData(Id recordId) {
    return [
      SELECT Id, Primary_Partnership_Manager__c, npe01__One2OneContact__c, Short_Name__c 
      FROM Account 
      WHERE Id = :recordId 
      LIMIT 1
    ];
  }
  @AuraEnabled
  public static void deleteResourceOrderItem(Id roiId){
    delete [SELECT Id FROM Resource_Order_Item__c WHERE Id = :roiId];
  }
  
  @AuraEnabled
  public static void deleteResourceOrder(Id roId){
    delete [SELECT Id, Resource_Order__c FROM Resource_Order_Item__c WHERE Resource_Order__c = :roId];
    delete [SELECT Id FROM Resource_Order__c WHERE Id = :roId];
  }
}