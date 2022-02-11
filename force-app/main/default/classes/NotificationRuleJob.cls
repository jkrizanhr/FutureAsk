// System.schedule('Notification Rule Job', '0 0 0/1 1/1 * ? *', new NotificationRuleJob());
global class NotificationRuleJob implements Database.AllowsCallouts, Schedulable {
    global void execute(SchedulableContext sc) {
      runNotificationRuleJob();
    }
    public void runNotificationRuleJob() {
      List<Notification_Rule__mdt> notificationRules = new List<Notification_Rule__mdt>();
      String query = 
        'SELECT ' +
          'MasterLabel, DeveloperName, Message__c, SOQL_Query__c, Subject__c, ' +
          'CRM_Notification__c, Email_Notification__c, ' +
          'Recipient_Field__c, Recipient_Type__c ' +
        'FROM Notification_Rule__mdt';
      if (Test.isRunningTest()) {
        query += ' WHERE DeveloperName LIKE \'UnitTest%\'';
      } else {
        query += ' WHERE (NOT DeveloperName LIKE \'UnitTest%\') AND Active__c = true';
      }
      notificationRules = Database.query(query);
      if (!notificationRules.isEmpty()) {
        new NotificationRuleBatcher(notificationRules); 
      }
    }
  }