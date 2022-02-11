global class DocumentGenerationBatchJob implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
  private String deliveryOption; // CSV - Email; CSV - Direct Download; PDF - Email; PDF - Direct Download
  private DocumentGenerationEngine engine;
  private Map<String, String> questionIdAnswerMap;
  private Boolean isTestMode;
  private Integer numRecordsProcessed;
  private String scheduledTOAddress;
  private String templateId;
  private String jobId;
  private Id jobLogId;

  global DocumentGenerationBatchJob(
    String templateId,
    String deliveryOption,
    Boolean isTestMode,
    Map<String, String> questionIdAnswerMap
  ) {
    this.templateId = templateId;
    this.deliveryOption = deliveryOption;
    this.questionIdAnswerMap = questionIdAnswerMap;
    this.isTestMode = isTestMode;
    this.numRecordsProcessed = 0;
    this.engine = new DocumentGenerationEngine(
      new List<String>(),
      this.templateId,
      this.deliveryOption,
      this.isTestMode,
      false
    );
  }

  global DocumentGenerationBatchJob(
    String templateId,
    String deliveryOption,
    Boolean isTestMode,
    Map<String, String> questionIdAnswerMap,
    String scheduledTOAddress
  ) {
    this.templateId = templateId;
    this.deliveryOption = deliveryOption;
    this.questionIdAnswerMap = questionIdAnswerMap;
    this.isTestMode = isTestMode;
    this.numRecordsProcessed = 0;
    this.scheduledTOAddress = scheduledTOAddress;
    this.engine = new DocumentGenerationEngine(
      new List<String>(),
      this.templateId,
      this.deliveryOption,
      this.isTestMode,
      true
    );
  }

  global Database.QueryLocator start(Database.BatchableContext bc) {
    String batchJobId = bc.getJobId();
    this.jobId = batchJobId.substring(0, 15);
    this.jobLogId = this.engine.createJobLog(this.jobId);
    this.engine.initDocumentTemplateData();
    this.engine.initDocumentQuestionMaps(this.questionIdAnswerMap);
    this.engine.initDocumentTemplateQueries();
    this.engine.initDocumentGenerationHandler();
    String queryString = this.engine.buildPrimarySOQLQueryString();
    System.debug('queryString: \n' + queryString);
    if (String.isBlank(queryString)) {
      return null;
    }
    return Database.getQueryLocator(queryString);
  }

  global void execute(Database.BatchableContext bc, List<SObject> scope) {
    this.numRecordsProcessed += scope.size();
    this.engine.setRecordList(scope);
    Boolean isSuccess = this.engine.handleDocumentGeneration();
    if (isSuccess) {
      this.engine.handlePostGenerationMethods();
    }
  }

  global void finish(Database.BatchableContext bc) {
    // For CSV delivery options, we will always assume that the post generation methods can only execute here in the finish method.
    // We don't want to execute post generation methods while building the CSV.
    // We do however want to build the record from the post generation methods while builing the CSV.
    if (this.deliveryOption == 'PDF - Email') {
      this.sendBatchJobSummaryEmail();
    } else {
      Boolean isSuccessful = true;

      if (this.deliveryOption == 'CSV - Direct Download' || this.deliveryOption == 'CSV - Email') {
        isSuccessful = this.engine.finishCSVGeneration();
        System.debug('engine.finishCSVGeneration successful? ' + isSuccessful);
      } else if (this.deliveryOption == 'PDF - Direct Download') {
        isSuccessful = true;
      }

      if (isSuccessful && this.isTestMode == false) {
        List<String> postGenContainerJSONs = this.engine.buildPostGenContainerJSONStrings();
        String summaryContentString = this.buildAttachedSummaryContent();
        String emailContentString = this.getEmailContent();
        DocGenPostMethodBatchJob postMethodJob = new DocGenPostMethodBatchJob(
          this.jobLogId,
          postGenContainerJSONs,
          this.templateId,
          summaryContentString,
          emailContentString,
          this.scheduledTOAddress
        );
        String postGenJobId = Database.executeBatch(postMethodJob, 100);
        this.engine.updateJobLog(postGenJobId);
      } else {
        // Email user job summary
        this.sendBatchJobSummaryEmail();
      }
    }
  }

  private void sendBatchJobSummaryEmail() {
    DocGenSettings__c docGenSettings = DocGenSettings__c.getInstance();
    if (docGenSettings == null || String.isBlank(docGenSettings.Email_Service__c)) {
      return;
    }

    String summaryContentString = this.buildAttachedSummaryContent();
    String emailContentString = this.getEmailContent();

    DocumentEmail email = new DocumentEmail();
    email.blobContent = Blob.valueOf(summaryContentString);
    email.emailContent = emailContentString;
    email.fileName = 'Document Generation Batch Job Completion Summary';
    email.contentType = 'txt';
    email.emailSubject = 'Document Generation Batch Job Completion Summary';

    Document_Template__c docTemp = [SELECT FROM_Address__c FROM Document_Template__c WHERE Id = :this.templateId];

    if (String.isNotBlank(this.scheduledTOAddress)) {
      email.toAddress = this.scheduledTOAddress;
      email.fromAddress = docTemp.FROM_Address__c;
    } else {
      email.toAddress = UserInfo.getUserEmail();
      email.fromAddress = docTemp.FROM_Address__c;
    }
    System.enqueueJob(new DocumentGenerationEmailQueueable(email));
  }

  private String getEmailContent() {
    return 'Attached is the batch job summary.\nThe Document Generation Log can be found at: ' +
      Url.getSalesforceBaseUrl().toExternalForm() +
      '/' +
      this.jobLogId;
  }

  private String buildAttachedSummaryContent() {
    List<AsyncApexJob> jobs = this.fetchAsyncApexJobs();
    Document_Template__c documentTemplate = this.engine.getDocumentTemplate();
    String emailContentString = 'Document Template: ' + documentTemplate.Name;
    emailContentString += '\n\nPrimary SOQL Query String: \n' + this.engine.getPrimarySOQLQueryString();
    List<String> secondaryQueryStrings = this.engine.getSecondarySOQLQueryStrings();
    for (String qs : secondaryQueryStrings) {
      emailContentString += '\n\nSecondary SOQL Query String: \n' + qs;
    }
    List<String> aggregateQueryStrings = this.engine.getAggregateSOQLQueryStrings();
    for (String qs : aggregateQueryStrings) {
      emailContentString += '\n\nAggregate SOQL Query String: \n' + qs;
    }
    List<String> customMetadataQueryStrings = this.engine.getCustomMetadataSOQLQueryStrings();
    for (String qs : customMetadataQueryStrings) {
      emailContentString += '\n\nCustom Metadata SOQL Query String: \n' + qs;
    }
    emailContentString += '\n\nAsyncApexJob: ' + JSON.serializePretty(jobs[0]);
    emailContentString += '\n\nNumber of records processed: ' + this.numRecordsProcessed;

    List<DocumentGeneratorModel.ErrorLog> errorLogs = this.engine.getErrorLogs();
    if (errorLogs != null && errorLogs.isEmpty() == false) {
      emailContentString += '\n\nErrors: \n';
      for (DocumentGeneratorModel.ErrorLog error : errorLogs) {
        emailContentString += 'Error Message: ' + error.errMessage + '\n';
      }
    } else {
      emailContentString += '\n\nErrors: No errors.\n';
    }

    return emailContentString;
  }

  private List<AsyncApexJob> fetchAsyncApexJobs() {
    return [
      SELECT
        ApexClassId,
        CompletedDate,
        CreatedById,
        CreatedDate,
        ExtendedStatus,
        Id,
        JobItemsProcessed,
        JobType,
        LastProcessed,
        LastProcessedOffset,
        MethodName,
        NumberOfErrors,
        ParentJobId,
        Status,
        TotalJobItems
      FROM AsyncApexJob
      WHERE Id = :this.jobId
    ];
  }
}