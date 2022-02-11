@isTest
private class ProjectPartnerServiceTest {
    
  @isTest
  static void rollupNumberOfProjectsToAccountTest() {
    Project__c proj = new Project__c(
      Name = 'Test Project',
      RecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Language Ministry Project').getRecordTypeId()
    );
    insert proj;

    Account acct = new Account(
      Name = 'Test Account'
    );
    insert acct;
    
    Project_Partner__c pp = new Project_Partner__c(
      Project__c = proj.Id,
      Account__c = acct.Id
    );

    Test.startTest();
      //TEST INSERT PROJECT PARTNER
      insert pp;

      Account res1 = [SELECT Id, Number_of_MPP_Projects__c, Number_of_TPP_Projects__c FROM Account WHERE Id = :acct.Id];
      System.assertEquals(1, res1.Number_of_MPP_Projects__c);
      System.assertEquals(0, res1.Number_of_TPP_Projects__c);
      
      //TEST UPDATE PROJECT PARTNER
      proj.RecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Language Translation Plan').getRecordTypeId();
      update proj;

      Project_Partner__c res2 = [SELECT Id, Project_Record_Type__c FROM Project_Partner__c WHERE Id = :pp.Id];
      System.assertEquals('Language Translation Plan', res2.Project_Record_Type__c);        

      Account res3 = [SELECT Id, Number_of_MPP_Projects__c, Number_of_TPP_Projects__c FROM Account WHERE Id = :acct.Id];
      System.assertEquals(0, res3.Number_of_MPP_Projects__c);
      System.assertEquals(1, res3.Number_of_TPP_Projects__c);
      
      //TEST DELETE PROJECT PARTNER
      delete pp;

      Account res4 = [SELECT Id, Number_of_MPP_Projects__c, Number_of_TPP_Projects__c FROM Account WHERE Id = :acct.Id];
      System.assertEquals(0, res4.Number_of_MPP_Projects__c);
      System.assertEquals(0, res4.Number_of_TPP_Projects__c);
      
      //TEST UNDELETE PROJECT PARTNER
      undelete pp;

      Account res5 = [SELECT Id, Number_of_MPP_Projects__c, Number_of_TPP_Projects__c FROM Account WHERE Id = :acct.Id];
      System.assertEquals(0, res5.Number_of_MPP_Projects__c);
      System.assertEquals(1, res5.Number_of_TPP_Projects__c);

    Test.stopTest();
  }
}