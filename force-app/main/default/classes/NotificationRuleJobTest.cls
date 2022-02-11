@isTest
public class NotificationRuleJobTest {
  @isTest
  static void notificationRuleJobTest() {
    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
    User u = new User(
      Alias = 'bibTest', 
      Email='TestClassUser@biblica.org', 
      EmailEncodingKey='UTF-8', 
      FirstName='User', 
      LastName='Testing', 
      LanguageLocaleKey='en_US', 
      LocaleSidKey='en_US', 
      ProfileId = p.Id, 
      TimeZoneSidKey='America/Los_Angeles', 
      UserName='TestClassUser@biblica.org'
    );
    insert u;

    System.runAs(u) {
      Contact c = new Contact(
        FirstName = 'Contact',
        LastName = 'Test',
        OwnerId = u.Id
      );
      insert c;
      c = [SELECT Id, AccountId, FirstName, LastName, OwnerId FROM Contact WHERE Id = :c.Id];

      Decimal usdRate = 1.10385;
      Decimal gbpRate = 0.855313;
  
      Currency_Exchange_Rate__c rate = new Currency_Exchange_Rate__c();
      rate.API_Response__c = CurrencyExchangeRateTestHelper.getResponseString(
          'EUR',
          usdRate,
          gbpRate
      );
      rate.Base__c = 'EUR';
      rate.Exchange_Rate_Collected_Date__c = Date.today();
      insert rate;
      
      Opportunity o = new Opportunity(
        AccountId = c.AccountId,
        CloseDate = Date.today(),
        Name = 'Test Opportunity',
        Original_Amount__c = 100,
        Original_Currency__c = 'USD',
        StageName = 'Prospecting'
      );
      insert o;
    }
      
    Test.startTest();
      System.schedule('TEST Notification Rule Job', '0 0 0/1 1/1 * ? *', new NotificationRuleJob());
      new NotificationRuleJob();
    Test.stopTest();

    Contact con = [SELECT Id FROM Contact LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    // UnitTest_Opportunity_User
    List<Notification__c> userNotifications = [
      SELECT 
        Message__c, Label__c, CRM__c, Email__c, 
        Contact__c, User__c, Status__c, Record_Id__c
      FROM Notification__c
      WHERE 
        Label__c = 'UnitTest_Opportunity_User'
    ];
    System.assertNotEquals(null, userNotifications);
    for (Notification__c n : userNotifications) {
      System.assertEquals(u.Id, n.User__c);
      System.assertEquals(null, n.Contact__c);
      System.assertEquals(opp.Id, n.Record_Id__c);
      System.assertEquals('Pending', n.Status__c);
      System.assertEquals('Hi User', n.Message__c);
      System.assertEquals(true, n.CRM__c);
      System.assertEquals(false, n.Email__c);
    }

    // UnitTest_Opportunity_Contact
    List<Notification__c> contactNotifications = [
      SELECT 
        Message__c, Label__c, CRM__c, Email__c, 
        Contact__c, User__c, Status__c, Record_Id__c
      FROM Notification__c
      WHERE 
        Label__c = 'UnitTest_Opportunity_Contact'
    ];
    System.assertNotEquals(null, contactNotifications);
    for (Notification__c n : contactNotifications) {
      System.assertEquals(null, n.User__c);
      System.assertEquals(con.Id, n.Contact__c);
      System.assertEquals(opp.Id, n.Record_Id__c);
      System.assertEquals('Pending', n.Status__c);
      System.assertEquals('Hi Contact', n.Message__c);
      System.assertEquals(false, n.CRM__c);
      System.assertEquals(true, n.Email__c);
    }

    // for reference - expected Notification_Rule__mdt records
    // Notification_Rule__mdt UnitTest_Opportunity_User = new Notification_Rule__mdt(
    //   DeveloperName = 'UnitTest_Opportunity_User',
    //   Recipient_Type__c = 'User',
    //   Email_Notification__c = true,
    //   Subject__c = 'UnitTest_Opportunity_User',
    //   Recipient_Field__c = 'Account.OwnerId',
    //   SOQL_Query__c = 'SELECT Id, Account.OwnerId, Account.Owner.FirstName, Account.npe01__One2OneContact__c, Account.npe01__One2OneContact__r.FirstName FROM Opportunity',
    //   Message__c = 'Hi {!Account.Owner.FirstName}'
    // );
    // Notification_Rule__mdt UnitTest_Opportunity_Contact = new Notification_Rule__mdt(
    //   DeveloperName = 'UnitTest_Opportunity_Contact',
    //   Recipient_Type__c = 'Contact',
    //   Email_Notification__c = true,
    //   Subject__c = 'UnitTest_Opportunity_Contact',
    //   Recipient_Field__c = 'Account.npe01__One2OneContact__c',
    //   SOQL_Query__c = 'SELECT Id, Account.OwnerId, Account.Owner.FirstName, Account.npe01__One2OneContact__c, Account.npe01__One2OneContact__r.FirstName FROM Opportunity',
    //   Message__c = 'Hi {!Account.npe01__One2OneContact__r.FirstName}'
    // );
  }
}