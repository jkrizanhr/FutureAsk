public without sharing class NotificationProcessor implements System.Queueable {
  private Set<Id> notificationIds;
  private List<Notification__c> notifications;
  private EmailTemplate notificationEmailTemplate;
  private Id orgWideEmailAddressId;

  public NotificationProcessor(Set<Id> notificationIds) {
    this.notificationIds = notificationIds;
    List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'User_Email_Notification'];
    if (!templateList.isEmpty()) {
      this.notificationEmailTemplate = templateList[0];
    }
    List<OrgWideEmailAddress> orgWideEmails = [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE DisplayName = 'noreply@biblica.com'
    ];
    if (!orgWideEmails.isEmpty()) {
      orgWideEmailAddressId = orgWideEmails[0].Id;
    }
  }

  public NotificationProcessor(List<Notification__c> notifications) {
    this.notifications = notifications;
  }

  private List<Notification__c> queryNotifications(Set<Id> notificationIds) {
    return [
      SELECT Id, Email__c, CRM__c, User__c, Contact__c, Record_Id__c, Status__c, Label__c, Message__c, Is_Donation_Page_Receipt__c, Template_Id__c, Org_Wide_Address__c, Opportunity_Id__c
      FROM Notification__c
      WHERE Id IN :notificationIds
    ];
  }

  public void execute(QueueableContext qc) {
    if (this.notificationIds != null) {
      this.notifications = queryNotifications(notificationIds);
    }
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    List<Notification__c> emailNotifications = new List<Notification__c>();
    List<Notification__c> crmNotifications = new List<Notification__c>();
    for (Notification__c notification : notifications) {
      if (notification.Email__c == true 
        && (notificationEmailTemplate != null || notification.Is_Donation_Page_Receipt__c)
      ){
        // allow for users to receive emails or contacts to receive emails
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(notification.Contact__c);
        mail.setTreatTargetObjectAsRecipient(true);
        mail.setSaveAsActivity(false);
        // If donation page receipt use fields set by donation page processor
        if (notification.Is_Donation_Page_Receipt__c){
          mail.setTemplateId(notification.Template_Id__c);
          mail.setWhatId(notification.Opportunity_Id__c);
          if (notification.Org_Wide_Address__c != null){
            mail.setOrgWideEmailAddressId(notification.Org_Wide_Address__c);
          }
        } 
        // If NOT a donation page receipt just send an email alert
        else {
          mail.setTemplateId(notificationEmailTemplate.Id);
          mail.setWhatId(notification.Id);
          if (notification.Org_Wide_Address__c != null){
            mail.setOrgWideEmailAddressId(notification.Org_Wide_Address__c);
          } else if (this.orgWideEmailAddressId != null) {
            mail.setOrgWideEmailAddressId(this.orgWideEmailAddressId);
          }
        }
        emails.add(mail);
        notification.Status__c = 'Completed';
        emailNotifications.add(notification);
      } else if (notification.CRM__c == true) {
        crmNotifications.add(notification);
      }
    }
    if (!Test.isRunningTest() && !emails.isEmpty()) {
      List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails, false);
      for (Integer i=0; i < results.size(); i++){
        String errorMessage = '';
        if (!results[i].isSuccess()){
          for (Messaging.SendEmailError error : results[i].getErrors()){
            errorMessage = errorMessage + error + '; ';
          }
        }
        emailNotifications[i].Status__c = results[i].isSuccess() ? 'Completed' : 'Failed';
        emailNotifications[i].Errors__c = errorMessage;
      }
      update emailNotifications;
    }
    if (Test.isRunningTest()) {
      update emailNotifications;
    }
    if (!crmNotifications.isEmpty()) {
      System.enqueueJob(new CRMNotificationQueueable(crmNotifications));
    }
  }
}