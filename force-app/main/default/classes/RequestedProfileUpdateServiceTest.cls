@isTest
private class RequestedProfileUpdateServiceTest {
  @isTest  
  static void testRequestedProfileUpdate() {
    Contact con = new Contact(
      Salutation = null,
      FirstName = 'Sample',
      LastName = 'Contact',
      Suffix = null,
      npe01__PreferredPhone__c = 'Home',
      HomePhone = '9876543210',
      npe01__WorkPhone__c = null,
      MobilePhone = null,
      npe01__Preferred_Email__c = 'Personal',
      npe01__HomeEmail__c = 'personal@example.com',
      npe01__WorkEmail__c = 'work@example.com',
      npe01__AlternateEmail__c = null,
      MailingCountry = 'United States',
      MailingStreet = '123 Test Street',
      MailingCity = 'Test City',
      MailingState = 'PA',
      MailingPostalCode = '17003'
    );
    insert con;

    Requested_Profile_Update__c rpu = new Requested_Profile_Update__c(
      Update_Status__c = 'Waiting for Approval',
      Contact__c = con.Id,
      Prefix__c = 'Miss',
      First_Name__c = 'Sample',
      Last_Name__c = 'Contact',
      Suffix__c = 'III',
      Preferred_Phone__c = 'Work',
      Home_Phone__c = null,
      Work_Phone__c = '9876543210',
      Mobile_Phone__c = null,
      Preferred_Email__c = 'Personal',
      Personal_Email__c = 'personal@example.com',
      Work_Email__c = 'work@example.com',
      Alternate_Email__c = 'alternate@example.com',
      Country__c = 'United States',
      Street__c = '123 Test Avenue',
      City__c = 'Test City',
      State__c = 'PA',
      Postal_Code__c = '12345'
    );
    insert rpu;

    Test.startTest();
    rpu.Update_Status__c = 'Approved';
    update rpu;
    Test.stopTest();

    Contact res = [SELECT Id, Suffix FROM Contact WHERE Id = :con.Id LIMIT 1];
    System.assertEquals(res.Suffix, 'III');
  }
  
  @isTest  
  static void testAutoApproveUpdate() {
    Contact con = new Contact(
      Salutation = null,
      FirstName = 'Sample',
      LastName = 'Contact',
      Suffix = null,
      npe01__PreferredPhone__c = 'Home',
      HomePhone = '9876543210',
      npe01__WorkPhone__c = null,
      MobilePhone = null,
      npe01__Preferred_Email__c = 'Personal',
      npe01__HomeEmail__c = 'personal@example.com',
      npe01__WorkEmail__c = 'work@example.com',
      npe01__AlternateEmail__c = null,
      MailingCountry = 'United States',
      MailingStreet = '123 Test Street',
      MailingCity = 'Test City',
      MailingState = 'PA',
      MailingPostalCode = '17003'
    );
    insert con;

    Requested_Profile_Update__c rpu = new Requested_Profile_Update__c(
      Update_Status__c = 'Pending',
      Contact__c = con.Id,
      Prefix__c = 'Miss',
      First_Name__c = 'Sample',
      Last_Name__c = 'Contact',
      Suffix__c = 'III',
      Preferred_Phone__c = 'Work',
      Home_Phone__c = null,
      Work_Phone__c = '9876543210',
      Mobile_Phone__c = null,
      Preferred_Email__c = 'Personal',
      Personal_Email__c = 'personal@example.com',
      Work_Email__c = 'work@example.com',
      Alternate_Email__c = 'alternate@example.com',
      Country__c = 'United States',
      Street__c = '123 Test Avenue',
      City__c = 'Test City',
      State__c = 'PA',
      Postal_Code__c = '12345'
    );
    insert rpu;

    Test.startTest();
    rpu.Update_Status__c = 'Waiting for Approval';
    update rpu;
    Test.stopTest();

    Contact res = [SELECT Id, Suffix FROM Contact WHERE Id = :con.Id LIMIT 1];
    System.assertEquals(res.Suffix, 'III');
    Notification__c n = [SELECT Id FROM Notification__c WHERE Contact__c = :con.Id LIMIT 1];
    System.assertNotEquals(null, n);
  }
}