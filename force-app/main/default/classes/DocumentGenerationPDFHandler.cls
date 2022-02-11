public class DocumentGenerationPDFHandler implements DocumentGenerationService {
  public DocumentGeneratorModel docGenModel;
  private DocGenSettings__c docGenSettings;
  private DocumentEmailService emailService;

  public void init(DocumentGeneratorModel docGenModel) {
    this.docGenModel = docGenModel;
    this.docGenSettings = DocGenSettings__c.getInstance();
  }

  private PageReference getPageReference(String recordIdsString) {
    PageReference page = new PageReference('/apex/' + this.docGenModel.docTemp.Visualforce_Page__c);
    page.getParameters().put('recordIds', recordIdsString);
    page.getParameters().put('templateId', this.docGenModel.docTemp.Id);
    page.getParameters().put('isTestMode', String.valueOf(this.docGenModel.isTestMode));
    page.getParameters().put('deliveryOption', this.docGenModel.deliveryOption);
    page.getParameters().put('getContentOnly', 'true'); // So that the post generation methods are not executed on page load

    if (this.docGenModel.questionIdAnswerMap != null) {
      // Add the question answer maps as URL Parameters
      for (Document_Template_Question__c question : this.docGenModel.docTempQuestionList) {
        String answer = this.docGenModel.questionIdAnswerMap.get(question.Id);
        if (answer != null) {
          page.getParameters().put(question.Id, answer);

          if (String.isNotBlank(question.URL_Parameter__c)) {
            page.getParameters().put(question.URL_Parameter__c, answer);
          }
          if (String.isNotBlank(question.Query_Merge_Field__c)) {
            this.docGenModel.mergeFieldAnswerMap.put(question.Query_Merge_Field__c, answer);
          }
        }
      }
    }
    return page;
  }

  private Blob getPageContent(PageReference page) {
    Blob pdfContentBlob;
    if (Test.isRunningTest()) {
      pdfContentBlob = Blob.valueOf('Test is running');
    } else {
      try {
        pdfContentBlob = page.getContent();
      } catch (Exception e) {
        if (this.docGenModel.jobLog != null && this.docGenModel.jobLog.Id != null) {
          // Publish the error event
          Document_Generation_Error_Event__e errorEvent = new Document_Generation_Error_Event__e();
          errorEvent.Apex_Class_Name__c = 'DocumentGenerationPDFHandler';
          errorEvent.Apex_Method_Name__c = 'getPageContent';
          errorEvent.Document_Generation_Job_Id__c = this.docGenModel.jobLog.Id;
          errorEvent.Error_Message__c = 'Failed to get page content as a pdf. ' + e.getMessage();
          System.debug(e.getMessage());
          EventBus.publish(errorEvent);
        }
        throw new DocumentGenerationException(
          'DocumentGenerationPDFHandler: failed to get the page content as a pdf! ' + e.getMessage()
        );
      }
    }
    System.debug('Successfully got the content as a pdf, now attempting to send the email(s)');
    return pdfContentBlob;
  }

  private DocumentEmail buildDocumentEmail(PageReference page, Blob pageContentBlob, SObject rec) {
    DocumentGenerationFieldMapService fieldMapService = new DocumentGenerationFieldMapService();
    Map<String, String> recordFieldMap = fieldMapService.createRecordFieldMap(rec);

    String emailContent = this.processMergeFields(
      rec,
      recordFieldMap,
      this.docGenModel.docTemp.Email_Template__c,
      this.docGenModel.docTemp.Name
    );
    String fileName = this.processMergeFields(
      rec,
      recordFieldMap,
      this.docGenModel.docTemp.Filename__c,
      this.docGenModel.docTemp.Name
    );
    String emailSubject = this.processMergeFields(
      rec,
      recordFieldMap,
      this.docGenModel.docTemp.Email_Subject__c,
      this.docGenModel.docTemp.Name
    );

    // Logic for building an email for the email field in Email_Recipient_Field_Path__c
    // This is NOT used when in test mode.
    String recipientFieldPath = this.docGenModel.docTemp.Email_Recipient_Field_Path__c;

    DocumentEmail email = new DocumentEmail();
    email.blobContent = pageContentBlob;
    email.isTestMode = this.docGenModel.isTestMode;
    email.emailContent = emailContent;
    email.fileName = fileName;
    email.fromAddress = this.docGenModel.docTemp.FROM_Address__c;
    email.contentType = 'PDF';
    email.emailSubject = emailSubject;

    if (String.isNotBlank(recipientFieldPath) && this.docGenModel.isTestMode != true) {
      recipientFieldPath = recipientFieldPath.replace('{!', '').replace('}', '').toLowerCase();
      String TOAddress = DocGenFieldService.mergeRecordValue(rec, recipientFieldPath);
      if (String.isNotBlank(TOAddress)) {
        email.toAddress = TOAddress;
      }
    } else if (this.docGenModel.isTestMode == true) {
      email.toAddress = this.docGenModel.docTemp.Test_Mode_TO_Address__c;
    }

    return email;
  }

  public Boolean handleDocumentGeneration(List<DocumentGeneratorModel.Doc> documents) {
    return true;
  }

  public Boolean handleDocumentGeneration(List<SObject> recordList) {
    if (this.docGenSettings == null || recordList.isEmpty()) {
      System.debug('this.docGenSettings == null ? ' + this.docGenSettings == null);
      System.debug('recordList.isEmpty() ? ' + recordList.isEmpty());
      return false;
    }

    if (
      this.docGenModel.deliveryOption == 'PDF - Email' &&
      String.isNotBlank(this.docGenSettings.Email_Service__c)
    ) {
      this.emailService = DocumentEmailServiceFactory.getEmailServiceByType(
        docGenSettings.Email_Service__c
      );

      Map<Id, DocumentEmail> documentEmailMap = new Map<Id, DocumentEmail>();
      List<ContentVersion> contentVersions = new List<ContentVersion>();
      List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();

      for (SObject rec : recordList) {
        if (rec.Id == null) {
          return false;
        }

        PageReference page = this.getPageReference(rec.Id);
        Blob pageContentBlob = this.getPageContent(page);

        if (pageContentBlob == null) {
          return false;
        }

        try {
          DocumentEmail email = this.buildDocumentEmail(page, pageContentBlob, rec);
          documentEmailMap.put(rec.Id, email);

          if (this.docGenModel.docTemp.Attach_PDF_to_Primary_Record__c == true) {
            ContentVersion cv = new ContentVersion();
            cv.Title = email.fileName;
            cv.VersionData = email.blobContent;
            cv.PathOnClient = email.fileName + '.' + email.contentType;
            contentVersions.add(cv);
            email.contentVersion = cv;
          }
        } catch (Exception e) {
          System.debug('\n\nError: ' + e.getMessage());
          return false;
        }
      }

      if (!contentVersions.isEmpty()) {
        insert contentVersions;

        Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>(
          [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions]
        );

        for (SObject rec : recordList) {
          DocumentEmail email = documentEmailMap.get(rec.Id);
          ContentDocumentLink link = new ContentDocumentLink();
          link.ContentDocumentId = contentVersionMap.get(email.contentVersion.Id).ContentDocumentId;
          link.LinkedEntityId = rec.Id;
          link.ShareType = 'V';
          contentDocumentLinks.add(link);
        }

        insert contentDocumentLinks;
      }

      return this.emailService.sendEmails(documentEmailMap.values());
    } else if (this.docGenModel.deliveryOption == 'PDF - Direct Download') {
      // Build a list of 15 character record ids
      List<String> recordIds = new List<String>();
      for (SObject rec : recordList) {
        if (rec.Id == null) {
          return false;
        }
        String recordId = rec.Id;
        recordIds.add(recordId.substring(0, 15));
      }

      String recordIdsString = String.join(recordIds, ';');
      PageReference page = this.getPageReference(recordIdsString);
      Blob pdfContentBlob = this.getPageContent(page);
      if (pdfContentBlob == null) {
        // Don't return false here, let it blow up when inserting the content version so that the user can see the batch failing
        throw new DocumentGenerationException(
          'DocumentGenerationPDFHandler.handleDocumentGeneration: no content found. Failed to generate document(s) for pdf-direct download!'
        );
      }

      ContentVersion cv = new ContentVersion();
      cv.Title = recordIds[0] + '-' + recordIds[recordIds.size() - 1];
      cv.VersionData = pdfContentBlob;
      cv.PathOnClient = cv.Title + '.PDF';
      insert cv;

      Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id]
      .ContentDocumentId;

      ContentDocumentLink link = new ContentDocumentLink();
      link.ContentDocumentId = contentDocumentId;
      link.LinkedEntityId = this.docGenModel.jobLog.Id;
      link.ShareType = 'V';
      insert link;

      return true;
    } else {
      return false;
    }
  }

  private String processMergeFields(
    SObject rec,
    Map<String, String> recordFieldMap,
    String stringToParseThru,
    String altString
  ) {
    if (String.isBlank(stringToParseThru)) {
      return altString;
    }
    DocumentMergeFieldProcessor mergeFieldProcessor = new DocumentMergeFieldProcessor();
    mergeFieldProcessor.deliveryOption = this.docGenModel.deliveryOption;
    if (this.docGenModel.jobLog != null) {
      mergeFieldProcessor.jobLogId = this.docGenModel.jobLog.Id;
    }
    mergeFieldProcessor.mergeFieldAnswerMap = this.docGenModel.mergeFieldAnswerMap;
    mergeFieldProcessor.recordFieldMap = recordFieldMap;
    mergeFieldProcessor.record = rec;
    mergeFieldProcessor.stringToParseThru = stringToParseThru;
    return mergeFieldProcessor.processString();
  }

  public Boolean completeDocumentGeneration() {
    return true;
  }
}