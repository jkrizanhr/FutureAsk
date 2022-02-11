/**
 * @description This class contains all trigger logic related to Contacts.
 */
public without sharing class ContactService {
  /**
   * @description This method gets called on any Contact DML operation and handles rolling up the
   * number of deceased Contacts to any Account related to the triggering Contact records.
   * @param contacts Trigger.new
   * @param oldMap Trigger.oldMap
   */
  public static void rollupDeceasedContactsToHousehold(
    List<Contact> contacts,
    Map<Id, Contact> oldMap
  ) {
    Set<Id> accIds = new Set<Id>();

    // Gather all of the Accounts impacted by the triggered Contacts.
    for (Contact c : contacts) {
      accIds.add(c.AccountId);

      if (oldMap?.get(c.Id) != null) {
        accIds.add(oldMap.get(c.Id).AccountId);
      }
    }

    if (!accIds.isEmpty()) {
      List<Account> accounts = [
        SELECT
          Id,
          Number_of_Deceased_Members__c,
          (SELECT Id, npsp__Deceased__c FROM Contacts)
        FROM Account
        WHERE Id IN :accIds
      ];

      // Count the number of deceased Contacts for each Account and save the result on the Account.
      for (Account a : accounts) {
        Integer numberDeceased = 0;

        for (Contact c : a.Contacts) {
          if (c.npsp__Deceased__c == true) {
            numberDeceased++;
          }
        }

        a.Number_of_Deceased_Members__c = numberDeceased;
      }
      update accounts;
    }
  }
}