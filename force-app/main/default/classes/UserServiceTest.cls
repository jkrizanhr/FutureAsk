@isTest
private class UserServiceTest {

  @isTest
  static void testSetUserLookupOnContactWithContactId() {
    Contact c = new Contact();
    c.FirstName = 'First';
    c.LastName = 'Last';
    c.Email = 'test@candoris.com.fotf';
    insert c;

    Profile p = [SELECT Id FROM Profile WHERE Name = 'Donor Portal User']; 
    User u = new User(
      Alias = 'user', 
      Email='test@candoris.com.fotf', 
      EmailEncodingKey='UTF-8', 
      LastName='User', 
      LanguageLocaleKey='en_US', 
      LocaleSidKey='en_US', 
      ProfileId = p.Id, 
      TimeZoneSidKey='America/New_York', 
      UserName='test@candoris.com.fotf',
      ContactId = c.Id
    );
    
    Test.startTest();
      insert u;
    Test.stopTest();
    
    Contact res = [SELECT Id, User__c FROM Contact WHERE Id = :c.Id];
    System.assertEquals(u.Id, res.User__c);
  }

  @isTest
  static void testSetUserLookupOnContactCustomContactId() {
    Contact c = new Contact();
    c.FirstName = 'First';
    c.LastName = 'Last';
    c.Email = 'test@candoris.com.fotf';
    insert c;

    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; 
    User u = new User(
      Alias = 'user', 
      Email='test@candoris.com.fotf', 
      EmailEncodingKey='UTF-8', 
      LastName='User', 
      LanguageLocaleKey='en_US', 
      LocaleSidKey='en_US', 
      ProfileId = p.Id, 
      TimeZoneSidKey='America/New_York', 
      UserName='test@candoris.com.fotf',
      Contact_Id__c = c.Id
    );
    
    Test.startTest();
      insert u;
    Test.stopTest();
    
    Contact res = [SELECT Id, User__c FROM Contact WHERE Id = :c.Id];
    System.assertEquals(u.Id, res.User__c);
  }

  @isTest
  static void testSetUserLookupOnContactUpdate() {
    Contact c = new Contact();
    c.FirstName = 'First';
    c.LastName = 'Last';
    c.Email = 'test@candoris.com.fotf';
    insert c;

    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; 
    User u = new User(
      Alias = 'user', 
      Email='test@candoris.com.fotf', 
      EmailEncodingKey='UTF-8', 
      LastName='User', 
      LanguageLocaleKey='en_US', 
      LocaleSidKey='en_US', 
      ProfileId = p.Id, 
      TimeZoneSidKey='America/New_York', 
      UserName='test@candoris.com.fotf',
      Contact_Id__c = c.Id
    );
    insert u;
    
    Test.startTest();
      u.Contact_Id__c = null;
      update u;
    Test.stopTest();
    
    Contact res = [SELECT Id, User__c FROM Contact WHERE Id = :c.Id];
    System.assertEquals(null, res.User__c);
  }
}