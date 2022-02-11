@isTest
private class ManualRecordMergeCtrl_Test {
    @isTest static void testProcessor() {
        Contact con1 = new Contact();
        con1.LastName = 'test';
        insert con1;

        Contact con2 = new Contact();
        con2.LastName = 'test';
        insert con2;

        ManualRecordMerge_Ctrl.createDuplicateSetWithItems(new List<String>{con1.Id, con2.Id});

        Contact con1Result = [SELECT Id,Duplicate_Match_Id__c FROM Contact WHERE Id = :con1.Id];
        System.assertEquals(con1.Id, con1Result.Id);
        System.assertEquals(con1.Id, con1Result.Duplicate_Match_Id__c);

        Contact con2Result = [SELECT Id,Duplicate_Match_Id__c FROM Contact WHERE Id = :con2.Id];
        System.assertEquals(con1.Id, con2Result.Duplicate_Match_Id__c);
    }
}