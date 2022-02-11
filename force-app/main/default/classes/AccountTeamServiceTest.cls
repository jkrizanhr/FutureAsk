@isTest
private class AccountTeamServiceTest {
  @TestSetup
  static void makeData(){
    Account a = new Account(
      Name = 'Test'
    );
    insert a;

    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User']; 
    User u = new User(
      Alias = 'user', 
      Email='test@candoris.com.biblica', 
      EmailEncodingKey='UTF-8', 
      LastName='User', 
      LanguageLocaleKey='en_US', 
      LocaleSidKey='en_US', 
      ProfileId = p.Id, 
      TimeZoneSidKey='America/New_York', 
      UserName='test@candoris.com.biblica'
    );
    insert u;
  }

  @isTest 
  static void testInsert() {
    Account a = [SELECT Id FROM Account WHERE Name = 'Test'];
    User u = [SELECT Id FROM User WHERE UserName = 'test@candoris.com.biblica'];
    
    Account_Team__c at1 = new Account_Team__c(
      Account__c = a.Id,
      User__c = u.Id,
      Role__c = 'Primary Partnership Manager',
      Start_Date__c = Date.today().addDays(-3),
      End_Date__c = Date.today().addDays(3),
      Status__c = 'Active'
    );

    Account_Team__c at2 = new Account_Team__c(
      Account__c = a.Id,
      User__c = u.Id,
      Role__c = 'Donor Relationship Manager',
      Start_Date__c = Date.today().addDays(-3),
      End_Date__c = Date.today().addDays(3),
      Status__c = 'Active'
    );

    Test.startTest();
      insert at1;
      Account acct = [SELECT Id, Primary_Partnership_Manager__c, Donor_Relationship_Manager__c FROM Account WHERE Id = :a.Id LIMIT 1];
      System.assertEquals(u.Id, acct.Primary_Partnership_Manager__c, 'The Primary Partnership Manager should be set.');
      
      insert at2;
      acct = [SELECT Id, Primary_Partnership_Manager__c, Donor_Relationship_Manager__c FROM Account WHERE Id = :a.Id LIMIT 1];
      System.assertEquals(u.Id, acct.Donor_Relationship_Manager__c, 'The Donor Relationship Manager should be set.');
    Test.stopTest();
  }

  @isTest 
  static void testUpdate() {
    Account a = [SELECT Id FROM Account WHERE Name = 'Test'];
    User u = [SELECT Id FROM User WHERE UserName = 'test@candoris.com.biblica'];
    
    Account_Team__c at = new Account_Team__c(
      Account__c = a.Id,
      User__c = u.Id,
      Role__c = 'Primary Partnership Manager',
      Start_Date__c = Date.today().addDays(-3),
      End_Date__c = Date.today().addDays(3),
      Status__c = 'Active'
    );
    insert at;

    Account acct = [SELECT Id, Primary_Partnership_Manager__c FROM Account WHERE Id = :a.Id LIMIT 1];
    System.assertEquals(u.Id, acct.Primary_Partnership_Manager__c, 'The Primary Partnership Manager should be set.');
    
    Test.startTest();
      //Update Status to Inactive
      at.End_Date__c = Date.today().addDays(-2);
      at.Status__c = 'Inactive';
      update at;
      acct = [SELECT Id, Primary_Partnership_Manager__c FROM Account WHERE Id = :a.Id LIMIT 1];
      System.assertEquals(null, acct.Primary_Partnership_Manager__c, 'The Primary Partnership Manager should be null.');

      //Update Status to Active
      at.End_Date__c = Date.today().addDays(7);
      at.Status__c = 'Active';
      update at;
      acct = [SELECT Id, Primary_Partnership_Manager__c FROM Account WHERE Id = :a.Id LIMIT 1];
      System.assertEquals(u.Id, acct.Primary_Partnership_Manager__c, 'The Primary Partnership Manager should be set.');

      //Update Role to Donor Relationship Manager
      at.Role__c = 'Donor Relationship Manager';
      at.Status__c = 'Active';
      update at;
      acct = [SELECT Id, Primary_Partnership_Manager__c, Donor_Relationship_Manager__c FROM Account WHERE Id = :a.Id LIMIT 1];
      System.assertEquals(null, acct.Primary_Partnership_Manager__c, 'The Primary Partnership Manager should be null.');
      System.assertEquals(u.Id, acct.Donor_Relationship_Manager__c, 'The Donor Relationship Manager should be null.');

      //Update Role to Inactive
      at.Status__c = 'Inactive';
      update at;
      acct = [SELECT Id, Primary_Partnership_Manager__c, Donor_Relationship_Manager__c FROM Account WHERE Id = :a.Id LIMIT 1];
      System.assertEquals(null, acct.Donor_Relationship_Manager__c, 'The Donor Relationship Manager should be null.');
    Test.stopTest();
  }

  @isTest 
  static void testDelete() {
    Account a = [SELECT Id FROM Account WHERE Name = 'Test'];
    User u = [SELECT Id FROM User WHERE UserName = 'test@candoris.com.biblica'];
    
    Account_Team__c at1 = new Account_Team__c(
      Account__c = a.Id,
      User__c = u.Id,
      Role__c = 'Primary Partnership Manager',
      Start_Date__c = Date.today().addDays(-3),
      End_Date__c = Date.today().addDays(3),
      Status__c = 'Active'
    );
    Account_Team__c at2 = new Account_Team__c(
      Account__c = a.Id,
      User__c = u.Id,
      Role__c = 'Donor Relationship Manager',
      Start_Date__c = Date.today().addDays(-3),
      End_Date__c = Date.today().addDays(3),
      Status__c = 'Active'
    );

    Test.startTest();
      // INSERT ACCOUNT ONE - TEST WITH PPM
      insert at1; 
      Account acct1 = [SELECT Id, Primary_Partnership_Manager__c, Donor_Relationship_Manager__c FROM Account WHERE Id = :a.Id LIMIT 1];
      System.assertEquals(u.Id, acct1.Primary_Partnership_Manager__c, 'The Primary Partnership Manager should be set.');
      
      delete at1;
      acct1 = [SELECT Id, Primary_Partnership_Manager__c, Donor_Relationship_Manager__c FROM Account WHERE Id = :a.Id LIMIT 1];
      System.assertEquals(null, acct1.Primary_Partnership_Manager__c, 'The Primary Partnership Manager should be removed.');   
      
      // INSERT ACCOUNT TWO - TEST WITH DRM
      insert at2;
      Account acct2 = [SELECT Id, Primary_Partnership_Manager__c, Donor_Relationship_Manager__c FROM Account WHERE Id = :a.Id LIMIT 1];
      System.assertEquals(u.Id, acct2.Donor_Relationship_Manager__c, 'The Donor Relationship Manager should be set.');
        
      delete at2;
      acct2 = [SELECT Id, Primary_Partnership_Manager__c, Donor_Relationship_Manager__c FROM Account WHERE Id = :a.Id LIMIT 1];
      System.assertEquals(null, acct2.Donor_Relationship_Manager__c, 'The Donor Relationship Manager should be removed.');   
    Test.stopTest();
  }
}