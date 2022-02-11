public inherited sharing class HouseholdGreetingContactWrapper implements Comparable {
  public Contact con;

  public HouseholdGreetingContactWrapper(Contact con) {
    this.con = con;
  }

  // Compare opportunities based on the Contact Gender.
  public Integer compareTo(Object compareTo) {
    HouseholdGreetingContactWrapper compareToCon = (HouseholdGreetingContactWrapper) compareTo;
    Set<String> isFemale = new Set<String>{ 'Mrs.', 'Ms.', 'Miss' };

    // The return value of 0 indicates that both elements are equal.
    Integer returnValue = 0;
    if (con.FirstName == null && compareToCon.con.FirstName <> null) {
      returnValue = 1;
    } else if (con.Gender__c == 'Female' && compareToCon.con.Gender__c != 'Female') {
      returnValue = -1;
    } else if (
      isFemale.contains(con.Salutation) && !(isFemale.contains(compareToCon.con.Salutation))
    ) {
      returnValue = -1;
    } else if (con.Gender__c != 'Female' && compareToCon.con.Gender__c == 'Female') {
      returnValue = 1;
    } else if (
      !isFemale.contains(con.Salutation) && isFemale.contains(compareToCon.con.Salutation)
    ) {
      returnValue = 1;
    }
    return returnValue;
  }
}