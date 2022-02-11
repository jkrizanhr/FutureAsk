@isTest
private class ResourceOrderServiceTest {
  @testSetup
  private static void makeData() {
    // Insert the default custom setting for all tests.
    Resource_Order_Name__c testResourceOrderName = new Resource_Order_Name__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      Counter__c = 0
    );
    insert testResourceOrderName;
  }

  private static void createInitialLmpTestData() {
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
  private static void testResourceOrderNamingInsert() {
    createInitialLmpTestData();

    User testUser = [SELECT Id FROM User WHERE Username = 'email@biblica.com.test' LIMIT 1];

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

    Resource_Order__c testResourceOrder = new Resource_Order__c(
      Name = 'Test Resource Order',
      Account__c = testAcct.Id,
      LMP_Project__c = testLmpProject.Id,
      Resource_Order_Total__c = 100,
      Submitted_Date__c = Date.today(),
      Partnership_Director__c = testUser.Id
    );

    Test.startTest();
    insert testResourceOrder;
    Test.stopTest();

    Resource_Order__c updatedResourceOrder = [
      SELECT
        Name,
        Submitted_Date__c,
        Partnership_Director__r.LastName,
        LMP_Project__r.Counter__c,
        LMP_Project__r.General_Accounting_Unit__r.Purpose_Code__c
      FROM Resource_Order__c
      WHERE Id = :testResourceOrder.Id
      LIMIT 1
    ];

    String expectedFormattedDate =
      String.valueOf(updatedResourceOrder.Submitted_Date__c.month()).leftPad(2, '0') +
      '/' +
      String.valueOf(updatedResourceOrder.Submitted_Date__c.year());

    String expectedName = (updatedResourceOrder.LMP_Project__r.General_Accounting_Unit__r.Purpose_Code__c +
    ' - ' +
    (String.valueOf(updatedResourceOrder.LMP_Project__r.Counter__c - 1).leftPad(4, '0')) +
    ' - No Items - ' +
    updatedResourceOrder.Partnership_Director__r.LastName +
    ' - ' +
    expectedFormattedDate);

    System.assertEquals(expectedName, updatedResourceOrder.Name);
  }

  @isTest
  private static void testResourceOrderNamingUpdate() {
    createInitialLmpTestData();

    User testUser = [SELECT Id FROM User WHERE Username = 'email@biblica.com.test' LIMIT 1];

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

    Resource__c testResource = [
      SELECT Id, Name
      FROM Resource__c
      WHERE Name = 'Test Resource'
      LIMIT 1
    ];

    Resource_Order__c testResourceOrder = new Resource_Order__c(
      Name = 'Test Resource Order',
      Account__c = testAcct.Id,
      LMP_Project__c = testLmpProject.Id,
      Resource_Order_Total__c = 100,
      Submitted_Date__c = Date.today()
    );
    insert testResourceOrder;

    Resource_Order_Item__c testResourceOrderItem = new Resource_Order_Item__c(
      Resource__c = testResource.Id,
      Resource_Order__c = testResourceOrder.Id,
      Quantity__c = 5
    );
    insert testResourceOrderItem;

    Test.startTest();

    Fund_GL_Account__c newTestGlAcct = new Fund_GL_Account__c(
      Name = 'Test Fund GL Account 2',
      GL_Account_External_Id__c = 'XYZ123',
      GL_Account_Prefix__c = 'TEST',
      GL_Account__c = 'Testing GL Account',
      Active__c = true
    );
    insert newTestGlAcct;

    npsp__General_Accounting_Unit__c newTestGau = new npsp__General_Accounting_Unit__c(
      Name = 'Test GAU',
      Purpose_Code__c = '1515',
      Default_Fund_GL_Account__c = newTestGlAcct.Id
    );
    insert newTestGau;

    testLmpProject.General_Accounting_Unit__c = newTestGau.Id;
    update testLmpProject;

    testResourceOrder.Name = 'Test Update';
    testResourceOrder.Partnership_Director__c = testUser.Id;
    update testResourceOrder;

    Test.stopTest();

    Resource_Order__c updatedResourceOrder = [
      SELECT
        Name,
        Submitted_Date__c,
        Partnership_Director__r.LastName,
        LMP_Project__r.Counter__c,
        LMP_Project__r.General_Accounting_Unit__r.Purpose_Code__c
      FROM Resource_Order__c
      WHERE Id = :testResourceOrder.Id
      LIMIT 1
    ];

    String expectedFormattedDate =
      String.valueOf(updatedResourceOrder.Submitted_Date__c.month()).leftPad(2, '0') +
      '/' +
      String.valueOf(updatedResourceOrder.Submitted_Date__c.year());

    String expectedName = (updatedResourceOrder.LMP_Project__r.General_Accounting_Unit__r.Purpose_Code__c +
    ' - ' +
    (String.valueOf(updatedResourceOrder.LMP_Project__r.Counter__c - 1).leftPad(4, '0')) +
    ' - Test Resource - ' +
    updatedResourceOrder.Partnership_Director__r.LastName +
    ' - ' +
    expectedFormattedDate);

    System.assertEquals(expectedName, updatedResourceOrder.Name);
  }

  @isTest
  private static void testResourceOrderNamingUpdateWithMultipleResources() {
    createInitialLmpTestData();

    User testUser = [SELECT Id FROM User WHERE Username = 'email@biblica.com.test' LIMIT 1];

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

    List<Resource__c> testResources = new List<Resource__c>();

    Resource__c testResource1 = new Resource__c(
      Name = 'Resource That Has An Unusually Long Name For Truncation',
      Retail_Value__c = 10
    );
    testResources.add(testResource1);

    Resource__c testResource2 = new Resource__c(Name = 'Resource Small', Retail_Value__c = 10);
    testResources.add(testResource2);

    insert testResources;

    Resource_Order__c testResourceOrder = new Resource_Order__c(
      Name = 'Test Resource Order',
      Account__c = testAcct.Id,
      LMP_Project__c = testLmpProject.Id,
      Resource_Order_Total__c = 100,
      Submitted_Date__c = Date.today(),
      Partnership_Director__c = testUser.Id
    );
    insert testResourceOrder;

    List<Resource_Order_Item__c> testResourceOrderItems = new List<Resource_Order_Item__c>();

    Resource_Order_Item__c testResourceOrderItem1 = new Resource_Order_Item__c(
      Resource__c = testResource1.Id,
      Resource_Order__c = testResourceOrder.Id,
      Quantity__c = 5
    );
    testResourceOrderItems.add(testResourceOrderItem1);

    Resource_Order_Item__c testResourceOrderItem2 = new Resource_Order_Item__c(
      Resource__c = testResource2.Id,
      Resource_Order__c = testResourceOrder.Id,
      Quantity__c = 3
    );
    testResourceOrderItems.add(testResourceOrderItem2);

    insert testResourceOrderItems;

    Test.startTest();

    Fund_GL_Account__c newTestGlAcct = new Fund_GL_Account__c(
      Name = 'Test Fund GL Account 2',
      GL_Account_External_Id__c = 'XYZ123',
      GL_Account_Prefix__c = 'TEST',
      GL_Account__c = 'Testing GL Account',
      Active__c = true
    );
    insert newTestGlAcct;

    npsp__General_Accounting_Unit__c newTestGau = new npsp__General_Accounting_Unit__c(
      Name = 'Test GAU',
      Purpose_Code__c = '1515',
      Default_Fund_GL_Account__c = newTestGlAcct.Id
    );
    insert newTestGau;

    testLmpProject.General_Accounting_Unit__c = newTestGau.Id;
    update testLmpProject;

    testResourceOrder.Name = 'Test Update';
    update testResourceOrder;

    Test.stopTest();

    Resource_Order__c updatedResourceOrder = [
      SELECT
        Name,
        Submitted_Date__c,
        Partnership_Director__r.LastName,
        LMP_Project__r.Counter__c,
        LMP_Project__r.General_Accounting_Unit__r.Purpose_Code__c
      FROM Resource_Order__c
      WHERE Id = :testResourceOrder.Id
      LIMIT 1
    ];

    String expectedFormattedDate =
      String.valueOf(updatedResourceOrder.Submitted_Date__c.month()).leftPad(2, '0') +
      '/' +
      String.valueOf(updatedResourceOrder.Submitted_Date__c.year());

    String expectedName = (updatedResourceOrder.LMP_Project__r.General_Accounting_Unit__r.Purpose_Code__c +
    ' - ' +
    (String.valueOf(updatedResourceOrder.LMP_Project__r.Counter__c - 1).leftPad(4, '0')) +
    ' - Resource That Has An Unusually Long Name Fo... - ' +
    updatedResourceOrder.Partnership_Director__r.LastName +
    ' - ' +
    expectedFormattedDate);

    System.assertEquals(expectedName, updatedResourceOrder.Name);
  }

  @isTest
  private static void testResourceOrderNamingWithoutProject() {
    createInitialLmpTestData();

    User testUser = [SELECT Id FROM User WHERE Username = 'email@biblica.com.test' LIMIT 1];

    Account testAcct = [
      SELECT Id, Primary_Partnership_Manager__r.LastName
      FROM Account
      WHERE Name = 'Test Account'
      LIMIT 1
    ];

    Resource_Order__c testResourceOrder = new Resource_Order__c(
      Name = 'Test Resource Order',
      Account__c = testAcct.Id,
      Resource_Order_Total__c = 100,
      Submitted_Date__c = Date.today(),
      Partnership_Director__c = testUser.Id
    );

    Test.startTest();
    insert testResourceOrder;
    Test.stopTest();

    Resource_Order__c updatedResourceOrder = [
      SELECT Name, Submitted_Date__c, Partnership_Director__r.LastName
      FROM Resource_Order__c
      WHERE Id = :testResourceOrder.Id
      LIMIT 1
    ];

    Project__c updatedTestLmpProject = [
      SELECT Id, Counter__c, General_Accounting_Unit__r.Purpose_Code__c
      FROM Project__c
      WHERE Name = 'Test Project'
      LIMIT 1
    ];

    String expectedFormattedDate =
      String.valueOf(updatedResourceOrder.Submitted_Date__c.month()).leftPad(2, '0') +
      '/' +
      String.valueOf(updatedResourceOrder.Submitted_Date__c.year());

    Resource_Order_Name__c defaultCounter = Resource_Order_Name__c.getOrgDefaults();

    String expectedName = ('9999 - ' +
    (String.valueOf(defaultCounter.Counter__c - 1).leftPad(4, '0')) +
    ' - No Items - ' +
    updatedResourceOrder.Partnership_Director__r.LastName +
    ' - ' +
    expectedFormattedDate);
    System.assertEquals(expectedName, updatedResourceOrder.Name);
  }

  @isTest
  public static void ResourceOrderServiceTest() {
    Account acct = new Account(
      Name = 'Test',
      BillingStreet = '123 Test Avenue',
      Website = 'testexample.edu'
    );
    insert acct;

    Account acct2 = new Account(
      Name = 'Account',
      BillingStreet = '456 Different Street',
      Website = 'accountexample.org'
    );
    insert acct2;

    Resource__c r = new Resource__c(Name = 'R', Retail_Value__c = 10);
    insert r;

    Resource_Order__c ro = new Resource_Order__c(
      Name = 'RO1',
      Account__c = acct.Id,
      Resource_Order_Total__c = 100,
      Submitted_Date__c = Date.today()
    );

    Test.startTest();
    //INSERT RESOURCE ORDER
    insert ro;

    Account res1 = [SELECT Id, Total_Orders_Amount__c FROM Account WHERE Id = :acct.Id];
    System.assertEquals(100, res1.Total_Orders_Amount__c);

    //UPDATE RESOURCE ORDER
    ro.Resource_Order_Total__c = 150;
    update ro;

    Account res2 = [SELECT Id, Total_Orders_Amount__c FROM Account WHERE Id = :acct.Id];
    System.assertEquals(150, res2.Total_Orders_Amount__c);

    //UPDATE RESOURCE ORDER
    ro.Account__c = acct2.Id;
    update ro;

    Account res3 = [SELECT Id, Total_Orders_Amount__c FROM Account WHERE Id = :acct2.Id];
    System.assertEquals(150, res3.Total_Orders_Amount__c);

    //DELETE RESOURCE ORDER
    delete ro;

    Account res4 = [SELECT Id, Total_Orders_Amount__c FROM Account WHERE Id = :acct2.Id];
    System.assertEquals(0, res4.Total_Orders_Amount__c);

    //UNDELETE RESOURCE ORDER
    undelete ro;

    Account res5 = [SELECT Id, Total_Orders_Amount__c FROM Account WHERE Id = :acct2.Id];
    System.assertEquals(150, res5.Total_Orders_Amount__c);

    Test.stopTest();
  }

  @isTest
  public static void ProjectRollupsTest() {
    Account acct = new Account(
      Name = 'Test',
      BillingStreet = '123 Test Avenue',
      Website = 'testexample.edu'
    );
    insert acct;

    Project__c p1 = new Project__c(
      Name = 'Test Project',
      Status__c = 'In Progress',
      RecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName()
        .get('Language Ministry Project')
        .getRecordTypeId()
    );
    insert p1;

    Project__c p2 = new Project__c(
      Name = 'Test Project',
      Status__c = 'In Progress',
      RecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName()
        .get('Language Ministry Project')
        .getRecordTypeId()
    );
    insert p2;

    Resource__c r = new Resource__c(Name = 'R', Retail_Value__c = 10, Media_Type__c = 'Print');
    insert r;

    Resource_Order__c ro = new Resource_Order__c(
      Name = 'RO1',
      Account__c = acct.Id,
      LMP_Project__c = p1.Id,
      Submitted_Date__c = Date.today()
    );
    insert ro;

    Resource_Order_Item__c roi = new Resource_Order_Item__c(
      Status__c = 'Ordered',
      Quantity__c = 100,
      Amount__c = 100,
      Resource__c = r.Id,
      Resource_Order__c = ro.Id
    );

    Test.startTest();
    //INSERT RESOURCE ORDER
    insert roi;

    Project__c res1 = [SELECT Id, Print_Reach__c FROM Project__c WHERE Id = :p1.Id];
    System.assertEquals(100, res1.Print_Reach__c);

    //UPDATE RESOURCE ORDER
    roi.Quantity__c = 150;
    update roi;

    Project__c res2 = [SELECT Id, Print_Reach__c FROM Project__c WHERE Id = :p1.Id];
    System.assertEquals(150, res2.Print_Reach__c);

    //UPDATE RESOURCE ORDER
    ro.LMP_Project__c = p2.Id;
    update ro;

    Project__c res3 = [SELECT Id, Print_Reach__c FROM Project__c WHERE Id = :p2.Id];
    System.assertEquals(150, res3.Print_Reach__c);

    Test.stopTest();
  }

  @isTest
  public static void createTasksForResourceOrdersTest() {
    User u = new User(
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator']
      .Id,
      LastName = 'Last',
      Email = 'email@biblica.com.test',
      Username = 'email@biblica.com.test',
      CompanyName = 'Candoris',
      Title = 'Tital',
      Alias = 'alias',
      TimeZoneSidKey = 'America/New_York',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US'
    );
    insert u;

    Account acct = new Account(Name = 'Test Account');
    insert acct;

    Resource_Order__c ro = new Resource_Order__c(
      Name = 'RO1',
      Account__c = acct.Id,
      Submitted_Date__c = Date.today(),
      Status__c = 'Information Gathering',
      Production_Assistant__c = u.Id,
      Project_Manager__c = u.Id,
      Partnership_Director__c = u.Id,
      Partner_Relations_Specialist__c = u.Id
    );
    insert ro;

    //ADD RESOURCE AND RESOURCE ORDER ITEM TO SATISFY VALIDATION RULE
    Resource__c r = new Resource__c(Name = 'R', Retail_Value__c = 10);
    insert r;

    Resource_Order_Item__c roi = new Resource_Order_Item__c(
      Resource__c = r.Id,
      Resource_Order__c = ro.Id,
      Amount__c = 150
    );
    insert roi;

    Test.startTest();
    List<Task> res1 = [SELECT Id FROM Task WHERE WhatId = :ro.Id];
    System.assertEquals(1, res1.size());

    ro.Status__c = 'Cost Estimate and Proposal';
    update ro;
    List<Task> res2 = [SELECT Id FROM Task WHERE WhatId = :ro.Id];
    System.assertEquals(3, res2.size());

    ro.Status__c = 'Acceptance and Sales Agreement';
    update ro;
    List<Task> res3 = [SELECT Id FROM Task WHERE WhatId = :ro.Id];
    System.assertEquals(5, res3.size());

    ro.Status__c = 'Systems Update and Project Details';
    update ro;
    List<Task> res4 = [SELECT Id FROM Task WHERE WhatId = :ro.Id];
    System.assertEquals(7, res4.size());

    ro.Status__c = 'Production and Delivery';
    update ro;
    List<Task> res5 = [SELECT Id FROM Task WHERE WhatId = :ro.Id];
    System.assertEquals(13, res5.size());

    ro.Status__c = 'Final Invoice and Payment';
    update ro;
    List<Task> res6 = [SELECT Id FROM Task WHERE WhatId = :ro.Id];
    System.assertEquals(16, res6.size());
    Test.stopTest();
  }
}