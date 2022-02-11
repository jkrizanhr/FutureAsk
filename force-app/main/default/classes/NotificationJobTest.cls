@isTest
public class NotificationJobTest {
  @testSetup 
  static void insertData() {
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
  }  

  @isTest
  static void notificationJobTest() {
    Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

    User testUser = new User(
      Alias = 'sysAdmin',
      Email = 'sysAdminUser@example.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = profile.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      Username = 'sysAdminUser@biblica.org'
    );
    insert testUser;

    System.runAs(testUser) {
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

      Contact c = new Contact(
        FirstName = 'Contact',
        LastName = 'Test',
        Email = 'test@biblica.org'
      );
      insert c;

      Opportunity opp = new Opportunity(
        Name = 'Test Opp',
        Amount = 10,
        AccountId = c.AccountId,
        npsp__Primary_Contact__c = c.Id,
        StageName = 'Posted',
        CloseDate = Date.today()
      );
      insert opp;

      Notification__c n1 = new Notification__c(
        User__c = null,
        Contact__c = c.Id,
        Record_Id__c = c.Id,
        Status__c = 'Pending',
        Label__c = 'Test',
        Message__c = 'Test',
        CRM__c = false,
        Email__c = true,
        Is_Donation_Page_Receipt__c = true,
        Opportunity_Id__c = opp.Id
      );
      
      
      Notification__c n2 = new Notification__c(
        User__c = u.Id,
        Contact__c = null,
        Record_Id__c = c.Id,
        Status__c = 'Pending',
        Label__c = 'Test',
        Message__c = 'Test',
        CRM__c = true,
        Email__c = false
        );
        
      Notification__c n3 = new Notification__c(
        User__c = null,
        Contact__c = c.Id,
        Record_Id__c = c.Id,
        Status__c = 'Pending',
        Label__c = 'Test',
        Message__c = 'Test',
        CRM__c = false,
        Email__c = true
      );

      List<Notification__c> nList = new List<Notification__c>{n1, n2, n3};
      insert nList;
    }

    EmailTemplate e = new EmailTemplate(
    Name = 'User_Email_Notification',
    DeveloperName = 'User_Email_Notification', 
    FolderId = UserInfo.getUserId(),
    TemplateType = 'Text'
    );
    insert e;

    Test.startTest();
      System.schedule('Notification Job', '0 0 0/1 1/1 * ? *', new NotificationJob());
      Database.executeBatch(new NotificationJob(), 50);
    Test.stopTest();

    List<Notification__c> nListPost = [SELECT Id, Contact__c, User__c, Status__c FROM Notification__c];
    for (Notification__c n : nListPost) {
      System.debug(n.Contact__c);
      System.debug(n.User__c);
      System.assertEquals('Completed', n.Status__c);
    }
  }
}