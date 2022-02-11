global class GetClickUpProjectJob implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts {
  public static final String CRON_EXP = '0 0 0 1 1/1 ? *';
  String query;
  private Id projectId;

  global GetClickUpProjectJob(){}
  
  global GetClickUpProjectJob(Id projectId){
    this.projectId = projectId;
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    this.query = 'SELECT Id, Clickup_External_ID__c, Name, Clickup_Space__c, ' +
                    '(SELECT Id, Clickup_External_Id__c FROM Project_Deliverables__r WHERE Clickup_External_Id__c != null) ' +
                    'FROM Project__c WHERE (Status__c = \'Planning\' OR Status__c = \'In Progress\' OR Status__c = \'Proposal\') AND Clickup_External_ID__c != null';
    if (projectId != null){
      this.query += ' AND Id = \'' + projectId + '\'';
    }
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<Project__c> projectList) {
    GetClickUpProjectJobService.createClickUpSnapshot(projectList);
  }

  global void finish(Database.BatchableContext BC) {}

  global void execute(SchedulableContext sc) {
    Database.executeBatch(this, 1);
  }

  @AuraEnabled
  public static void getOneClickUpProject(Id projectId){
    Database.executeBatch(new GetClickUpProjectJob(projectId), 1);
  }

}