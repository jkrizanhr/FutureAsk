@isTest
private class HouseholdGreetingContactWrapperTest {
  @isTest
  static void testContactSort() {
    // Add the contact wrapper objects to a list.
    HouseholdGreetingContactWrapper[] conList = new List<HouseholdGreetingContactWrapper>();
    Date closeDate = Date.today().addDays(10);
    conList.add(
      new HouseholdGreetingContactWrapper(
        new Contact(LastName = 'Edge Installation', Gender__c = 'Male')
      )
    );
    conList.add(
      new HouseholdGreetingContactWrapper(
        new Contact(LastName = 'United Oil Installations', Gender__c = 'Female')
      )
    );
    conList.add(
      new HouseholdGreetingContactWrapper(
        new Contact(LastName = 'Grand Hotels SLA', Gender__c = 'Male')
      )
    );

    conList.sort();
    System.debug(conList);

    // Verify the sort order
    System.assertEquals('United Oil Installations', conList[0].con.LastName);
    System.assertEquals('Female', conList[0].con.Gender__c);
    System.assertEquals('Male', conList[1].con.Gender__c);
    System.assertEquals('Male', conList[2].con.Gender__c);
  }

  @isTest
  static void testContactSortSalutations() {
    // Add the contact wrapper objects to a list.
    HouseholdGreetingContactWrapper[] conList = new List<HouseholdGreetingContactWrapper>();
    Date closeDate = Date.today().addDays(10);
    conList.add(
      new HouseholdGreetingContactWrapper(
        new Contact(LastName = 'Edge Installation', Salutation = 'Mr.')
      )
    );
    conList.add(
      new HouseholdGreetingContactWrapper(
        new Contact(LastName = 'Grand Hotels SLA', Salutation = 'Mr.')
      )
    );
    conList.add(
      new HouseholdGreetingContactWrapper(
        new Contact(LastName = 'United Oil Installations', Salutation = 'Ms.')
      )
    );

    conList.sort();
    System.debug(conList);

    // Verify the sort order
    System.assertEquals('United Oil Installations', conList[0].con.LastName);
    System.assertEquals('Ms.', conList[0].con.Salutation);
    System.assertEquals('Mr.', conList[1].con.Salutation);
    System.assertEquals('Mr.', conList[2].con.Salutation);
  }
}