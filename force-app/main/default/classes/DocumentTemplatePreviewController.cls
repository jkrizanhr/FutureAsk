public with sharing class DocumentTemplatePreviewController {
    @AuraEnabled
    public static Document_Template__c fetchTemplate(Id docTempId) {
        List<Document_Template__c> dtList = [
                SELECT
                        CSV_Columns__c,
                        Delivery_Options__c,
                        Id,
                        Name,
                        Primary_Query__c,
                        Salesforce_Object__c,
                        Visualforce_Page__c
                FROM Document_Template__c
                WHERE Id = :docTempId
        ];
        return dtList.isEmpty() ? null : dtList[0];
    }

    @AuraEnabled
    public static List<SObject> fetchTestRecords(String SObjectName) {
        if (SObjectName != null) {
            List<SObject> lt =  Database.query('SELECT Id, Name FROM ' + SObjectName + ' ORDER BY LastViewedDate DESC LIMIT 5');
            if (lt.isEmpty()) {
                return Database.query('SELECT Id, Name FROM ' + SObjectName + ' ORDER BY LastModifiedDate DESC LIMIT 5');
            } else {
                return lt;
            }
        } else {
            return new List<SObject>();
        }
    }
}