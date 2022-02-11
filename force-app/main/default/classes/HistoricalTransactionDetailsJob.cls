global class HistoricalTransactionDetailsJob implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {
  private static final String CRON_EXP = '0 0 0/1 1/1 * ? *';
  private String type;

  global HistoricalTransactionDetailsJob(String type) {
    this.type = type;
  }

  global static string schedule(String type, String jobName, String cron) {
    if (jobName == null) {
      jobName = 'Historical Transaction Details Job';
    }
    if (cron == null) {
      cron = CRON_EXP;
    }
    return System.schedule(
      jobName,
      cron,
      new HistoricalTransactionDetailsJob(type)
    );
  }

  global void execute(SchedulableContext sc) {
    Database.executeBatch(this, 80);
  }

  global static void run(String type) {
    Database.executeBatch(new HistoricalTransactionDetailsJob(type), 80);
  }

  global Database.QueryLocator start(Database.BatchableContext bc) {
    String theType = this.type;
    String query =
      'SELECT ' +
      getQueryFields() +
      ' FROM Historical_Transaction__c WHERE Retrieved_Details__c = false AND Type__c = :theType';
    return Database.getQueryLocator(query);
  }

  global void execute(
    Database.BatchableContext bc,
    List<Historical_Transaction__c> transactions
  ) {
    Historical_Transaction_Settings__c htSettings = Historical_Transaction_Settings__c.getInstance(
      type
    );
    if (htSettings == null) {
      throw new HistoricalTransactionException(
        'No Historical_Transaction_Settings__c found with type: ' + type
      );
    }
    HistoricalTransactionAPI api = HistoricalTransactionAPIFactory.getTransactionsAPIByType(
      this.type
    );
    api.setMode(htSettings.API_Type__c);
    api.authenticate();
    for (Historical_Transaction__c ht : transactions) {
      try {
        ht = api.completeTransactionDetails(ht);
        ht.Retrieved_Details__c = (ht.Status__c != null &&
          !ht.Status__c.contains('pending'))
          ? true
          : false;
      } catch (HistoricalTransactionException e) {
        ht.Needs_Review__c = true;
        ht.Error_Messages__c = e.getMessage();
      }
    }
    update transactions;
  }

  global void finish(Database.BatchableContext bc) {
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
}