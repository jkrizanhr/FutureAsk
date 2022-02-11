public with sharing class SObjectBannerAlert_Ctrl {

  @AuraEnabled
  public static List<CustomAlertGroup> getAlertsForSObject(Id recordId) {
    String sObjectName = recordId.getSobjectType().getDescribe().getName();
    Map<String,CustomAlertGroup> alertGroupMap = new Map<String,CustomAlertGroup>();

    String query = 'SELECT ';

    List<SObject_Banner_Alert__c> alertSettings = [
                                            SELECT Message__c,
                                            Field_Name__c,
                                            Object_Name__c,
                                            Value__c,
                                            Does_not_equal__c,
                                            Include_NULL_Values__c,
                                            Alert_Type__c,
                                            Message_Merge_Fields__c
                                            FROM SObject_Banner_Alert__c
                                            WHERE Object_Name__c = :sObjectName];

    Set<String> fieldsToQuery = new Set<String>();
    for(SObject_Banner_Alert__c setting : alertSettings) {
      fieldsToQuery.add(setting.Field_Name__c.tolowercase());
      if(setting.Message_Merge_Fields__c != null) {
        fieldsToQuery.addAll(setting.Message_Merge_Fields__c.replaceAll(' ', '').tolowercase().split(','));
      }
    }
    List<String> fields = new List<String>(fieldsToQuery);
    query += String.join(fields, ',');

    if(!alertSettings.isEmpty()) {
      query += ' FROM ' + sObjectName + ' WHERE Id = \'' + recordId + '\'';

      for(SObject record : Database.query(query)) {
        for(SObject_Banner_Alert__c setting : alertSettings) {

          String fieldVal = getFieldValue(setting.Field_Name__c, record);

          Boolean emptyValue = String.isBlank(fieldVal);
          Boolean condition1 = !emptyValue && !setting.Does_not_equal__c && fieldVal == setting.Value__c;
          Boolean condition2 = !emptyValue && setting.Does_not_equal__c && fieldVal != setting.Value__c;
          Boolean condition3 = setting.Include_NULL_Values__c && emptyValue;
          Boolean condition4 = !emptyValue && String.isNotBlank(setting.Value__c) && !setting.Does_not_equal__c && setting.Value__c.split(',').contains(fieldVal);

          System.debug(condition1 + ':' + condition2 + ':' + condition3 + ':' + condition4);

          if(condition1 || condition2 || condition3 || condition4) {
            String alertType = setting.Alert_Type__c != null ? setting.Alert_Type__c.toLowerCase() : 'info';
            CustomAlertGroup grp = alertGroupMap.get(alertType);

            if(grp == null) {
              grp = new CustomAlertGroup();
              grp.alerts = new List<CustomAlert>();
              grp.alertType = alertType;
              alertGroupMap.put(alertType, grp);
            }

            CustomAlert a = new CustomAlert();
            if(setting.Message__c.contains('{!')) { //Has merge fields
              while(setting.Message__c.contains('{!')) {
                setting.Message__c = mergeMessageFields(setting.Message__c, record);
              } 
            }
            a.message = setting.Message__c;
            a.sObjectName = setting.Object_Name__c;
            a.sObjectFieldName = setting.Field_Name__c;
            if(setting.Field_Name__c.contains('\\.')) {
              a.sObjectFieldLabel = Schema.getGlobalDescribe().get(setting.Object_Name__c).getDescribe().fields.getMap().get(setting.Field_Name__c).getDescribe().getLabel();
            } else {
              a.sObjectFieldLabel = setting.Field_Name__c;
            }
            a.messageValue = setting.Value__c != null ? String.join(setting.Value__c.split(','), ' OR ') : 'NULL';
            grp.alerts.add(a);
          }
        }
      }
    }

    return alertGroupMap.values();
  }

  private static String mergeMessageFields(String theMessage, SObject currentRecordValues) {
    Integer startingPoint = theMessage.indexOf('{!'); // find the starting point of the merge field
    Integer endingPoint = theMessage.indexOf('}', startingPoint); // find the next closing bracket after the start of {!
    String mergeFieldApiName = theMessage.substring(startingPoint + 2, endingPoint); //e.g. Account.Name without brackets
    String mergeField = '\\{!' + mergeFieldApiName + '\\}'; // e.g. {!Account.Name} with brackets
    String mergeFieldValue = getFieldValue(mergeFieldApiName, currentRecordValues); // the account value from the current record
    if(mergeFieldValue == null) {
      mergeFieldValue = 'NULL_VALUE';
    }
    theMessage = theMessage.replaceAll(mergeField, mergeFieldValue); //Swap out the merge field with the value e.g. {!Account.Name} => Example Co.
    return theMessage;
  }

  private static String getFieldValue(String fieldName, SObject obj) {
    String fieldVal;
    List<String> pathParts = fieldName.split('\\.');
    Integer i = 1;

    for(String f : pathParts) {
      if(pathParts.size() > i) {
        obj = obj.getSObject(f);
        i++;
        if(obj == null) {
          break;
        }

      } else {
        fieldVal = String.valueOf(obj.get(f));
      }
    }
    return fieldVal;
  }

  public class CustomAlertGroup {
    @AuraEnabled public String alertType {get; set;}
    @AuraEnabled public List<CustomAlert> alerts {get; set;}
  }

  public class CustomAlert {
    @AuraEnabled public String sObjectName {get; set;}
    @AuraEnabled public String sObjectFieldName {get; set;}
    @AuraEnabled public String sObjectFieldLabel {get; set;}
    @AuraEnabled public String messageValue {get; set;}
    @AuraEnabled public String message {get; set;}
  }
}