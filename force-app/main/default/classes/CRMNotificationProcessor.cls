public class CRMNotificationProcessor {
  // https://salesforce.stackexchange.com/questions/256989/bell-notifications-via-apex/286556#286556
  public static void generateCRMNotification(List<Notification__c> notifications) {
    Http h = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint(Url.getOrgDomainUrl().toExternalForm() + '/services/data/v46.0/actions/standard/customNotificationAction');
    req.setMethod('POST');
    req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
    req.setHeader('Content-Type', 'application/json');
    List<CustomNotificationActionInput> inputs = new List<CustomNotificationActionInput>();
    for (Notification__c n : notifications) {
      CustomNotificationActionInput input = new CustomNotificationActionInput();
      // Custom Notifications in Setup
      // SELECT Id, DeveloperName FROM CustomNotificationType
      input.customNotifTypeId = '0ML3I0000004CN0WAM'; 
      input.recipientIds = new List<String>{n.User__c};
      input.title = n.Label__c;
      input.body = n.Message__c;
      input.targetId = n.Record_Id__c; 
      inputs.add(input);
      n.Status__c = 'Completed';
    }
    CustomNotificationAction action = new CustomNotificationAction();
    action.inputs = inputs;
    req.setBody(JSON.serialize(action));
    if (!Test.isRunningTest()) {
      HttpResponse res = h.send(req);
    }
    update notifications;
  }

  public class CustomNotificationAction {
    public List<CustomNotificationActionInput> inputs { get; set; }
  }

  public class CustomNotificationActionInput {
    public String customNotifTypeId { get; set; }
    public List<String> recipientIds { get; set; }
    public String title { get; set; }
    public String body { get; set; }
    public String targetId { get; set; }
  }
}