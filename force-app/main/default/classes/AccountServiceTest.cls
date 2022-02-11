@isTest
public class AccountServiceTest {
    
  @isTest
  static void testCreateAccountStageHistoryRecord() {
    Account acct = new Account(
      Name = 'Test Account',
      Donor_Stage__c = 'Identification'
    );
    
    Test.startTest();
      insert acct;

      Account_Stage_History__c res1 = [SELECT Id, New_Stage__c FROM Account_Stage_History__c WHERE Account__c = :acct.Id];
      System.assertNotEquals(res1, null);
      System.assertEquals(res1.New_Stage__c, 'Identification');

      acct.Donor_Stage__c = 'Prospect Qualification';
      update acct;

      Account_Stage_History__c res2 = [SELECT Id, New_Stage__c, End_Date__c FROM Account_Stage_History__c WHERE Id = :res1.Id];
      System.assertEquals(res2.End_Date__c, Date.today());

      Account_Stage_History__c res3 = [SELECT Id, New_Stage__c, Previous_Stage__c FROM Account_Stage_History__c WHERE Id != :res1.Id AND Account__c = :acct.Id];
      System.assertNotEquals(res3, null);
      System.assertEquals(res3.New_Stage__c, 'Prospect Qualification');
      System.assertEquals(res3.Previous_Stage__c, 'Identification');
    Test.stopTest();
  }

  @isTest
  static void testInsert(){
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; 
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

    Account a = new Account(
      Name = 'Test',
      RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId(),
      OwnerId = u.Id
    );
    
    Test.startTest();
      insert a;
    Test.stopTest();

    Account_Team__c res = [SELECT Id FROM Account_Team__c WHERE User__c = :u.Id AND Account__c = :a.Id];
    System.assertNotEquals(res, null);
  }

  @isTest
  static void testCreateNotificationForRM(){
    
    // Create default user custom setting
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; 
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

    Relations_Coordinator_Defaults__c rcd = Relations_Coordinator_Defaults__c.getOrgDefaults();
    rcd.Mass_Donor_Relations_Coordinator__c = u.Id;
    rcd.Mid_Level_Donor_Relations_Coordinator__c = u.Id;
    upsert rcd;
    
    // Insert Levels
    npsp__Level__c mass = new npsp__Level__c(
      npsp__Active__c = true,
      Name = 'Mass Investor',
      npsp__Source_Field__c = 'npo02__OppAmountLastNDays__c',
      npsp__Target__c = 'Account',
      npsp__Level_Field__c = 'Donor_Giving_Level__c',
      npsp__Minimum_Amount__c = 0, 
      npsp__Maximum_Amount__c = 1000
    );
    npsp__Level__c mid = new npsp__Level__c(
      npsp__Active__c = true,
      Name = 'Mid-Level Investor',
      npsp__Source_Field__c = 'npo02__OppAmountLastNDays__c',
      npsp__Target__c = 'Account',
      npsp__Level_Field__c = 'Donor_Giving_Level__c',
      npsp__Minimum_Amount__c = 1000, 
      npsp__Maximum_Amount__c = 10000
    );
    npsp__Level__c major = new npsp__Level__c(
      npsp__Active__c = true,
      Name = 'Major Investor',
      npsp__Source_Field__c = 'npo02__OppAmountLastNDays__c',
      npsp__Target__c = 'Account',
      npsp__Level_Field__c = 'Donor_Giving_Level__c',
      npsp__Minimum_Amount__c = 10000 
    );
    insert new List<npsp__Level__c>{mass, mid, major};

    // Create Account
    Account acct = new Account(
      Name = 'Test Account',
      Donor_Relationship_Manager__c = u.Id,
      Donor_Giving_Level__c = mass.Id
    );
    insert acct;

    Test.startTest();
      acct.Donor_Giving_Level__c = mid.Id;
      update acct;
      Notification__c res1 = [SELECT Id, User__c, CRM__c, Label__c, Message__c FROM Notification__c ORDER BY Id DESC LIMIT 1];
      System.assertEquals('Level Change: Mass to Mid-Level Investor', res1.Label__c);
      
      acct.Donor_Giving_Level__c = major.Id;
      update acct;
      Notification__c res2 = [SELECT Id, User__c, CRM__c, Label__c, Message__c FROM Notification__c ORDER BY Id DESC LIMIT 1];
      System.assertEquals('Level Change: Mid-Level to Major Investor', res2.Label__c);
      
      acct.Donor_Giving_Level__c = mid.Id;
      update acct;
      Notification__c res3 = [SELECT Id, User__c, CRM__c, Label__c, Message__c FROM Notification__c ORDER BY Id DESC LIMIT 1];
      System.assertEquals('Level Change: Major to Mid-Level or Mass Investor', res3.Label__c);
      
      acct.Donor_Giving_Level__c = mass.Id;
      update acct;
      Notification__c res4 = [SELECT Id, User__c, CRM__c, Label__c, Message__c FROM Notification__c ORDER BY Id DESC LIMIT 1];
      System.assertEquals('Level Change: Mid-Level to Mass Investor', res4.Label__c);
      
      acct.Donor_Giving_Level__c = major.Id;
      update acct;
      Notification__c res5 = [SELECT Id, User__c, CRM__c, Label__c, Message__c FROM Notification__c ORDER BY Id DESC LIMIT 1];
      System.assertEquals('Donor Changed Levels', res5.Label__c);
    Test.stopTest();
  }
}