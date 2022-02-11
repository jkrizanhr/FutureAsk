@isTest
private without sharing class StatusUpdateEmailJobServiceTest {
  @testSetup
  private static void makeData() {
    // Insert the default custom setting for all tests.
    Resource_Order_Name__c testResourceOrderName = new Resource_Order_Name__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      Counter__c = 0
    );
    insert testResourceOrderName;

    User testUser = new User(
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator']
      .Id,
      FirstName = 'Adam',
      LastName = 'Johnson',
      Email = 'email@biblica.com.test',
      Username = 'email@biblica.com.test',
      CompanyName = 'Candoris',
      Title = 'Title',
      Alias = 'alias',
      TimeZoneSidKey = 'America/New_York',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US'
    );
    insert testUser;

    Account testAcct = new Account(
      Name = 'Test Account',
      BillingStreet = '123 Test Avenue',
      Website = 'testexample.edu',
      Primary_Partnership_Manager__c = testUser.Id
    );
    insert testAcct;

    Resource__c testResource = new Resource__c(Name = 'Test Resource', Retail_Value__c = 10);
    insert testResource;

    Fund_GL_Account__c testGlAcct = new Fund_GL_Account__c(
      Name = 'Test Fund GL Account',
      GL_Account_External_Id__c = 'ABC123',
      GL_Account_Prefix__c = 'TEST',
      GL_Account__c = 'Testing GL Account',
      Active__c = true
    );
    insert testGlAcct;

    npsp__General_Accounting_Unit__c testGau = new npsp__General_Accounting_Unit__c(
      Name = 'Test GAU',
      Purpose_Code__c = '2020',
      Default_Fund_GL_Account__c = testGlAcct.Id
    );
    insert testGau;

    Project__c testLmpProject = new Project__c(
      Name = 'Test Project',
      Status__c = 'In Progress',
      General_Accounting_Unit__c = testGau.Id,
      RecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName()
        .get('Language Ministry Project')
        .getRecordTypeId()
    );
    insert testLmpProject;
  }

  @isTest
  private static void testStatusUpdateEmailJob() {
    Contact testCon = new Contact(FirstName = 'Jared', LastName = 'Smith');
    insert testCon;

    List<Prayer_Request__c> testPrayerReqs = new List<Prayer_Request__c>();

    Prayer_Request__c testPrayerReq1 = new Prayer_Request__c(
      Contact__c = testCon.Id,
      Date_Requested__c = Date.today(),
      Region__c = 'The Americas',
      Request__c = 'Testing',
      Request_Explanation__c = 'Jared\'s first testing prayer request.'
    );
    testPrayerReqs.add(testPrayerReq1);

    Prayer_Request__c testPrayerReq2 = new Prayer_Request__c(
      Contact__c = testCon.Id,
      Date_Requested__c = Date.today(),
      Region__c = 'The Americas',
      Request__c = 'Testing 2',
      Request_Explanation__c = 'Jared\'s second testing prayer request.'
    );
    testPrayerReqs.add(testPrayerReq2);

    insert testPrayerReqs;

    Account testAcct = [
      SELECT Id, Primary_Partnership_Manager__r.LastName
      FROM Account
      WHERE Name = 'Test Account'
      LIMIT 1
    ];

    Project__c testLmpProject = [
      SELECT Id, Counter__c, General_Accounting_Unit__r.Purpose_Code__c
      FROM Project__c
      WHERE Name = 'Test Project'
      LIMIT 1
    ];

    User testUser = [SELECT Id FROM User WHERE Username = 'email@biblica.com.test' LIMIT 1];

    List<Resource_Order__c> testResourceOrders = new List<Resource_Order__c>();

    Resource_Order__c testResourceOrder1 = new Resource_Order__c(
      Name = 'Test Resource Order 1',
      Account__c = testAcct.Id,
      LMP_Project__c = testLmpProject.Id,
      Resource_Order_Total__c = 100,
      Submitted_Date__c = Date.today(),
      Status__c = 'Information Gathering',
      Region__c = 'The Americas',
      Project_Manager__c = testUser.Id
    );
    testResourceOrders.add(testResourceOrder1);

    Resource_Order__c testResourceOrderWithoutUpdates1 = new Resource_Order__c(
      Name = 'Test Resource Order Without Updates 1',
      Account__c = testAcct.Id,
      LMP_Project__c = testLmpProject.Id,
      Resource_Order_Total__c = 100,
      Submitted_Date__c = Date.today(),
      Status__c = 'Cost Estimate and Proposal',
      Advance_without_Roles__c = true,
      Region__c = 'The Americas',
      Project_Manager__c = testUser.Id
    );
    testResourceOrders.add(testResourceOrderWithoutUpdates1);

    Resource_Order__c testResourceOrderWithoutUpdates2 = new Resource_Order__c(
      Name = 'Test Resource Order Without Updates 2',
      Account__c = testAcct.Id,
      LMP_Project__c = testLmpProject.Id,
      Resource_Order_Total__c = 100,
      Submitted_Date__c = Date.today(),
      Status__c = 'Acceptance and Sales Agreement',
      Advance_without_Roles__c = true,
      Region__c = 'The Americas',
      Project_Manager__c = testUser.Id
    );
    testResourceOrders.add(testResourceOrderWithoutUpdates2);

    Resource_Order__c testResourceOrderWithoutUpdates3 = new Resource_Order__c(
      Name = 'Test Resource Order Without Updates 3',
      Account__c = testAcct.Id,
      LMP_Project__c = testLmpProject.Id,
      Resource_Order_Total__c = 100,
      Submitted_Date__c = Date.today(),
      Status__c = 'Systems Update and Project Details',
      Advance_without_Roles__c = true,
      Region__c = 'The Americas',
      Project_Manager__c = testUser.Id
    );
    testResourceOrders.add(testResourceOrderWithoutUpdates3);

    Resource_Order__c testResourceOrderWithoutUpdates4 = new Resource_Order__c(
      Name = 'Test Resource Order Without Updates 4',
      Account__c = testAcct.Id,
      LMP_Project__c = testLmpProject.Id,
      Resource_Order_Total__c = 100,
      Submitted_Date__c = Date.today(),
      Status__c = 'Production and Delivery',
      Advance_without_Roles__c = true,
      Region__c = 'The Americas',
      Project_Manager__c = testUser.Id
    );
    testResourceOrders.add(testResourceOrderWithoutUpdates4);

    Resource_Order__c testResourceOrderWithoutUpdates5 = new Resource_Order__c(
      Name = 'Test Resource Order Without Updates 5',
      Account__c = testAcct.Id,
      LMP_Project__c = testLmpProject.Id,
      Resource_Order_Total__c = 100,
      Submitted_Date__c = Date.today(),
      Status__c = 'Final Invoice and Payment',
      Advance_without_Roles__c = true,
      Region__c = 'The Americas',
      Project_Manager__c = testUser.Id
    );
    testResourceOrders.add(testResourceOrderWithoutUpdates5);

    insert testResourceOrders;

    List<Status_Update__c> testStatusUpdates = new List<Status_Update__c>();

    Status_Update__c update1 = new Status_Update__c(
      Resource_Order__c = testResourceOrder1.Id,
      Status_Update_Date__c = Date.today().addDays(-8),
      Status_Update__c = '<p>Testing old update.</p>'
    );
    testStatusUpdates.add(update1);

    Status_Update__c update2 = new Status_Update__c(
      Resource_Order__c = testResourceOrder1.Id,
      Status_Update_Date__c = Date.today(),
      Status_Update__c = '<p>Testing new update.</p>'
    );
    testStatusUpdates.add(update2);

    Status_Update__c update3 = new Status_Update__c(
      Resource_Order__c = testResourceOrder1.Id,
      Status_Update_Date__c = Date.today().addDays(-3),
      Status_Update__c = '<p>Testing another new update.</p>'
    );
    testStatusUpdates.add(update3);

    insert testStatusUpdates;

    Email_Recipient__c testEmailRecipient = new Email_Recipient__c(
      Name = 'Jared Smith',
      Email__c = 'jsmith@candoris.com.test',
      Active__c = true,
      Greeting__c = 'Hello Mr. Smith,',
      Region__c = 'The Americas'
    );
    insert testEmailRecipient;

    Test.startTest();

    System.schedule('Test Status Update Email Job', '0 0 6 ? * MON *', new StatusUpdateEmailJob());
    Id batchId = Database.executeBatch(new StatusUpdateEmailJob(), 10);

    Test.stopTest();

    AsyncApexJob job = [
      SELECT Id, Status, NumberOfErrors
      FROM AsyncApexJob
      WHERE Id = :batchId
      LIMIT 1
    ];

    System.assertEquals('Completed', job.Status);
    System.assertEquals(0, job.NumberOfErrors);
  }

  @isTest
  private static void testStatusUpdateEmailJobWithMissingData() {
    Contact testCon = new Contact(FirstName = 'Jared', LastName = 'Smith');
    insert testCon;

    List<Prayer_Request__c> testPrayerReqs = new List<Prayer_Request__c>();

    Account testAcct = [
      SELECT Id, Primary_Partnership_Manager__r.LastName
      FROM Account
      WHERE Name = 'Test Account'
      LIMIT 1
    ];

    Project__c testLmpProject = [
      SELECT Id, Counter__c, General_Accounting_Unit__r.Purpose_Code__c
      FROM Project__c
      WHERE Name = 'Test Project'
      LIMIT 1
    ];

    User testUser = [SELECT Id FROM User WHERE Username = 'email@biblica.com.test' LIMIT 1];

    Resource_Order__c testResourceOrder = new Resource_Order__c(
      Name = 'Test Resource Order',
      Account__c = testAcct.Id,
      LMP_Project__c = testLmpProject.Id,
      Resource_Order_Total__c = 100,
      Submitted_Date__c = Date.today(),
      Region__c = 'The Americas',
      Project_Manager__c = testUser.Id,
      Advance_without_Roles__c = true,
      Status__c = 'Complete'
    );
    insert testResourceOrder;

    Status_Update__c testOldStatusUpdate = new Status_Update__c(
      Resource_Order__c = testResourceOrder.Id,
      Status_Update_Date__c = Date.today().addDays(-8),
      Status_Update__c = '<p>Testing old update.</p>'
    );
    insert testOldStatusUpdate;

    Email_Recipient__c testEmailRecipient = new Email_Recipient__c(
      Name = 'Jared Smith',
      Email__c = 'jsmith@candoris.com.test',
      Active__c = true,
      Greeting__c = 'Hello Mr. Smith,',
      Region__c = 'The Americas'
    );
    insert testEmailRecipient;

    Test.startTest();

    System.schedule('Test Status Update Email Job', '0 0 0 ? * MON *', new StatusUpdateEmailJob());
    Id batchId = Database.executeBatch(new StatusUpdateEmailJob(), 10);

    Test.stopTest();

    AsyncApexJob job = [
      SELECT Id, Status, NumberOfErrors
      FROM AsyncApexJob
      WHERE Id = :batchId
      LIMIT 1
    ];

    System.assertEquals('Completed', job.Status);
    System.assertEquals(0, job.NumberOfErrors);
  }

  @isTest
  private static void testSchedule() {
    // List<CronTrigger> scheduledJobs = [
    //   SELECT Id, CronJobDetail.Name
    //   FROM CronTrigger
    //   WHERE CronJobDetail.Name = 'Status Update Email Job'
    // ];

    // System.assertEquals(0, scheduledJobs.size());

    Test.startTest();
    StatusUpdateEmailJob.schedule();
    Test.stopTest();

    List<CronTrigger> scheduledJobs = [
      SELECT Id, CronJobDetail.Name
      FROM CronTrigger
      WHERE CronJobDetail.Name = 'Status Update Email Job'
    ];

    System.assertEquals(1, scheduledJobs.size());
  }

  @isTest
  private static void testUnschedule() {
    StatusUpdateEmailJob.schedule();

    List<CronTrigger> scheduledJobs = [
      SELECT Id, CronJobDetail.Name
      FROM CronTrigger
      WHERE CronJobDetail.Name = 'Status Update Email Job'
    ];

    System.assertEquals(1, scheduledJobs.size());

    Test.startTest();
    StatusUpdateEmailJob.unschedule();
    Test.stopTest();

    scheduledJobs = [
      SELECT Id, CronJobDetail.Name
      FROM CronTrigger
      WHERE CronJobDetail.Name = 'Status Update Email Job'
    ];

    System.assertEquals(0, scheduledJobs.size());
  }
}