public without sharing class ProjectNarrativeJobService {
  
  public static void createNarratives(List<Project__c> projects) {
    List<Narrative__c> narrativesToCreate = new List<Narrative__c>();
    for (Project__c proj : projects){
      Narrative__c n = new Narrative__c(
        Project__c = proj.Id,
        Date__c = Date.today(),
        Status__c = 'Pending',
        RecordTypeId = getNarrativeRecordType()
      );
      narrativesToCreate.add(n);
    }
    if (!narrativesToCreate.isEmpty()){
      insert narrativesToCreate;
    }
    List<Task> tasksToCreate = new List<Task>();
    Integer numberOfDays = Date.daysInMonth(Date.today().year(), Date.today().month());
    Date lastDayOfMonth = Date.newInstance(Date.today().year(), Date.today().month(), numberOfDays);
    for (Narrative__c n : [
      SELECT Id, Project__r.Partnership_Director__c 
      FROM Narrative__c 
      WHERE Id IN :narrativesToCreate]
    ){
      if (n.Project__r.Partnership_Director__c != null){
        Task t = new Task(
          Subject = 'Complete Narrative',
          ActivityDate = lastDayOfMonth,
          OwnerId = n.Project__r.Partnership_Director__c,
          WhatId = n.Id
        );
        tasksToCreate.add(t);
      }
    }
    if (!tasksToCreate.isEmpty()){
      insert tasksToCreate;
    }
  }

  private static Id getNarrativeRecordType(){
    List<Integer> quarterlyMonths = new List<Integer>{1, 4, 7, 10};
    if (quarterlyMonths.contains(Date.today().month())){
      return Schema.SObjectType.Narrative__c.getRecordTypeInfosByName().get('Language Ministry Project - Quarterly').getRecordTypeId();
    } else {
      return Schema.SObjectType.Narrative__c.getRecordTypeInfosByName().get('Language Ministry Project - Monthly').getRecordTypeId();
    }
  }
}