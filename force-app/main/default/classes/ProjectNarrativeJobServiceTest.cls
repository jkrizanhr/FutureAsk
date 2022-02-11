@isTest
private class ProjectNarrativeJobServiceTest {
  
  @isTest
  static void testProjectNarrativeJob(){
    Profile pr = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    User u = new User(
      Alias = 'test',
      Email = 'testProjectNarrativeJob@test.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Test',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = pr.Id,
      TimeZoneSidKey = 'America/New_York',
      UserName = 'testProjectNarrativeJob@test.com');
    insert u;
    
    List<Project__c> projects = new List<Project__c>();
    Id rt = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Language Ministry Project').getRecordTypeId();
    Project__c p1 = new Project__c(
      Name = 'Test Project 1',
      Partnership_Director__c = u.Id,
      Status__c = 'Planning',
      RecordTypeId = rt
    );
    projects.add(p1);

    Project__c p2 = new Project__c(
      Name = 'Test Project 2',
      Status__c = 'In Progress',
      RecordTypeId = rt
    );
    projects.add(p2);

    Project__c p3 = new Project__c(
      Name = 'Test Project 3',
      Partnership_Director__c = u.Id,
      Status__c = 'Complete',
      RecordTypeId = rt
    );
    projects.add(p3);

    insert projects;

    Test.startTest();
    Database.executeBatch(new ProjectNarrativeJob());
    Test.stopTest();
    
    // CHECK THE NUMBER OF NARRATIVES CREATED
    List<Narrative__c> narratives = [SELECT Id FROM Narrative__c WHERE Project__c IN :projects];
    System.AssertEquals(2, narratives.size(), 'Only two narratives should have been created.');
    
    // CHECK THE NUMBER OF TASKS CREATED
    List<Task> tasks = [SELECT Id FROM Task WHERE WhatId IN :narratives];
    System.AssertEquals(1, tasks.size(), 'Only one task should have been created.');
    
    // CHECK VALUES WERE SET CORRECTLY FOR PROJECT WITH PROJECT MANAGER
    Narrative__c n1 = [SELECT Id, Date__c, Status__c, Project__c FROM Narrative__c WHERE Project__c = :p1.Id];
    System.AssertEquals(Date.today(), n1.Date__c, 'A narrative should be created with the date equal to today.');
    Task t1 = [SELECT Id, ActivityDate, WhatId, OwnerId FROM Task WHERE WhatId = :n1.Id];
    System.AssertEquals(p1.Partnership_Director__c, t1.OwnerId, 'Task should be assigned to the Project Manager.');
    
    // CHECK VALUES WERE SET CORRECTLY FOR PROJECT WITHOUT PROJECT MANAGER
    Narrative__c n2 = [SELECT Id, Date__c, Status__c, Project__c FROM Narrative__c WHERE Project__c = :p2.Id];
    System.AssertEquals('Pending', n2.Status__c, 'A narrative should be created with a status of pending.');
  }

  @isTest
  static void testScheduleJob(){
    Profile pr = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    User u = new User(
      Alias = 'test',
      Email = 'testProjectNarrativeJob@test.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Test',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = pr.Id,
      TimeZoneSidKey = 'America/New_York',
      UserName = 'testProjectNarrativeJob@test.com');
    insert u;
    
    List<Project__c> projects = new List<Project__c>();
    Id rt = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Language Ministry Project').getRecordTypeId();
    Project__c p1 = new Project__c(
      Name = 'Test Project 1',
      Partnership_Director__c = u.Id,
      Status__c = 'Planning',
      RecordTypeId = rt
    );
    projects.add(p1);

    Project__c p2 = new Project__c(
      Name = 'Test Project 2',
      Status__c = 'In Progress',
      RecordTypeId = rt
    );
    projects.add(p2);

    Project__c p3 = new Project__c(
      Name = 'Test Project 3',
      Partnership_Director__c = u.Id,
      Status__c = 'Complete',
      RecordTypeId = rt
    );
    projects.add(p3);

    insert projects;
    
    Test.startTest();
    ProjectNarrativeJob.schedule(null, null);
    Test.stopTest();
  }
}