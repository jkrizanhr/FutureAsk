public inherited sharing class HouseholdGreetingsService {
  public static void updateNamingOrder(List<AggregateResult> results) {
    Set<Id> accountIds = new Set<Id>();
    for (AggregateResult ar : results) {
      accountIds.add((Id) ar.get('AccountId'));
    }
    updateNamingOrder(accountIds);
  }

  public static void updateNamingOrder(Set<Id> accountIds) {
    Map<String, List<Contact>> contactsInHouseholdsMap = getContactMapping(
      accountIds
    );

    List<Contact> sortedCons = new List<Contact>();
    for (List<Contact> cons : contactsInHouseholdsMap.values()) {
      cons = assignNamingOrder(cons);
      cons = assignFormalGreetingOrder(cons);
      sortedCons.addAll(cons);
    }

    if (!sortedCons.isEmpty()) {
      Database.DMLOptions dmlOptions = new Database.DMLOptions();
      dmlOptions.DuplicateRuleHeader.allowSave = true;
      dmlOptions.DuplicateRuleHeader.runAsCurrentUser = true;
      dmlOptions.OptAllOrNone = true;
      Database.update(sortedCons, dmlOptions);
    }
  }

  private static Boolean isSameLastName(List<Contact> cons) {
    String lastName = null;
    for (Contact con : cons) {
      if (lastName == null) {
        lastName = con.LastName;
      } else if (con.LastName != lastName) {
        return false;
      }
    }
    return true;
  }

  public static List<Contact> assignNamingOrder(List<Contact> cons) {
    List<HouseholdGreetingContactWrapper> consWrapped = new List<HouseholdGreetingContactWrapper>();
    for (Contact con : cons) {
      HouseholdGreetingContactWrapper conWrapped = new HouseholdGreetingContactWrapper(
        con
      );
      consWrapped.add(conWrapped);
    }
    consWrapped.sort();

    List<Contact> results = new List<Contact>();
    for (Integer i = 0; i < consWrapped.size(); i++) {
      Contact con = consWrapped[i].con;
      con.npo02__Household_Naming_Order__c = i;
      results.add(con);
    }
    return results;
  }

  public static List<Contact> assignFormalGreetingOrder(List<Contact> cons) {
    List<HouseholdGreetingContactWrapper> consWrapped = new List<HouseholdGreetingContactWrapper>();
    for (Contact con : cons) {
      HouseholdGreetingContactWrapper conWrapped = new HouseholdGreetingContactWrapper(
        con
      );
      consWrapped.add(conWrapped);
    }
    consWrapped.sort();

    List<Contact> results = new List<Contact>();
    if (isSameLastName(cons)) {
      // when the husband and wife have different last names, we want the reverse order
      Integer j = 0;
      for (Integer i = consWrapped.size(); i-- > 0;) {
        Contact con = consWrapped[i].con;
        con.NPSP_Formal_Greeting_Order__c = j;
        results.add(con);
        j++;
      }
    } else {
      // when same last name, we want the normal order
      for (Integer i = 0; i < consWrapped.size(); i++) {
        Contact con = consWrapped[i].con;
        con.NPSP_Formal_Greeting_Order__c = i;
        results.add(con);
      }
    }
    return results;
  }

  public static Map<String, List<Contact>> getContactMapping(
    Set<Id> accountIds
  ) {
    List<Contact> cons = [
      SELECT Id, FirstName, LastName, AccountId, Gender__c, Salutation
      FROM Contact
      WHERE AccountId IN :accountIds
      ORDER BY npo02__Household_Naming_Order__c ASC
    ];
    Map<String, List<Contact>> contactsInHouseholdsMap = new Map<String, List<Contact>>();
    for (Contact con : cons) {
      List<Contact> temp = new List<Contact>();
      if (contactsInHouseholdsMap.containsKey(con.AccountId)) {
        temp = contactsInHouseholdsMap.get(con.AccountId);
        temp.add(con);
        contactsInHouseholdsMap.put(con.AccountId, temp);
      } else {
        temp.add(con);
        contactsInHouseholdsMap.put(con.AccountId, temp);
      }
    }
    return contactsInHouseholdsMap;
  }
}