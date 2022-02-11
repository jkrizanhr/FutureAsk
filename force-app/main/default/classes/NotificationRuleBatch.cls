global without sharing class NotificationRuleBatch implements Database.Batchable<sObject> {
  Notification_Rule__mdt rule;
  public NotificationRuleBatch(Notification_Rule__mdt rule) {
    this.rule = rule;
  }

  global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(rule.SOQL_Query__c);
  }

  global void execute(Database.BatchableContext bc, List<SObject> sobjList) {
    new NotificationRuleProcessor(this.rule, sobjList);
  }

  global void finish(Database.BatchableContext bc) {}
}