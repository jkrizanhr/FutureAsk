global class DocumentGenerationController {
  global DocumentFieldLibrary fieldLib { get; set; }
  public List<DocumentGeneratorModel.Doc> documents { get; set; }
  global String deliveryOption { get; set; }
  public Boolean attachFile; // Attaches the content of the document as a file to the primary record
  public Boolean getContentOnly; // So that the post generation methods are not executed twice
  public Boolean isTestMode;
  public List<String> recordIds; // Record Ids for PDF direct-download generation
  public Map<String, String> questionIdAnswerMap;
  public String templateId;

  public DocumentGenerationController() {
    String recordIdsString = ApexPages.currentPage().getParameters().get('recordIds');
    this.documents = new List<DocumentGeneratorModel.Doc>();
    this.recordIds = new List<String>();
    if (String.isNotBlank(recordIdsString)) {
      this.recordIds = recordIdsString.split(';');
    }

    this.templateId = ApexPages.currentPage().getParameters().get('templateId');
    this.attachFile = ApexPages.currentPage().getParameters().get('attachFile') != null
      ? Boolean.valueOf(ApexPages.currentPage().getParameters().get('attachFile'))
      : false;
    this.isTestMode = ApexPages.currentPage().getParameters().get('isTestMode') != null
      ? Boolean.valueOf(ApexPages.currentPage().getParameters().get('isTestMode'))
      : false;
    this.deliveryOption = ApexPages.currentPage().getParameters().get('deliveryOption');
    this.questionIdAnswerMap = new Map<String, String>();
    this.getContentOnly = ApexPages.currentPage().getParameters().get('getContentOnly') != null
      ? Boolean.valueOf(ApexPages.currentPage().getParameters().get('getContentOnly'))
      : false;
    // Create an instance of DocumentFieldLibrary so that the instance variables can be
    // referenced in the visualforce page
    this.fieldLib = new DocumentFieldLibrary();
  }

  // This is called from the visualforce page
  public PageReference processDocuments() {
    System.debug('\n\nDocumentGenerationController.processSingleDocument');
    DocumentGenerationEngine engine = new DocumentGenerationEngine(
      this.recordIds,
      this.templateId,
      this.deliveryOption,
      this.isTestMode,
      false
    );
    engine.initDocumentTemplateData();
    engine.initDocumentQuestionMaps(null);
    engine.initDocumentTemplateQueries();
    engine.initDocumentGenerationHandler();
    String primarySOQLQueryString = engine.buildPrimarySOQLQueryString();
    // System.debug(recordIds);
    System.debug(
      'DocumentGenerationController.processSingleDocument: primarySOQLQueryString = \n' +
      primarySOQLQueryString
    );
    List<SObject> records = engine.getSObjectRecords(primarySOQLQueryString);
    // System.debug(records);
    engine.setRecordList(records);
    this.documents = engine.buildDocumentModels();

    // for (DocumentGeneratorModel.Doc res : this.documents) {
    //   System.debug('\n\nprimaryRecord: ');
    //   System.debug(res.primaryRecord);

    //   System.debug('aggregateQueries: ');
    //   for (String key : res.aggregateQueries.keySet()) {
    //     System.debug(key + ' : ' + res.aggregateQueries.get(key));
    //   }

    //   System.debug('customMetadataQueries: ');
    //   for (String key : res.customMetadataQueries.keySet()) {
    //     System.debug(key + ' : ' + res.customMetadataQueries.get(key));
    //   }

    //   System.debug('secondaryQueries: ');
    //   for (String key : res.secondaryQueries.keySet()) {
    //     System.debug(key + ' : ' + res.secondaryQueries.get(key));
    //   }

    //   System.debug('aggregateQuerySizes: ');
    //   for (String key : res.aggregateQuerySizes.keySet()) {
    //     System.debug(key + ' : ' + res.aggregateQuerySizes.get(key));
    //   }

    //   System.debug('secondaryQuerySizes: ');
    //   for (String key : res.secondaryQuerySizes.keySet()) {
    //     System.debug(key + ' : ' + res.secondaryQuerySizes.get(key));
    //   }
    // }

    // System.debug('getContentOnly = ' + this.getContentOnly);
    // System.debug('attachFile = ' + this.attachFile);

    // NOTE: On the initial load of the page generation for a one-off pdf-direct download,
    //  getContentOnly will be false
    if (this.getContentOnly == false) {
      Boolean isSuccess = engine.handleDocumentGeneration();
      if (isSuccess) {
        engine.handlePostGenerationMethods();
      }
      // So that the post generation methods are not executed twice and we know that the page has already loaded
      PageReference currentPage = ApexPages.currentPage();
      currentPage.getParameters().put('getContentOnly', 'true');
      if (this.attachFile == true) {
        // This is for one-off direct download.
        Document_Template__c template = engine.getDocumentTemplate();
        currentPage.getParameters().put('attachFile', 'false');
        Blob pdfContentBlob = currentPage.getContent();

        DocumentGenerationFieldMapService fieldMapService = new DocumentGenerationFieldMapService();
        Map<String, String> recordFieldMap = fieldMapService.createRecordFieldMap(records[0]);
        String fileName = engine.processMergeFields(
          records[0],
          recordFieldMap,
          template.Filename__c,
          template.Name
        );

        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.VersionData = pdfContentBlob;
        cv.PathOnClient = cv.Title + '.PDF';
        insert cv;

        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id]
        .ContentDocumentId;

        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = contentDocumentId;
        link.LinkedEntityId = this.recordIds[0];
        link.ShareType = 'V';
        insert link;

        System.debug('Successfully attached the file to the record.');
      }
      currentPage.setRedirect(true);
      return currentPage;
    }
    return null;
  }
}