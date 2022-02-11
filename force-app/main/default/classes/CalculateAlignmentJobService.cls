public without sharing class CalculateAlignmentJobService {
    
  public static void calculateAlignmentRollups(List<Account> acctList) {
    List<Account> acctsToUpdate = new List<Account>();
    
    for (Account acct : acctList){
      Double numOfQuantity = 0;
      Double numOfOrders = 0;
      Double numOfMPP = 0;
      Double numOfTPP = 0;

      if (!acct.Project_Partners__r.isEmpty()){
        for (Project_Partner__c pp : acct.Project_Partners__r){
          if (pp.Project__r.RecordType.Name == 'Language Ministry Project'){
            numOfMPP++;
          } else if (pp.Project__r.RecordType.Name == 'Language Translation Plan'){
            numOfTPP++;
          }
        } 
      }
      if (!acct.Resource_Orders__r.isEmpty()){
        for (Resource_Order__c ro : acct.Resource_Orders__r){
          numOfQuantity = ro.Total_Order_Quanity__c != null ? numOfQuantity + ro.Total_Order_Quanity__c : numOfQuantity;
          numOfOrders++;
        } 
      }

      if (numOfMPP != acct.Number_of_MPP_Projects__c || numOfTPP != acct.Number_of_TPP_Projects__c || numOfQuantity != acct.Number_of_Resource_Item_Quantity__c || numOfOrders != acct.Number_of_Resource_Orders__c){
        Account newAcct = new Account(
          Id = acct.Id,
          Number_of_Resource_Item_Quantity__c = numOfQuantity,
          Number_of_Resource_Orders__c = numOfOrders,
          Number_of_MPP_Projects__c = numOfMPP,
          Number_of_TPP_Projects__c = numOfTPP
        );
        acctsToUpdate.add(newAcct);
      }
    }
    if (!acctsToUpdate.isEmpty()){
      update acctsToUpdate;
    }
  }
}