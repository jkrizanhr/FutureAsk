public inherited sharing class ContactRecalculateNamingOrder {
  private Map<Id, Contact> newMap;
  private Map<Id, Contact> oldMap;

  public ContactRecalculateNamingOrder(Map<Id, Contact> newMap, Map<Id, Contact> oldMap) {
    this.newMap = newMap;
    this.oldMap = oldMap;
  }

  public void run() {
    Set<Id> accountIds = new Set<Id>();

    for (Contact con : this.newMap.values()) {
      Contact oldCon = this.oldMap != null ? this.oldMap.get(con.Id) : null;
      if (
        oldCon == null ||
        (oldCon != null &&
        (con.Salutation != oldCon.Salutation ||
        con.FirstName != oldCon.FirstName ||
        con.LastName != oldCon.LastName ||
        con.AccountId != oldCon.AccountId ||
        con.Gender__c != oldCon.Gender__c))
      ) {
        accountIds.add(con.AccountId);
        if (oldCon != null) {
          accountIds.add(oldCon.AccountId);
        }
      }
    }

    if (!accountIds.isEmpty()) {
      HouseholdGreetingsService.updateNamingOrder(accountIds);
    }
  }
}