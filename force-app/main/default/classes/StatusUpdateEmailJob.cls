public without sharing class StatusUpdateEmailJob implements Database.Batchable<sObject>, Schedulable {
  public StatusUpdateEmailJob() {
  }

  public List<Resource_Order__c> start(Database.BatchableContext bc) {
    return [
      SELECT
        Id,
        Name,
        Region__c,
        Contact__c,
        Contact__r.Email,
        Project_Manager__c,
        Project_Manager__r.Name,
        Status__c,
        (
          SELECT Id, Status_Update_Date__c, Status_Update__c
          FROM Status_Updates__r
          ORDER BY Status_Update_Date__c DESC
        )
      FROM Resource_Order__c
      WHERE
        Project_Manager__c != NULL
        AND Region__c != NULL
        AND Status__c NOT IN ('Cancelled', 'Complete', 'On Hold')
      ORDER BY Region__c ASC, Project_Manager__r.Name ASC
    ];
  }

  public void execute(Database.BatchableContext bc, List<Resource_Order__c> resourceOrders) {
    StatusUpdateEmailJobService.run(resourceOrders);
  }

  public void execute(SchedulableContext sc) {
    Database.executeBatch(this);
  }

  public static void schedule(String cronExp) {
    unschedule();
    System.schedule('Status Update Email Job', cronExp, new StatusUpdateEmailJob());
  }

  public static void schedule() {
    String cron = '0 0 6 ? * MON *';
    schedule(cron);
  }

  public static void unschedule() {
    List<CronTrigger> scheduledJobs = [
      SELECT Id, CronJobDetail.Name
      FROM CronTrigger
      WHERE CronJobDetail.Name = 'Status Update Email Job'
    ];

    if (!scheduledJobs.isEmpty()) {
      System.abortJob(scheduledJobs[0].Id);
    }
  }

  public void finish(Database.BatchableContext bc) {
  }
}