public without sharing class CRMNotificationQueueable implements Queueable, Database.AllowsCallouts {
  List<Notification__c> notifications;
  public CRMNotificationQueueable(List<Notification__c> notifications) {
    this.notifications = notifications;
  }
  public void execute(QueueableContext context) {
    CRMNotificationProcessor.generateCRMNotification(this.notifications);
  }
}