global class ProjectNarrativeJob implements Database.Batchable<sObject>, Schedulable {
  public static final String CRON_EXP = '0 0 2 1 1/1 ? *';
  private Integer batchSize = 200;
  String query;

  global Database.QueryLocator start(Database.BatchableContext BC) {
    this.query = 'SELECT ' + getQueryFields() + ' FROM Project__c WHERE Status__c != \'Complete\' AND Status__c != \'Cancelled\' AND RecordType.Name = \'Language Ministry Project\'';
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<Project__c> projectList) {
    ProjectNarrativeJobService.createNarratives(projectList);
  }

  global void finish(Database.BatchableContext BC) {}

  global void execute(SchedulableContext sc) {
    Database.executeBatch(this, this.batchSize);
  }

  global static String schedule(String jobName, String cron) {
    jobName = jobName != null ? jobName : 'Project Narrative Job';
    cron = cron != null ? cron : ProjectNarrativeJob.CRON_EXP;
    return System.schedule(jobName, cron, new ProjectNarrativeJob());
  }

  private String getQueryFields() {
    Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Project__c.fields.getMap();

    List<String> fields = new List<String>();
    for (Schema.SObjectField sObjField : fieldMap.values()) {
        Schema.DescribeFieldResult dfr = sObjField.getDescribe();
        fields.add(dfr.getName());
    }

    String fieldString = String.join(fields, ',');
    return fieldString;
  }
}