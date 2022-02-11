@isTest
public without sharing class ContactServiceTest {
  @testSetup
  public static void createData() {
    Account a = new Account();
    a.Name = 'Test Account';
    a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('HH_Account')
      .getRecordTypeId();
    insert a;
  }

  @isTest
  public static void testInsertDeceased() {
    Account a = [SELECT Id, Number_of_Deceased_Members__c FROM Account][0];

    System.assertEquals(
      0,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value before insert.'
    );

    Contact c = new Contact();
    c.FirstName = 'Test';
    c.LastName = 'Contact';
    c.AccountId = a.Id;
    c.npsp__Deceased__c = true;

    Test.startTest();
    insert c;
    Test.stopTest();

    a = [
      SELECT Id, Number_of_Deceased_Members__c
      FROM Account
      WHERE Id = :a.Id
    ][0];

    System.assertEquals(
      1,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value after insert.'
    );
  }

  @isTest
  public static void testInsertNondeceased() {
    Account a = [SELECT Id, Number_of_Deceased_Members__c FROM Account][0];

    System.assertEquals(
      0,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value before insert.'
    );

    Contact c = new Contact();
    c.FirstName = 'Test';
    c.LastName = 'Contact';
    c.AccountId = a.Id;
    c.npsp__Deceased__c = false;

    Test.startTest();
    insert c;
    Test.stopTest();

    a = [
      SELECT Id, Number_of_Deceased_Members__c
      FROM Account
      WHERE Id = :a.Id
    ][0];

    System.assertEquals(
      0,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value after insert.'
    );
  }

  @isTest
  public static void testUpdateToDeceased() {
    Account a = [SELECT Id, Number_of_Deceased_Members__c FROM Account][0];

    System.assertEquals(
      0,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value before insert.'
    );

    Contact c = new Contact();
    c.FirstName = 'Test';
    c.LastName = 'Contact';
    c.AccountId = a.Id;
    c.npsp__Deceased__c = false;
    insert c;

    a = [
      SELECT Id, Number_of_Deceased_Members__c
      FROM Account
      WHERE Id = :a.Id
    ][0];

    System.assertEquals(
      0,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value after insert.'
    );

    c.npsp__Deceased__c = true;

    Test.startTest();
    update c;
    Test.stopTest();

    a = [
      SELECT Id, Number_of_Deceased_Members__c
      FROM Account
      WHERE Id = :a.Id
    ][0];

    System.assertEquals(
      1,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value after update.'
    );
  }

  @isTest
  public static void testUpdateToNondeceased() {
    Account a = [SELECT Id, Number_of_Deceased_Members__c FROM Account][0];

    System.assertEquals(
      0,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value before insert.'
    );

    Contact c = new Contact();
    c.FirstName = 'Test';
    c.LastName = 'Contact';
    c.AccountId = a.Id;
    c.npsp__Deceased__c = true;
    insert c;

    a = [
      SELECT Id, Number_of_Deceased_Members__c
      FROM Account
      WHERE Id = :a.Id
    ][0];

    System.assertEquals(
      1,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value after insert.'
    );

    c.npsp__Deceased__c = false;

    Test.startTest();
    update c;
    Test.stopTest();

    a = [
      SELECT Id, Number_of_Deceased_Members__c
      FROM Account
      WHERE Id = :a.Id
    ][0];

    System.assertEquals(
      0,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value after update.'
    );
  }

  @isTest
  public static void testDeleteDeceased() {
    Account a = [SELECT Id, Number_of_Deceased_Members__c FROM Account][0];

    System.assertEquals(
      0,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value before insert.'
    );

    Contact c = new Contact();
    c.FirstName = 'Test1';
    c.LastName = 'Contact';
    c.AccountId = a.Id;
    c.npsp__Deceased__c = true;

    Contact c2 = new Contact();
    c2.FirstName = 'Test2';
    c2.LastName = 'Contact';
    c2.AccountId = a.Id;
    c2.npsp__Deceased__c = true;

    insert new List<Contact>{c, c2};

    a = [
      SELECT Id, Number_of_Deceased_Members__c
      FROM Account
      WHERE Id = :a.Id
    ][0];

    System.assertEquals(
      2,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value after insert.'
    );

    Test.startTest();
    delete c;
    Test.stopTest();

    a = [
      SELECT Id, Number_of_Deceased_Members__c
      FROM Account
      WHERE Id = :a.Id
    ][0];

    System.assertEquals(
      1,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value after insert.'
    );
  }

  @isTest
  public static void testDeleteNondeceased() {
    Account a = [SELECT Id, Number_of_Deceased_Members__c FROM Account][0];

    System.assertEquals(
      0,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value before delete.'
    );

    Contact c = new Contact();
    c.FirstName = 'Test1';
    c.LastName = 'Contact';
    c.AccountId = a.Id;
    c.npsp__Deceased__c = false;

    Contact c2 = new Contact();
    c2.FirstName = 'Test2';
    c2.LastName = 'Contact';
    c2.AccountId = a.Id;
    c2.npsp__Deceased__c = true;

    insert new List<Contact>{c, c2};

    a = [
      SELECT Id, Number_of_Deceased_Members__c
      FROM Account
      WHERE Id = :a.Id
    ][0];

    System.assertEquals(
      1,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value after insert.'
    );

    Test.startTest();
    delete c;
    Test.stopTest();

    a = [
      SELECT Id, Number_of_Deceased_Members__c
      FROM Account
      WHERE Id = :a.Id
    ][0];

    System.assertEquals(
      1,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value after delete.'
    );
  }

  @isTest
  public static void testUndeleteDeceased() {
    Account a = [SELECT Id, Number_of_Deceased_Members__c FROM Account][0];

    System.assertEquals(
      0,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value before insert.'
    );

    Contact c = new Contact();
    c.FirstName = 'Test1';
    c.LastName = 'Contact';
    c.AccountId = a.Id;
    c.npsp__Deceased__c = true;

    Contact c2 = new Contact();
    c2.FirstName = 'Test2';
    c2.LastName = 'Contact';
    c2.AccountId = a.Id;
    c2.npsp__Deceased__c = true;

    insert new List<Contact>{c, c2};

    a = [
      SELECT Id, Number_of_Deceased_Members__c
      FROM Account
      WHERE Id = :a.Id
    ][0];

    System.assertEquals(
      2,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value after insert.'
    );

    delete c;

    a = [
      SELECT Id, Number_of_Deceased_Members__c
      FROM Account
      WHERE Id = :a.Id
    ][0];

    System.assertEquals(
      1,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value after delete.'
    );

    Test.startTest();
    undelete c;
    Test.stopTest();

    a = [
      SELECT Id, Number_of_Deceased_Members__c
      FROM Account
      WHERE Id = :a.Id
    ][0];

    System.assertEquals(
      2,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value after undelete.'
    );
  }

  @isTest
  public static void testUndeleteNondeceased() {
    Account a = [SELECT Id, Number_of_Deceased_Members__c FROM Account][0];

    System.assertEquals(
      0,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value before delete.'
    );

    Contact c = new Contact();
    c.FirstName = 'Test1';
    c.LastName = 'Contact';
    c.AccountId = a.Id;
    c.npsp__Deceased__c = false;

    Contact c2 = new Contact();
    c2.FirstName = 'Test2';
    c2.LastName = 'Contact';
    c2.AccountId = a.Id;
    c2.npsp__Deceased__c = true;

    insert new List<Contact>{c, c2};

    a = [
      SELECT Id, Number_of_Deceased_Members__c
      FROM Account
      WHERE Id = :a.Id
    ][0];

    System.assertEquals(
      1,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value after insert.'
    );

    delete c;

    a = [
      SELECT Id, Number_of_Deceased_Members__c
      FROM Account
      WHERE Id = :a.Id
    ][0];

    System.assertEquals(
      1,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value after delete.'
    );

    Test.startTest();
    undelete c;
    Test.stopTest();

    a = [
      SELECT Id, Number_of_Deceased_Members__c
      FROM Account
      WHERE Id = :a.Id
    ][0];

    System.assertEquals(
      1,
      a.Number_of_Deceased_Members__c,
      'Account rollup field does not contain the correct value after undelete.'
    );
  }
}