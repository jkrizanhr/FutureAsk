public inherited sharing class ResultService {

  public static void resultSnapshotRollup(List<DS360oi__DonorSearch_del_del__c> snapshots){
    Set<Id> contactIds = new Set<Id>();

    for (DS360oi__DonorSearch_del_del__c snapshot : snapshots){
      if (snapshot.DS360oi__ID__c != null){
        contactIds.add(snapshot.DS360oi__ID__c);
      }
    }

    if (!contactIds.isEmpty()){
      Map<Id, Account> accountMap = new Map<Id, Account>();
      for (Contact con : [SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds]){
        Account acct = new Account(
          Id = con.AccountId,
          DS_Rating__c = null,
          Estimated_Capacity__c = null,
          Target_Ask_Based_on_Giving__c = null,
          Target_Ask_Based_on_Wealth__c = null,
          Annual_Fund_Likelihood__c = null,
          Major_Gift_Likelihood__c = null,
          Quality_Score__c = null,
          Profile__c = null,
          DS_Last_Updated_Date__c = null
        );
        accountMap.put(con.AccountId, acct);
      }

      Map<Id, List<DS360oi__DonorSearch_del_del__c>> snapshotMap = new Map<Id, List<DS360oi__DonorSearch_del_del__c>>();

      if (!accountMap.isEmpty()){
        for (Contact con : [
          SELECT Id, AccountId, 
            (SELECT DS360oi__ID__r.AccountId, CreatedDate, DS360oi__DS_Rating__c, DS360oi__Wealth_Score__c, DS360oi__Capacity_Range_Based_on_Wealth__c, DS360oi__Wealth_Capacity_Range__c, DS360oi__Annual_Fund_Likelihood__c, DS360oi__Major_Gift_Likelihood__c, DS360oi__Quality_Score__c, DS360oi__Profile__c
            FROM DS360oi__DonorSearch__r
            ORDER BY CreatedDate DESC LIMIT 1)
          FROM Contact
          WHERE AccountId IN :accountMap.keySet()]
        ){
          List<DS360oi__DonorSearch_del_del__c> temp = snapshotMap.get(con.AccountId) != null ? snapshotMap.get(con.AccountId) : new List<DS360oi__DonorSearch_del_del__c>();
          if (!con.DS360oi__DonorSearch__r.isEmpty()){
            temp.addAll(con.DS360oi__DonorSearch__r);
          }
          snapshotMap.put(con.AccountId, temp);
        }

          
        if (!snapshotMap.isEmpty()){
          for (Id acctId : snapshotMap.keySet()){
            List<DS360oi__DonorSearch_del_del__c> tempList = snapshotMap.get(acctId);
              

            if (!tempList.isEmpty()){
              DS360oi__DonorSearch_del_del__c newest = tempList[0];
              for (Integer i = 1; i < tempList.size(); i++){
                if (tempList[i].CreatedDate > newest.CreatedDate){
                  newest = tempList[i];
                }
              }


              Account acct = accountMap.get(acctId);
              acct.DS_Rating__c = newest.DS360oi__DS_Rating__c;
              acct.Estimated_Capacity__c = newest.DS360oi__Wealth_Score__c;
              acct.Target_Ask_Based_on_Giving__c = newest.DS360oi__Capacity_Range_Based_on_Wealth__c;
              acct.Target_Ask_Based_on_Wealth__c = newest.DS360oi__Wealth_Capacity_Range__c;
              acct.Annual_Fund_Likelihood__c = newest.DS360oi__Annual_Fund_Likelihood__c;
              acct.Major_Gift_Likelihood__c = newest.DS360oi__Major_Gift_Likelihood__c;
              acct.Quality_Score__c = newest.DS360oi__Quality_Score__c;
              acct.Profile__c = newest.DS360oi__Profile__c;
              acct.DS_Last_Updated_Date__c = Datetime.now();
              accountMap.put(acctId, acct);
            }
          }
        }

        update accountMap.values();
      }
    }
  }
}