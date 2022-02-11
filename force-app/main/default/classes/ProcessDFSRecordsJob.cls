public without sharing class ProcessDFSRecordsJob implements Database.Batchable<SObject>, Schedulable {
  private static final String JOB_NAME = 'Process Stuck DFS Records Job';

  public void execute(SchedulableContext sc) {
    Database.executeBatch(this, 1);
  }

  public static void schedule(String cronExp) {
    unschedule();
    System.schedule(JOB_NAME, cronExp, new ProcessDFSRecordsJob());
  }

  public static void unschedule() {
    List<CronTrigger> scheduledJobs = [
      SELECT Id, CronJobDetail.Name
      FROM CronTrigger
      WHERE CronJobDetail.Name = :JOB_NAME
    ];

    if (!scheduledJobs.isEmpty()) {
      System.abortJob(scheduledJobs[0].Id);
    }
  }

  public static void schedule() {
    String cron = '0 0 0 1/1 * ? *';
    schedule(cron);
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Donation_Form_Submission__c.fields.getMap();
    List<String> fields = new List<String>();

    for (Schema.SObjectField sObjField : fieldMap.values()) {
      Schema.DescribeFieldResult dfr = sObjField.getDescribe();
      fields.add(dfr.getName());
    }

    // Added condition that submission date must be greater than 3/1/21 to prevent old failed records from being processed
    String dfsFields = String.join(fields, ',');
    String dfsQuery =
      'SELECT ' +
      dfsFields +
      ' FROM Donation_Form_Submission__c WHERE Opportunity__c = NULL AND Has_Errors__c = FALSE AND Submission_Date__c > 2021-03-01 AND (Payment_Processor_Transaction_Id__c != NULL OR Payment_Processor_Subscription_Id__c != NULL)';
    return Database.getQueryLocator(dfsQuery);
  }

  public void execute(
    Database.BatchableContext bc,
    List<Donation_Form_Submission__c> formSubmissions
  ) {
    new DonationPageProcessor(formSubmissions).run();
  }

  public void finish(Database.BatchableContext bc) {
  }
}