global without sharing class DuplicateJobSchedule implements Schedulable {
  //System.schedule('Duplicate Job', '0 0 0 1/1 * ? *', new DuplicateJobSchedule());

  global void execute(SchedulableContext SC) {
    DuplicateJobSchedule.executeOnAccounts();
    DuplicateJobSchedule.executeOnContacts();
  }

  global static void executeOnAccounts(){
    DuplicateRule dr = [
        SELECT DeveloperName
        FROM DuplicateRule
        WHERE DeveloperName = 'Account_Duplicate'
      ];
    CAND_Duplicate_Job__c duplicateJob = new CAND_Duplicate_Job__c();
    duplicateJob.SObject_Type__c = 'Account';
    duplicateJob.Duplicate_Rule_Id__c = dr.Id;
    duplicateJob.Duplicate_Rule_API_Name__c = dr.DeveloperName;
    // duplicateJob.Job_Mapping_Name__c = jobMappingName;
    insert duplicateJob;
    if (!Test.isRunningTest())
      Database.executeBatch(
        new CAND_DuplicateJob_RunBatchable(duplicateJob.Id, false),
        50
      );
  }

  global static void executeOnContacts(){
    DuplicateRule dr = [
        SELECT DeveloperName
        FROM DuplicateRule
        WHERE DeveloperName = 'Contact_Duplicate'
      ];
    CAND_Duplicate_Job__c duplicateJob = new CAND_Duplicate_Job__c();
    duplicateJob.SObject_Type__c = 'Contact';
    duplicateJob.Duplicate_Rule_Id__c = dr.Id;
    duplicateJob.Duplicate_Rule_API_Name__c = dr.DeveloperName;
    // duplicateJob.Job_Mapping_Name__c = jobMappingName;
    insert duplicateJob;
    if (!Test.isRunningTest())
      Database.executeBatch(
        new CAND_DuplicateJob_RunBatchable(duplicateJob.Id, false),
        50
      );
  }
}