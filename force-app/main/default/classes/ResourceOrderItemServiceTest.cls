@isTest
private class ResourceOrderItemServiceTest {
  @testSetup
  private static void makeData() {
    // Insert the default custom setting for all tests.
    Resource_Order_Name__c testResourceOrderName = new Resource_Order_Name__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      Counter__c = 0
    );
    insert testResourceOrderName;
  }

  @isTest
  public static void ResourceOrderItemServiceTest() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    Resource__c r = new Resource__c(Name = 'R', Retail_Value__c = 10, Media_Type__c = 'Print');
    insert r;

    Project__c p = new Project__c(
      Name = 'Test Project',
      Status__c = 'In Progress',
      RecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName()
        .get('Language Ministry Project')
        .getRecordTypeId()
    );
    insert p;

    Resource_Order__c ro = new Resource_Order__c(
      Name = 'RO1',
      Account__c = acct.Id,
      LMP_Project__c = p.Id,
      Submitted_Date__c = Date.today()
    );
    insert ro;

    Resource_Order_Item__c roi = new Resource_Order_Item__c(
      Status__c = 'Ordered',
      Quantity__c = 10,
      Amount__c = 100,
      Resource__c = r.Id,
      Resource_Order__c = ro.Id
    );

    Test.startTest();
    //INSERT RESOURCE ORDER ITEM
    insert roi;

    Resource_Order__c res1 = [
      SELECT Id, Resource_Order_Total__c
      FROM Resource_Order__c
      WHERE Id = :ro.Id
    ];
    System.assertEquals(100, res1.Resource_Order_Total__c);
    Project__c proj_res1 = [SELECT Id, Print_Reach__c FROM Project__c WHERE Id = :p.Id];
    System.assertEquals(10, proj_res1.Print_Reach__c);

    //UPDATE RESOURCE ORDER ITEM
    roi.Amount__c = 150;
    update roi;

    Resource_Order__c res2 = [
      SELECT Id, Resource_Order_Total__c
      FROM Resource_Order__c
      WHERE Id = :ro.Id
    ];
    System.assertEquals(150, res2.Resource_Order_Total__c);
    Project__c proj_res2 = [SELECT Id, Print_Reach__c FROM Project__c WHERE Id = :p.Id];
    System.assertEquals(10, proj_res2.Print_Reach__c);

    //UPDATE RESOURCE ORDER ITEM
    roi.Status__c = 'Cancelled';
    update roi;

    Resource_Order__c res3 = [
      SELECT Id, Resource_Order_Total__c
      FROM Resource_Order__c
      WHERE Id = :ro.Id
    ];
    System.assertEquals(0, res3.Resource_Order_Total__c);
    Project__c proj_res3 = [SELECT Id, Print_Reach__c FROM Project__c WHERE Id = :p.Id];
    System.assertEquals(0, proj_res3.Print_Reach__c);

    //DELETE RESOURCE ORDER ITEM
    roi.Status__c = 'Ordered';
    update roi;
    delete roi;

    Resource_Order__c res4 = [
      SELECT Id, Resource_Order_Total__c
      FROM Resource_Order__c
      WHERE Id = :ro.Id
    ];
    System.assertEquals(0, res4.Resource_Order_Total__c);
    Project__c proj_res4 = [SELECT Id, Print_Reach__c FROM Project__c WHERE Id = :p.Id];
    System.assertEquals(0, proj_res4.Print_Reach__c);

    //UNDELETE RESOURCE ORDER ITEM
    undelete roi;

    Resource_Order__c res5 = [
      SELECT Id, Resource_Order_Total__c
      FROM Resource_Order__c
      WHERE Id = :ro.Id
    ];
    System.assertEquals(150, res5.Resource_Order_Total__c);
    Project__c proj_res5 = [SELECT Id, Print_Reach__c FROM Project__c WHERE Id = :p.Id];
    System.assertEquals(10, proj_res5.Print_Reach__c);

    Test.stopTest();
  }

  @isTest
  public static void copyShippingAddressFromAccountTest() {
    Account acct = new Account(
      Name = 'Test Account',
      ShippingStreet = '123 Test Street',
      ShippingCity = 'New York',
      ShippingState = 'New York',
      ShippingPostalCode = '12345',
      ShippingCountry = 'United States'
    );
    insert acct;

    Resource__c r = new Resource__c(Name = 'R', Retail_Value__c = 10);
    insert r;

    Resource_Order__c ro = new Resource_Order__c(
      Name = 'RO1',
      Account__c = acct.Id,
      Submitted_Date__c = Date.today()
    );
    insert ro;

    Resource_Order_Item__c roi1 = new Resource_Order_Item__c(
      Status__c = 'Ordered',
      Amount__c = 100,
      Same_Address_as_Account__c = true,
      Resource__c = r.Id,
      Resource_Order__c = ro.Id
    );

    Resource_Order_Item__c roi2 = new Resource_Order_Item__c(
      Status__c = 'Ordered',
      Amount__c = 200,
      Same_Address_as_Account__c = false,
      Resource__c = r.Id,
      Resource_Order__c = ro.Id
    );
    insert roi2;

    Test.startTest();
    //INSERT RESOURCE ORDER ITEM 1
    insert roi1;

    //UPDATE RESOURCE ORDER ITEM 2
    roi2.Same_Address_as_Account__c = true;
    update roi2;

    List<Resource_Order_Item__c> resList = [
      SELECT Id, Street_Address__c, City__c, State_Province__c, Postal_Code__c, Country__c
      FROM Resource_Order_Item__c
      WHERE Resource__c = :r.Id
    ];
    for (Resource_Order_Item__c res : resList) {
      System.assertEquals(acct.ShippingStreet, res.Street_Address__c);
      System.assertEquals(acct.ShippingCity, res.City__c);
      System.assertEquals(acct.ShippingState, res.State_Province__c);
      System.assertEquals(acct.ShippingPostalCode, res.Postal_Code__c);
      System.assertEquals(acct.ShippingCountry, res.Country__c);
    }
    Test.stopTest();
  }
}