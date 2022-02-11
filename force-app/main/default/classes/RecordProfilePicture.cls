public without sharing class RecordProfilePicture {

    @AuraEnabled
    public static String getProfilePicture(String recordId, String fieldName, String sObjectName) {
        List<SObject> records = Database.query('SELECT Id,' + fieldName + ' FROM ' + sObjectName + ' WHERE Id = :recordId');
        return records.isEmpty() ? null : String.valueOf(records[0].get(fieldName));
    }

    @AuraEnabled
    public static void saveProfileId(String recordId, String contentId, String fieldName, String sObjectName) {
        if(recordId != null && contentId != null) {
            SObject obj = Schema.getGlobalDescribe().get(sObjectName).newSObject() ;
            obj.put('Id', recordId);
            obj.put(fieldName, contentId);
            update obj;

            List<ContentDocumentLink> cdlList = [SELECT Id,Visibility FROM ContentDocumentLink WHERE ContentDocumentId = :contentId AND LinkedEntityId = :recordId];
            for(ContentDocumentLink cdl : cdlList) {
                cdl.Visibility = 'AllUsers';
            }
            update cdlList;
        } else {
            System.debug('Record Id or Content Id missing');
        }
    }
}