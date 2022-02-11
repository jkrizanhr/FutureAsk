global without sharing class HistoricalTransactionProcessingJob implements Schedulable, Database.Batchable<sObject> {
  public static final String CRON_EXP = '0 0 0/1 1/1 * ? *';

  global static String schedule(String jobName, String cron) {
    if (jobName == null) {
      jobName = 'Historical Transaction Processing Job';
    }
    if (cron == null) {
      cron = HistoricalTransactionProcessingJob.CRON_EXP;
    }
    return System.schedule(jobName, cron, new HistoricalTransactionProcessingJob());
  }

  global void execute(SchedulableContext sc) {
    Database.executeBatch(this, 1);
  }

  global static void run() {
    Database.executeBatch(new HistoricalTransactionProcessingJob(), 1);
  }

  private String getQueryFields() {
    Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Historical_Transaction__c.fields.getMap();
    List<String> fields = new List<String>();
    for (Schema.SObjectField sObjField : fieldMap.values()) {
      Schema.DescribeFieldResult dfr = sObjField.getDescribe();
      fields.add(dfr.getName());
    }
    return String.join(fields, ',');
  }

  global Database.QueryLocator start(Database.BatchableContext bc) {
    String query =
      'SELECT ' +
      getQueryFields() +
      ' FROM Historical_Transaction__c WHERE Processed__c = false AND Retrieved_Details__c = true AND Needs_Review__c = false';
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext bc, List<Historical_Transaction__c> transactions) {
    HistoricalTransactionProcessor processor = new HistoricalTransactionProcessor(transactions[0]);
    processor.run();
  }

  global void finish(Database.BatchableContext bc) {
  }
}