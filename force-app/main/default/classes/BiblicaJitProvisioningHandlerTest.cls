@isTest
public without sharing class BiblicaJitProvisioningHandlerTest {
  @testSetup
  static void createData() {
    Contact c = new Contact();
    c.FirstName = 'altFirstName';
    c.LastName = 'lastName';
    c.Email = 'test2@test.com';
    insert c;
  }
  @isTest
  static void testCreateUserNoContact() {
    String profileId = [SELECT Id FROM Profile WHERE Name = 'Donor Portal User'].Id;

    String firstName = 'firstName';
    String lastName = 'lastName';
    String email = 'test@test.com';

    Map<String, String> attributeMap = new Map<String, String>();
    attributeMap.put('sfdc_networkid', '12345');
    
    Auth.UserData data = new Auth.UserData('identifier', firstName, lastName, firstName + ' ' + lastName, email, 'https://www.facebook.com', email, UserInfo.getLocale(), 'Facebook', null, attributeMap);
    
    Id portalId = '0DB000000000000';

    Test.startTest();
    BiblicaJitProvisioningHandler handler = new BiblicaJitProvisioningHandler();
    handler.createUser(portalId, data);
    Test.stopTest();

    List<User> users = [
      SELECT Id, FirstName, LastName, Username, Email, IsActive, ContactId, ProfileId
      FROM User
      WHERE Email = :email
      LIMIT 1
    ];
    System.debug(users.size());
    System.assert(users.size() == 1);
    User newUser = users[0];
    System.assertEquals(firstName, newUser.FirstName);
    System.assertEquals(lastName, newUser.LastName);
    System.assertEquals(email, newUser.Email);
    System.assertEquals(true, newUser.IsActive);
    System.assertEquals(profileId, newUser.ProfileId);
    System.assertNotEquals(null, newUser.ContactId);
    List<Contact> contacts = [
      SELECT Id, FirstName, LastName, Email
      FROM Contact
      WHERE Id = :newUser.ContactId
    ];
    System.assert(contacts.size() == 1);
    Contact con = contacts[0];
    System.assertEquals(firstName, con.FirstName);
    System.assertEquals(lastName, con.LastName);
    System.assertEquals(email, con.Email);
  }

  // @isTest
  // static void testCreateUserFromContact() {
  //   String profileId = [SELECT Id FROM Profile WHERE Name = 'Donor Portal User'].Id;

  //   Contact c = new Contact();
  //   c.LastName = 'lastName';
  //   c.FirstName = 'firstName';
  //   c.Email = 'test@test.com';
  //   insert c;

  //   String firstName = 'firstName';
  //   String lastName = 'lastName';
  //   String email = 'test@test.com';
    
  //   Map<String, String> attributeMap = new Map<String, String>();
  //   attributeMap.put('sfdc_networkid', '12345');
    
  //   Auth.UserData data = new Auth.UserData('identifier', firstName, lastName, firstName + ' ' + lastName, email, 'https://www.facebook.com', email, UserInfo.getLocale(), 'Facebook', null, attributeMap);
    
  //   Id portalId = '0DB000000000000';

  //   Test.startTest();
  //   BiblicaJitProvisioningHandler handler = new BiblicaJitProvisioningHandler();
  //   handler.createUser(portalId, data);
  //   Test.stopTest();

  //   List<User> users = [
  //     SELECT Id, FirstName, LastName, Username, Email, IsActive, ContactId, ProfileId
  //     FROM User
  //     WHERE Email = :email
  //     LIMIT 1
  //   ];
  //   System.debug(users.size());
  //   System.assert(users.size() == 1);
  //   User newUser = users[0];
  //   System.assertEquals(firstName, newUser.FirstName);
  //   System.assertEquals(lastName, newUser.LastName);
  //   System.assertEquals(email, newUser.Email);
  //   System.assertEquals(true, newUser.IsActive);
  //   System.assertEquals(profileId, newUser.ProfileId);
  //   System.assertEquals(c.Id, newUser.ContactId);
  //   List<Contact> contacts = [
  //     SELECT Id, FirstName, LastName, Email
  //     FROM Contact
  //     WHERE Id = :c.Id
  //   ];
  //   System.assert(contacts.size() == 1);
  //   Contact con = contacts[0];
  //   System.assertEquals(firstName, con.FirstName);
  //   System.assertEquals(lastName, con.LastName);
  //   System.assertEquals(email, con.Email);
  // }

  @isTest
  static void testCreateUserJitException() {
    String profileId = [SELECT Id FROM Profile WHERE Name = 'Donor Portal User'].Id;

    Contact c = new Contact();
    c.LastName = 'lastName';
    c.Email = 'test@test.com';
    insert c;

    String firstName = 'firstName';
    String lastName = null;
    String email = 'test@test.com';
    
    Map<String, String> attributeMap = new Map<String, String>();
    attributeMap.put('sfdc_networkid', '12345');
    
    Auth.UserData data = new Auth.UserData('identifier', firstName, lastName, firstName + ' ' + lastName, email, 'https://www.facebook.com', email, UserInfo.getLocale(), 'Facebook', null, attributeMap);
    
    Id portalId = '0DB000000000000';

    Test.startTest();
      try {
        BiblicaJitProvisioningHandler handler = new BiblicaJitProvisioningHandler();
        handler.createUser(portalId, data);
        System.assert(false, 'Should\'ve thrown error but didn\'t.');
      } catch (Exception e){
        System.debug(e.getMessage());
      }
    Test.stopTest();
  }
}