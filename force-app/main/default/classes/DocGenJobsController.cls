public class DocGenJobsController {
  @AuraEnabled
  public static void deleteOldJobLogs() {
    delete [
      SELECT Id
      FROM Document_Generation_Job_Log__c
      WHERE CreatedById = :UserInfo.getUserId() AND CreatedDate < LAST_N_DAYS:30
    ];
  }

  @AuraEnabled
  public static List<Document_Generation_Job_Log__c> fetchJobLogs() {
    return [
      SELECT
        Async_Apex_Job_Id__c,
        FORMAT(CreatedDate),
        Delivery_Option__c,
        Document_Template__c,
        Document_Template__r.Name,
        Id,
        Name,
        Post_Generation_Job_Id__c,
        Question_Answer_JSON__c
      FROM Document_Generation_Job_Log__c
      WHERE CreatedById = :UserInfo.getUserId() AND CreatedDate >= LAST_N_DAYS:14 AND Processed__c = false
      ORDER BY CreatedDate DESC
    ];
  }

  @AuraEnabled
  public static List<AsyncApexJob> fetchApexJobs(List<String> apexJobIds) {
    return [
      SELECT
        ApexClassId,
        ApexClass.Name,
        FORMAT(CreatedDate),
        ExtendedStatus,
        Id,
        JobItemsProcessed,
        JobType,
        NumberOfErrors,
        MethodName,
        Status,
        TotalJobItems
      FROM AsyncApexJob
      WHERE
        ApexClass.Name IN ('DocumentGenerationBatchJob', 'DocGenPostMethodBatchJob')
        AND JobType = 'BatchApex'
        AND CreatedById = :UserInfo.getUserId()
        AND Id IN :apexJobIds
      ORDER BY CreatedDate DESC
    ];
  }

  @AuraEnabled
  public static Boolean abortBatchJob(String jobId) {
    if (String.isNotEmpty(jobId)) {
      try {
        System.abortJob(jobId);
        return true;
      } catch (Exception e) {
        throw new AuraHandledException('Error: ' + e.getMessage());
      }
    }
    return false;
  }

  @AuraEnabled
  public static List<ContentVersion> fetchContentVersions(String jobId) {
    Id entityId = Id.valueOf(jobId);
    List<ContentDocumentLink> links = [
      SELECT Id, ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :entityId
    ];

    List<Id> contentDocumentIds = new List<Id>();
    for (ContentDocumentLink cdl : links) {
      contentDocumentIds.add(cdl.ContentDocumentId);
    }

    List<ContentVersion> contentVersions = [
      SELECT Id, Title
      FROM ContentVersion
      WHERE ContentDocumentId IN :contentDocumentIds
    ];

    return contentVersions;
  }
}