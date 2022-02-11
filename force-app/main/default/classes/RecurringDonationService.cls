public inherited sharing class RecurringDonationService {
    
  public static void recurringDonationSustainerRollup(List<npe03__Recurring_Donation__c> donations, Map<Id, npe03__Recurring_Donation__c> oldMap) {
    Set<Id> accountIds = new Set<Id>();
    for (npe03__Recurring_Donation__c rd : donations) {
      if (oldMap != null) {
        npe03__Recurring_Donation__c old = oldMap.get(rd.Id);
        if (
          old != null &&
          ((old.npsp__Status__c != rd.npsp__Status__c) ||
          (old.npe03__Organization__c == rd.npe03__Organization__c))
        ) {
          if (old.npe03__Organization__c != null) {
            accountIds.add(old.npe03__Organization__c);
          }
          if (rd.npe03__Organization__c != null) {
            accountIds.add(rd.npe03__Organization__c);
          }
        }
      } else {
        if (rd.npe03__Organization__c != null) {
          accountIds.add(rd.npe03__Organization__c);
        }
      }
    }

    Map<Id, Account> acctsToUpdate = new Map<Id, Account>();
    for (Account acct : [SELECT Id, Sustainer__c FROM Account WHERE Id IN :accountIds]) {
      Account temp = new Account();
      temp.Id = acct.Id;
      temp.Sustainer__c = false;
      acctsToUpdate.put(acct.Id, temp);
    }

    for (AggregateResult ar : [
      SELECT COUNT(Id) ct, npe03__Organization__c
      FROM npe03__Recurring_Donation__c
      WHERE npe03__Organization__c IN :acctsToUpdate.keySet() AND npsp__Status__c = 'Active'
      GROUP BY npe03__Organization__c
    ]) {
      Id acctId = String.valueOf(ar.get('npe03__Organization__c'));
      if (acctId != null) {
        Account acct = acctsToUpdate.get(acctId);
        acct.Sustainer__c = true;
      }
    }
    if (!acctsToUpdate.isEmpty()) {
      update acctsToUpdate.values();
    }
  }
}