public class MonthlyGiverJob implements Database.Batchable<sObject>, Schedulable {
  
  public static String schedule(String jobName, String cron) {
    if (String.isBlank(jobName)) jobName = 'Monthly Giver Job';
    if (String.isBlank(cron)) cron = '0 0 3 * * ?'; // Everyday @ 3 am
    return System.schedule(jobName, cron, new MonthlyGiverJob());
  }
  
  public List<Account> start(Database.BatchableContext BC) {
    return [SELECT Id, Monthly_Giver__c, Override_Monthly_Giver_Type__c, Name FROM Account 
            WHERE Id IN (SELECT AccountId FROM Opportunity WHERE IsWon = true AND CloseDate = LAST_N_DAYS:365) AND Override_Monthly_Giver_Type__c = false];
  }

  public void execute(Database.BatchableContext BC, List<Account> accts) {
    MonthlyGiverJobService.findMonthlyGiverStatus(accts);
  }

  public void finish(Database.BatchableContext BC) {}

  public void execute(SchedulableContext sc) {
    Database.executeBatch(this, 200);
  }
}