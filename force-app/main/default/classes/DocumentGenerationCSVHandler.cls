public class DocumentGenerationCSVHandler implements DocumentGenerationService {
  private List<String> csvRows;
  public DocumentGeneratorModel docGenModel;
  private DocGenSettings__c docGenSettings;

  public void init(DocumentGeneratorModel docGenModel) {
    this.docGenModel = docGenModel;
    this.docGenSettings = DocGenSettings__c.getOrgDefaults();
    this.csvRows = new List<String>();
    if (this.docGenModel != null && String.isNotBlank(this.docGenModel.docTemp.CSV_Columns__c)) {
      DocumentGenerationCSVService csvService = new DocumentGenerationCSVService();
      String headerRow = csvService.generateHeaderRow(this.docGenModel.docTemp.CSV_Columns__c);
      this.csvRows.add(headerRow);
    }
  }

  public Boolean handleDocumentGeneration(List<DocumentGeneratorModel.Doc> documents) {
    // Build the list of rows for the CSV without additional rows.
    DocumentGenerationCSVBuilder csvBuilder = new DocumentGenerationCSVBuilder(this.docGenModel, documents);
    List<String> rowResults = csvBuilder.buildCSVRows();
    this.csvRows.addAll(rowResults);
    return true;
  }

  public Boolean handleDocumentGeneration(List<SObject> recordList) {
    return true;
  }

  public Boolean completeDocumentGeneration() {
    if (this.docGenModel.docTemp.Show_Headers__c == false && this.csvRows.size() > 0) {
      this.csvRows.remove(0);
    }

    String csvString = String.join(this.csvRows, '\r\n');
    Blob csvBlob = Blob.valueOf(csvString);

    DocumentMergeFieldProcessor mergeFieldProcessor = new DocumentMergeFieldProcessor();
    mergeFieldProcessor.deliveryOption = this.docGenModel.deliveryOption;
    mergeFieldProcessor.stringToParseThru = this.docGenModel.docTemp.Filename__c;
    mergeFieldProcessor.mergeFieldAnswerMap = this.docGenModel.mergeFieldAnswerMap;
    if (this.docGenModel.jobLog != null) {
      mergeFieldProcessor.jobLogId = this.docGenModel.jobLog.Id;
    }

    String documentName = mergeFieldProcessor.processString();
    if (String.isBlank(documentName)) {
      documentName = this.docGenModel.docTemp.Name;
    }

    Boolean isSuccess = true;
    if (this.docGenModel.deliveryOption == 'CSV - Email') {
      // Email the completed CSV
      isSuccess = this.emailCSV(documentName, csvBlob);
    } else if (this.docGenModel.deliveryOption == 'CSV - Direct Download') {
      // Insert a file so it is available download
      isSuccess = this.insertCSVFile(documentName, csvBlob);
    } else {
      isSuccess = false;
    }
    return isSuccess;
  }

  private Boolean emailCSV(String documentName, Blob csvBlob) {
    Boolean isSuccess = false;
    if (this.docGenSettings != null && String.isNotBlank(this.docGenSettings.Email_Service__c)) {
      DocumentEmail email = this.buildDocumentEmail(csvBlob, documentName);
      DocumentEmailService emailService = DocumentEmailServiceFactory.getEmailServiceByType(
        this.docGenSettings.Email_Service__c
      );
      isSuccess = emailService.sendEmails(new List<DocumentEmail>{email});
    }
    return isSuccess;
  }

  private DocumentEmail buildDocumentEmail(Blob blobContent, String documentName) {
    DocumentEmail email = new DocumentEmail();
    email.blobContent = blobContent;
    // Don't set the email to test mode so that the csv can still send
    if (this.docGenSettings != null && String.isNotBlank(this.docGenSettings.CSV_File_Extension__c)) {
      email.contentType = this.docGenSettings.CSV_File_Extension__c;
    } else {
      email.contentType = 'CSV';
    }
    email.emailContent = 'Your export is complete.';
    email.emailSubject = this.docGenModel.docTemp.Name + ' - Bulk CSV';

    if (this.docGenModel.isTestMode == true) {
      email.emailSubject = 'TEST MODE: ' + email.emailSubject;
    }
    email.fileName = documentName;

    // Determine if this is running from a scheduled and if so, use the Scheduled_TO_Address__c, otherwise
    // send to the running user.
    if (
      this.docGenModel != null &&
      this.docGenModel.isScheduled == true &&
      this.docGenModel.docTemp != null &&
      String.isNotBlank(this.docGenModel.docTemp.Scheduled_TO_Address__c)
    ) {
      email.toAddress = this.docGenModel.docTemp.Scheduled_TO_Address__c;
    } else {
      email.toAddress = UserInfo.getUserEmail();
    }

    email.fromAddress = this.docGenModel.docTemp.FROM_Address__c;
    return email;
  }

  private Boolean insertCSVFile(String documentName, Blob csvBlob) {
    if (csvBlob == null) {
      System.debug('Error inserting Content Version: csvBlob is null');
      if (this.docGenModel.jobLog != null && this.docGenModel.jobLog.Id != null) {
        // Add error to job log
        Document_Generation_Error_Event__e errorEvent = new Document_Generation_Error_Event__e();
        errorEvent.Apex_Class_Name__c = 'DocumentGenerationCSVHandler';
        errorEvent.Apex_Method_Name__c = 'insertCSVFile';
        errorEvent.Document_Generation_Job_Id__c = this.docGenModel.jobLog.Id;
        errorEvent.Error_Message__c = 'Failed to insert content version. csvBlob parameter is null.';
        EventBus.publish(errorEvent);
      }
      return false;
    }

    ContentVersion cv = new ContentVersion();
    cv.Title = documentName;
    cv.VersionData = csvBlob;

    String fileExtension = 'CSV';
    if (this.docGenSettings != null && String.isNotBlank(this.docGenSettings.CSV_File_Extension__c)) {
      fileExtension = this.docGenSettings.CSV_File_Extension__c;
    }
    cv.PathOnClient = documentName + '.' + fileExtension;

    try {
      insert cv;

      ContentDocumentLink link = new ContentDocumentLink();
      link.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
      link.LinkedEntityId = this.docGenModel.jobLog.Id;
      link.ShareType = 'V';
      insert link;

      return true;
    } catch (DmlException e) {
      System.debug('Error inserting Content Version: ' + e.getMessage());
      if (this.docGenModel.jobLog != null && this.docGenModel.jobLog.Id != null) {
        // Add error to job log
        Document_Generation_Error_Event__e errorEvent = new Document_Generation_Error_Event__e();
        errorEvent.Apex_Class_Name__c = 'DocumentGenerationCSVHandler';
        errorEvent.Apex_Method_Name__c = 'insertCSVFile';
        errorEvent.Document_Generation_Job_Id__c = this.docGenModel.jobLog.Id;
        errorEvent.Error_Message__c = 'Failed to insert content version. ' + e.getMessage();
        EventBus.publish(errorEvent);
      }
      return false;
    }
  }
}