// System.schedule('Notification Job', '0 0 0/1 1/1 * ? *', new NotificationJob());
global class NotificationJob implements Database.Batchable<sObject>, Database.AllowsCallouts, Schedulable {
  public NotificationJob() {}

  global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator([SELECT Id FROM Notification__c WHERE Status__c = 'Pending']);
  }

  global void execute(Database.BatchableContext bc, List<Notification__c> notifications) {
    new NotificationProcessor(new Map<Id, Notification__c>(notifications).keySet()).execute(null);
  }

  global void finish(Database.BatchableContext bc) {
  }

  global void execute(SchedulableContext sc) {
    Database.executeBatch(new NotificationJob(), 50);
  }
}