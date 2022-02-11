@IsTest
public class HouseholdGreetingsJobTest {
  @IsTest
  public static void testHouseholdNamingConventionExplicit() {
    Account a = new Account();
    a.Name = 'Household';
    insert a;

    Contact c = new Contact();
    c.FirstName = 'Male';
    c.LastName = 'Male';
    c.Gender__c = 'Male';
    c.npo02__Household_Naming_Order__c = 3;
    c.AccountId = a.Id;
    insert c;

    Contact c2 = new Contact();
    c2.FirstName = 'Male2';
    c2.LastName = 'Male2';
    c2.Salutation = 'Mr.';
    c2.npo02__Household_Naming_Order__c = 4;
    c2.AccountId = a.Id;
    insert c2;

    Contact c3 = new Contact();
    c3.FirstName = 'Female';
    c3.LastName = 'Female';
    c3.Gender__c = 'Female';
    c3.npo02__Household_Naming_Order__c = 2;
    c3.AccountId = a.Id;
    insert c3;

    Contact c4 = new Contact();
    c4.FirstName = 'Female';
    c4.LastName = 'Female2';
    c4.Salutation = 'Miss';
    c4.npo02__Household_Naming_Order__c = 1;
    c4.AccountId = a.Id;
    insert c4;

    List<Contact> con = [
      SELECT Id, LastName, npo02__Household_Naming_Order__c
      FROM Contact
      ORDER BY npo02__Household_Naming_Order__c
    ];
    System.debug(con);

    Test.startTest();
    System.schedule('Household Greeting Test', '0 0 23 1/1 * ? *', new householdGreetingsJob(null));
    Test.stopTest();

    con = [
      SELECT Id, LastName, npo02__Household_Naming_Order__c
      FROM Contact
      ORDER BY npo02__Household_Naming_Order__c
    ];
    System.debug(con);

    c3.FirstName = 'Female1';
    update c3;

    con = [
      SELECT Id, LastName, npo02__Household_Naming_Order__c
      FROM Contact
      ORDER BY npo02__Household_Naming_Order__c
    ];
    System.debug(con);

    c3.FirstName = 'Female';
    update c3;

    con = [
      SELECT Id, LastName, npo02__Household_Naming_Order__c
      FROM Contact
      ORDER BY npo02__Household_Naming_Order__c
    ];
    System.debug(con);

    System.assertEquals('Male2', con[3].LastName);
    System.assertEquals('Male', con[2].LastName);
    System.assertEquals(0, con[0].npo02__Household_Naming_Order__c);
    System.assertEquals(1, con[1].npo02__Household_Naming_Order__c);
    System.assertEquals(2, con[2].npo02__Household_Naming_Order__c);
    System.assertEquals(3, con[3].npo02__Household_Naming_Order__c);
  }

  @IsTest
  public static void testHouseholdNamingConventionExplicitNullFirstName() {
    Contact c = new Contact();
    c.LastName = 'Male';
    c.Gender__c = 'Male';
    c.npo02__Household_Naming_Order__c = 2;
    insert c;
    c = [SELECT Id, AccountId FROM Contact WHERE Id = :c.Id];

    Contact c2 = new Contact();
    c2.FirstName = 'Female';
    c2.LastName = 'Female';
    c2.Gender__c = 'Female';
    c2.npo02__Household_Naming_Order__c = 1;
    c2.AccountId = c.AccountId;
    insert c2;

    Test.startTest();
    Database.executeBatch(new householdGreetingsJob(null));
    Test.stopTest();

    List<Contact> con = [
      SELECT Id, LastName, npo02__Household_Naming_Order__c
      FROM Contact
      ORDER BY npo02__Household_Naming_Order__c
    ];
    System.assertEquals('Female', con[0].LastName);
    System.assertEquals('Male', con[1].LastName);
  }
}