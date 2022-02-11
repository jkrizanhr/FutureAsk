global without sharing class NotificationRuleProcessor {
  public NotificationRuleProcessor(Notification_Rule__mdt rule, List<SObject> sobjList) {
    DocumentMergeFieldProcessor mergeFieldProcessor = new DocumentMergeFieldProcessor();
    List<SObject> sobjListToUpdate = new List<SObject>();
    List<Notification__c> notificationList = new List<Notification__c>();

    if (String.isNotBlank(rule.Message__c)) {
      for (SObject sobj : sobjList) {
        Notification__c n = new Notification__c();
        String message = rule.Message__c;
        // Run the merge field processing to replace any merge fields with fields
        mergeFieldProcessor.record = sobj;
        mergeFieldProcessor.stringToParseThru = message;
        n.Message__c = mergeFieldProcessor.processString();
        n.Label__c = rule.Subject__c;
        n.CRM__c = rule.CRM_Notification__c;
        n.Email__c = rule.Email_Notification__c;
        n.Status__c = 'Pending';

        // SObjectBannerAlert_Ctrl gets value from the last referenced field
        String fieldVal;
        List<String> pathParts = rule.Recipient_Field__c.split('\\.');
        Integer i = 1;
        for (String f : pathParts) {
          if(pathParts.size() > i) {
            sobj = sobj.getSObject(f);
            i++;
            if(sobj == null) {
              break;
            }
          } else {
            fieldVal = String.valueOf(sobj.get(f));
          }
        }
        if (rule.Recipient_Type__c == 'Contact') {
          n.Contact__c = fieldVal;
        } else if (rule.Recipient_Type__c == 'User') {
          n.User__c = fieldVal;
        }
        notificationList.add(n);
      }
    }

    if (!notificationList.isEmpty()) {
      insert notificationList;
    }
  }
}