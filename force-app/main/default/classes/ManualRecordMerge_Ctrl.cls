public with sharing class ManualRecordMerge_Ctrl {
    @AuraEnabled
    public static void createDuplicateSetWithItems(List<String> recordsToMerge){

        Id firstRecId = recordsToMerge[0];
        List<SObject> objList = new List<SObject>();
        for(String recId : recordsToMerge) {
            SObject obj = Id.valueOf(recId).getSObjectType().newSObject(recId);
            obj.put('Duplicate_Match_Id__c', firstRecId);
            objList.add(obj);
        }
        update objList;
    }
}