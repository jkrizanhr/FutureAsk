public without sharing class ResourceOrderItemService {
    
  public static void rollupResourceOrderLineItems(List<Resource_Order_Item__c> roiList, Map<Id, Resource_Order_Item__c> oldMap) {
    Map<Id, Resource_Order__c> ordersToUpdate = new Map<Id, Resource_Order__c>();

    for (Resource_Order_Item__c roi : roiList){
      Resource_Order_Item__c old = oldMap != null ? oldMap.get(roi.Id) : null;

      if (old == null || (old != null && (
        (roi.Amount__c != old.Amount__c) || 
        (roi.Resource__c != old.Resource__c) || 
        ((roi.Status__c != old.Status__c) && (roi.Status__c == 'Cancelled' || old.Status__c == 'Cancelled')) ||
        (roi.Resource_Order__c != old.Resource_Order__c) ||
        (roi.Quantity__c != old.Quantity__c)))
      ){
        if (roi.Resource_Order__c != null){
          Resource_Order__c ro = new Resource_Order__c(
            Id = roi.Resource_Order__c,
            Resource_Order_Total__c = 0,
            Total_Order_Quanity__c = 0
          );  
          ordersToUpdate.put(roi.Resource_Order__c, ro);
        }
        if (old != null && old.Resource_Order__c != null && old.Resource_Order__c != roi.Resource_Order__c){
          Resource_Order__c ro = new Resource_Order__c(
            Id = old.Resource_Order__c,
            Resource_Order_Total__c = 0,
            Total_Order_Quanity__c = 0
          );  
          ordersToUpdate.put(old.Resource_Order__c, ro);
        }
      }
    }
    if (!ordersToUpdate.isEmpty()){
      projectRollups(ordersToUpdate.keySet(), new Map<Id, Project__c>());
      resourceOrderRollups(ordersToUpdate);
    }
  }

  // Used in RollupResourceOrderLineItems to calculate the rollups on an LMP Project
  public static void projectRollups(Set<Id> resourceOrders, Map<Id, Project__c> projectsToUpdate){
    
    // Get the Projects that are stored on the Resource Order
    if (!resourceOrders.isEmpty()){
      for (Resource_Order__c ro : [SELECT Id, LMP_Project__c FROM Resource_Order__c WHERE Id IN :resourceOrders]){
        if (ro.LMP_Project__c != null){
          Project__c proj = new Project__c(
            Id = ro.LMP_Project__c,
            Print_Reach__c = 0
          );  
          projectsToUpdate.put(ro.LMP_Project__c, proj);
        }
      }
    }

    Set<String> printResources = new Set<String>{'Paperback', 'Leather', 'Hardback', 'Softcover', 'Vinyl', 'PU Cover', 'Booklet', 'PU', 'Flexicover', 'Flexiback', 'Print'};

    // Update the Print Reach rollup on Project
    if (!projectsToUpdate.isEmpty()){
      for (AggregateResult ar : [SELECT SUM(Quantity__c) qty, Resource_Order__r.LMP_Project__c proj
                                  FROM Resource_Order_Item__c
                                  WHERE Resource_Order__r.LMP_Project__c IN :projectsToUpdate.keySet() 
                                    AND Status__c != 'Cancelled' 
                                    AND Quantity__c != null
                                    AND Resource__r.Media_Type__c IN :printResources
                                  GROUP BY Resource_Order__r.LMP_Project__c
      ]){
        Id projId = String.valueOf(ar.get('proj'));
        if (projId != null){
          Project__c proj = projectsToUpdate.get(projId);
          proj.Print_Reach__c = Double.valueOf(ar.get('qty'));
        }
      }
      if (!projectsToUpdate.isEmpty()){
        update projectsToUpdate.values();
      }
    }
  }

  // Used in RollupResourceOrderLineItems to calculate the rollups on a Resource Order
  public static void resourceOrderRollups(Map<Id, Resource_Order__c> ordersToUpdate){
    if (!ordersToUpdate.isEmpty()){
      for (AggregateResult ar : [SELECT SUM(Amount__c) amt, SUM(Quantity__c) qty, Resource_Order__c
                                  FROM Resource_Order_Item__c
                                  WHERE Resource_Order__c IN :ordersToUpdate.keySet() AND Status__c != 'Cancelled' AND Amount__c != null
                                  GROUP BY Resource_Order__c
      ]){
        Id roId = String.valueOf(ar.get('Resource_Order__c'));
        if (roId != null){
          Resource_Order__c ro = ordersToUpdate.get(roId);
          ro.Resource_Order_Total__c = Double.valueOf(ar.get('amt'));
          ro.Total_Order_Quanity__c = Double.valueOf(ar.get('qty'));
        }
      }
      if (!ordersToUpdate.isEmpty()){
        update ordersToUpdate.values();
      }
    }
  }

  // before insert and update 
  // check if Same Address as Account is set, if so copy the address
  public static void copyShippingAddressFromAccount(List<Resource_Order_Item__c> itemList, Map<Id, Resource_Order_Item__c> oldMap) {
    Set<Id> resourceOrderIds = new Set<Id>();
    List<Resource_Order_Item__c> itemsToUpdate = new List<Resource_Order_Item__c>();
    for (Resource_Order_Item__c item : itemList) {
      // before insert check
      if (oldMap == null) {
        if (item.Same_Address_as_Account__c == true) {
          resourceOrderIds.add(item.Resource_Order__c);
          itemsToUpdate.add(item);
        } 
      } 
      // before update check
      else {
        Resource_Order_Item__c oldItem = oldMap.get(item.Id);
        if (oldItem != null && oldItem.Same_Address_as_Account__c == false && item.Same_Address_as_Account__c == true) {
          resourceOrderIds.add(item.Resource_Order__c);
          itemsToUpdate.add(item);
        }
      }
    }
    // only run query if necessary
    if (!resourceOrderIds.isEmpty()) {
      // query our Resource_Order__c's because the Order Item Id's don't exist yet on before insert
      Map<Id, Resource_Order__c> resourceOrderMap = new Map<Id, Resource_Order__c>();
      List<Resource_Order__c> resourceOrderList = [
        SELECT 
          Id, 
          Account__r.ShippingStreet, 
          Account__r.ShippingCity, 
          Account__r.ShippingState, 
          Account__r.ShippingPostalCode, 
          Account__r.ShippingCountry 
        FROM Resource_Order__c 
        WHERE Id IN :resourceOrderIds
      ];
      for (Resource_Order__c order : resourceOrderList) {
        resourceOrderMap.put(order.Id, order);
      }
      if (resourceOrderMap != null) {
        // update address fields
        for (Resource_Order_Item__c item : itemsToUpdate) {
          Resource_Order__c order = resourceOrderMap.get(item.Resource_Order__c);
          if (item.Resource_Order__c != null && order != null) {
            if (order.Account__c != null) {
              item.Street_Address__c = order.Account__r.ShippingStreet;
              item.City__c = order.Account__r.ShippingCity;
              item.State_Province__c = order.Account__r.ShippingState;
              item.Postal_Code__c = order.Account__r.ShippingPostalCode;
              item.Country__c = order.Account__r.ShippingCountry;
            }
          }
        }
      }
    }
  }
}