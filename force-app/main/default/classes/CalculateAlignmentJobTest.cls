@isTest
private class CalculateAlignmentJobTest {
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
  static void testCalculateAlignmentJob() {
    Account acct = new Account(
      Name = 'Test Account'
    );
    insert acct;
    
    Project__c proj = new Project__c(
      Name = 'Test Project',
      RecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Language Ministry Project').getRecordTypeId()
    );
    insert proj;
    
    Project_Partner__c pp = new Project_Partner__c(
      Project_Record_Type__c = 'MPP',
      Project__c = proj.Id,
      Account__c = acct.Id
    );
    insert pp;

    Resource__c r = new Resource__c(
      Name = 'R',
      Retail_Value__c = 10
    );
    insert r;

    Resource_Order__c ro = new Resource_Order__c(
      Name = 'RO1',
      Account__c = acct.Id,
      Submitted_Date__c = Date.today(),
      Total_Order_Quanity__c = 100
    );
    insert ro;

    Test.startTest();
      Database.executeBatch(new CalculateAlignmentJob());
    Test.stopTest();

    Account res = [SELECT Id, Number_of_MPP_Projects__c, Number_of_Resource_Item_Quantity__c, Number_of_Resource_Orders__c, Number_of_TPP_Projects__c FROM Account WHERE Id = :acct.Id];
    System.debug(res);
    System.assertEquals(0, res.Number_of_TPP_Projects__c);
    System.assertEquals(1, res.Number_of_MPP_Projects__c);
    System.assertEquals(1, res.Number_of_Resource_Orders__c);
    System.assertEquals(100, res.Number_of_Resource_Item_Quantity__c);
  }
}