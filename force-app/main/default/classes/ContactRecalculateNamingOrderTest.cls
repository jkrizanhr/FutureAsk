@isTest
private class ContactRecalculateNamingOrderTest {
  private static Contact queryContact(Id contactId) {
    return [
      SELECT Id, AccountId, npo02__Household_Naming_Order__c, NPSP_Formal_Greeting_Order__c
      FROM Contact
      WHERE Id = :contactId
    ];
  }

  @isTest
  static void testTrigger() {
    Contact con = new Contact();
    con.FirstName = 'Bill';
    con.LastName = 'Jones';
    insert con;

    con = queryContact(con.Id);
    System.assert(con.npo02__Household_Naming_Order__c != null);
    System.assert(con.NPSP_Formal_Greeting_Order__c != null);

    con.FirstName = 'John';
    update con;

    con = queryContact(con.Id);
    System.assert(con.npo02__Household_Naming_Order__c != null);
    System.assert(con.NPSP_Formal_Greeting_Order__c != null);

    delete con;
    undelete con;

    con = queryContact(con.Id);
    System.assert(con.npo02__Household_Naming_Order__c != null);
    System.assert(con.NPSP_Formal_Greeting_Order__c != null);
  }
}