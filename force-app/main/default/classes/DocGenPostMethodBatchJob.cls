global class DocGenPostMethodBatchJob implements Database.Batchable<String> {
  private List<String> postGenContainerJSONs;
  private String summaryContentString;
  private String emailContentString;
  private String documentTemplateId;
  private String scheduledTOAddress;
  private Id jobLogId;

  global DocGenPostMethodBatchJob(
    Id jobLogId,
    List<String> postGenContainerJSONs,
    String documentTemplateId,
    String summaryContentString,
    String emailContentString,
    String scheduledTOAddress
  ) {
    this.jobLogId = jobLogId;
    this.postGenContainerJSONs = postGenContainerJSONs;
    this.documentTemplateId = documentTemplateId;
    this.summaryContentString = summaryContentString;
    this.emailContentString = emailContentString;
    this.scheduledTOAddress = scheduledTOAddress;
  }

  global Iterable<String> start(Database.BatchableContext bc) {
    return this.postGenContainerJSONs;
  }

  global void execute(Database.BatchableContext bc, List<String> scope) {
    List<DocumentGeneratorModel.PostGenContainer> postGenContainers = new List<DocumentGeneratorModel.PostGenContainer>();
    for (String str : scope) {
      DocumentGeneratorModel.PostGenContainer postGenContainer = (DocumentGeneratorModel.PostGenContainer) JSON.deserialize(
        str,
        DocumentGeneratorModel.PostGenContainer.class
      );
      postGenContainers.add(postGenContainer);
    }
    DocumentPostGenMethodService.executePostGenContainerMethods(postGenContainers, this.jobLogId);
  }

  global void finish(Database.BatchableContext bc) {
    this.sendBatchJobSummaryEmail();
  }

  private void sendBatchJobSummaryEmail() {
    DocGenSettings__c docGenSettings = DocGenSettings__c.getInstance();
    if (
      docGenSettings == null || String.isBlank(docGenSettings.Email_Service__c) ||
      String.isBlank(this.summaryContentString)
    ) {
      return;
    }

    DocumentEmail email = new DocumentEmail();
    email.blobContent = Blob.valueOf(this.summaryContentString);
    email.emailContent = this.emailContentString;
    email.fileName = 'Document Generation Batch Job Completion Summary';
    email.contentType = 'txt';
    email.emailSubject = 'Document Generation Batch Job Completion Summary';

    Document_Template__c docTemp = [
      SELECT FROM_Address__c
      FROM Document_Template__c
      WHERE Id = :this.documentTemplateId
    ];

    if (String.isNotBlank(this.scheduledTOAddress)) {
      email.toAddress = this.scheduledTOAddress;
      email.fromAddress = docTemp.FROM_Address__c;
    } else {
      email.toAddress = UserInfo.getUserEmail();
      email.fromAddress = docTemp.FROM_Address__c;
    }

    System.enqueueJob(new DocumentGenerationEmailQueueable(email));
  }
}