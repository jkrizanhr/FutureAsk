global class CalculateAlignmentJob implements Database.Batchable<sObject>, Schedulable {
  public static final String CRON_EXP = '0 0 2 1 1 ? *';
  private Integer batchSize;
  String query;

  global Database.QueryLocator start(Database.BatchableContext BC) {
    this.query = 'SELECT Id, Number_of_Resource_Item_Quantity__c, Number_of_Resource_Orders__c, Number_of_MPP_Projects__c, Number_of_TPP_Projects__c, ' + 
    '(SELECT Id, Project__r.RecordType.Name, Project__c, CreatedDate FROM Project_Partners__r WHERE CreatedDate >= LAST_N_YEARS:5), ' +
    '(SELECT Id, Resource_Order_Total__c, Total_Order_Quanity__c, Submitted_Date__c FROM Resource_Orders__r WHERE Submitted_Date__c >= LAST_N_YEARS:5) ' +
    'FROM Account WHERE RecordType.Name != \'Household Account\'';
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<Account> acctList) {
    CalculateAlignmentJobService.calculateAlignmentRollups(acctList);
  }

  global void finish(Database.BatchableContext BC) {}

  global void execute(SchedulableContext sc) {
    Database.executeBatch(this, this.batchSize);
  }

}