@isTest
private class ProjectDeliverableServiceTest {

  @isTest
  static void projectDeliverableRollupToProjectTest() {
    Project__c lmp = new Project__c(
      Name = 'Test Project'
    );
    insert lmp;
    Project__c ltp = new Project__c(
      Name = 'Test Project'
    );
    insert ltp;

    Resource__c translation = new Resource__c(
      Name = 'Bible Translation'        
    );
    Resource__c printBible = new Resource__c(
      Name = 'Print Bible'        
    );
    Resource__c audioBible = new Resource__c(
      Name = 'Audio Bible'        
    );
    insert new List<Resource__c>{translation, printBible, audioBible};

    Project_Deliverable__c bible = new Project_Deliverable__c(
      Name = 'Bible Translation',
      Project__c = lmp.Id,
      Resource__c = translation.Id
    );
    Project_Deliverable__c audio = new Project_Deliverable__c(
      Name = 'Audio Recording',
      Project__c = lmp.Id,
      Resource__c = audioBible.Id
    );
    Project_Deliverable__c noResource = new Project_Deliverable__c(
      Name = 'No Resource',
      Project__c = lmp.Id
    );

    Test.startTest();
      //TEST INSERT
      insert bible;
      Project__c res1 = [SELECT Id, Resources__c FROM Project__c WHERE Id = :lmp.Id LIMIT 1];
      System.assertEquals('Bible Translation', res1.Resources__c);
      
      insert new List<Project_Deliverable__c>{audio, noResource};
      Project__c res2 = [SELECT Id, Resources__c FROM Project__c WHERE Id = :lmp.Id LIMIT 1];
      System.assertEquals('Audio Bible; Bible Translation', res2.Resources__c);
      
      //TEST UPDATE
      bible.Resource__c = printBible.Id;
      update bible;
      Project__c res3 = [SELECT Id, Resources__c FROM Project__c WHERE Id = :lmp.Id LIMIT 1];
      System.assertEquals('Audio Bible; Print Bible', res3.Resources__c);
      
      noResource.Resource__c = printBible.Id;
      update noResource;
      Project__c res4 = [SELECT Id, Resources__c FROM Project__c WHERE Id = :lmp.Id LIMIT 1];
      System.assertEquals('Audio Bible; Print Bible', res4.Resources__c);

      //TEST DELETE
      delete bible;
      delete noResource;
      Project__c res7 = [SELECT Id, Resources__c FROM Project__c WHERE Id = :lmp.Id LIMIT 1];
      System.assertEquals('Audio Bible', res7.Resources__c);
      
      //TEST UNDELETE
      undelete bible;
      Project__c res9 = [SELECT Id, Resources__c FROM Project__c WHERE Id = :lmp.Id LIMIT 1];
      System.assertEquals('Audio Bible; Print Bible', res9.Resources__c);
    Test.stopTest();
  }
}