public without sharing class NotificationRuleBatcher {
  public NotificationRuleBatcher(List<Notification_Rule__mdt> notificationRules) {
    for (Notification_Rule__mdt rule : notificationRules) {
      if (rule.SOQL_Query__c != null) {
        List<SObject> sobjList = Database.query(rule.SOQL_Query__c);
        if (sobjList != null) {
          if (sobjList.size() > 0 ) {
            Database.executeBatch(new NotificationRuleBatch(rule));
          }
        }
      }
    }
  }
}