@isTest
private class DigitalResourceOrdersCtrlTest {
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
  public static void testDigitalResourceOrdersCtrl() {
    Account acct = new Account(
      Name = 'Test Account'
    );
    insert acct;

    Resource__c r = new Resource__c(
      Name = 'R',
      Retail_Value__c = 10
    );
    insert r;

    Resource_Order__c ro = new Resource_Order__c(
      Name = 'RO1',
      Account__c = acct.Id
    );
    insert ro;

    Resource_Order_Item__c roi1 = new Resource_Order_Item__c(
      Status__c = 'Ordered',
      Amount__c = 100,
      Resource__c = r.Id,
      Resource_Order__c = ro.Id
    );
    insert roi1;
    
    Resource_Order_Item__c roi2 = new Resource_Order_Item__c(
      Status__c = 'Ordered',
      Amount__c = 100,
      Resource__c = r.Id,
      Resource_Order__c = ro.Id
    );
    insert roi2;

    Test.startTest();
    Account res1 = DigitalResourceOrdersCtrl.fetchData(acct.Id);
    System.assertNotEquals(null, res1);

    DigitalResourceOrdersCtrl.deleteResourceOrderItem(roi1.Id);
    List<Resource_Order_Item__c> res2 = [SELECT Id FROM Resource_Order_Item__c WHERE Id =: roi1.Id];
    System.assertEquals(true, res2.isEmpty());
    
    DigitalResourceOrdersCtrl.deleteResourceOrder(ro.Id);
    List<Resource_Order__c> res3 = [SELECT Id FROM Resource_Order__c WHERE Id =: ro.Id];
    System.assertEquals(true, res3.isEmpty());
    List<Resource_Order_Item__c> res4 = [SELECT Id FROM Resource_Order_Item__c WHERE Id =: roi2.Id];
    System.assertEquals(true, res4.isEmpty());

  }
}