public with sharing class AddressService {
  
  public static void setAddressOnAccount(List<npsp__Address__c> addresses, Map<Id, npsp__Address__c> oldMap) {
    Map<Id, Account> accountMap = new Map<Id, Account>();
    for (npsp__Address__c a : addresses){
      npsp__Address__c old = oldMap != null && oldMap.containsKey(a.Id) ? oldMap.get(a.Id) : null;
      // If a new address record is added update the account record
      if (old == null){
        Account acct = new Account();
        acct.Id = a.npsp__Household_Account__c;
        acct.Address__c = null;
        accountMap.put(acct.Id, acct);
      } 
      // If an old address record is changed update the account record
      else if (old != null && 
        (a.npsp__Default_Address__c != old.npsp__Default_Address__c || 
        a.npsp__Household_Account__c != old.npsp__Household_Account__c)
      ){
        Account acct = new Account();
        acct.Id = a.npsp__Household_Account__c;
        acct.Address__c = null;
        accountMap.put(acct.Id, acct);
        if (a.npsp__Household_Account__c != old.npsp__Household_Account__c){
          Account oldAcct = new Account();
          oldAcct.Id = old.npsp__Household_Account__c;
          oldAcct.Address__c = null;
          accountMap.put(oldAcct.Id, oldAcct);
        }
      }
    }
    System.debug(accountMap);
    if (!accountMap.isEmpty()){
      for (Account acct : [
        SELECT Id, Address__c,
          (SELECT Id FROM npsp__Addresses__r 
          WHERE npsp__Default_Address__c = true
          ORDER BY CreatedDate DESC LIMIT 1)
        FROM Account WHERE Id IN :accountMap.keySet()
      ]){
        System.debug(acct.npsp__Addresses__r);
        if (!acct.npsp__Addresses__r.isEmpty()){
          Account temp = accountMap.get(acct.Id);
          temp.Address__c = acct.npsp__Addresses__r[0].Id;
        }
      }
      if (!accountMap.isEmpty()){
        update accountMap.values();
      }
    }
  }
}