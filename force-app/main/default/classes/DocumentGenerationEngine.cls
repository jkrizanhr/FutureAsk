public class DocumentGenerationEngine {
  private DocumentGeneratorModel docGenModel;
  private DocumentGenerationService docGenServiceHandler;
  private List<SObject> recordList;
  private List<String> recordIds; // DocumentGenerationController may have a string of record ids in URL for bulk pdf direct download

  public DocumentGenerationEngine(
    List<String> recordIds,
    String docTempId,
    String deliveryOption,
    Boolean isTestMode,
    Boolean isScheduled
  ) {
    this.docGenModel = new DocumentGeneratorModel(
      deliveryOption,
      docTempId,
      isTestMode,
      isScheduled
    );
    this.recordIds = recordIds;
    this.recordList = new List<SObject>();
  }

  public List<SObject> getSObjectRecords(String primarySOQLQueryString) {
    if (String.isBlank(primarySOQLQueryString)) {
      System.debug('No Primary SOQL Query!');
      return null;
    }
    List<SObject> records = Database.query(primarySOQLQueryString);
    return records;
  }

  public Id createJobLog(String batchJobId) {
    List<Document_Generation_Job_Log__c> logs = [
      SELECT
        Id,
        Async_Apex_Job_Id__c,
        Delivery_Option__c,
        Document_Template__c,
        Question_Answer_JSON__c
      FROM Document_Generation_Job_Log__c
      WHERE Async_Apex_Job_Id__c = :batchJobId
    ];

    if (logs.isEmpty()) {
      Document_Generation_Job_Log__c jobLog = new Document_Generation_Job_Log__c();
      jobLog.Async_Apex_Job_Id__c = batchJobId;
      jobLog.Delivery_Option__c = this.docGenModel.deliveryOption;
      jobLog.Document_Template__c = this.docGenModel.docTempId;
      jobLog.Question_Answer_JSON__c = JSON.serialize(this.docGenModel.questionIdAnswerMap);
      insert jobLog;
      this.docGenModel.jobLog = jobLog;
      return jobLog.Id;
    } else {
      this.docGenModel.jobLog = logs[0];
      return logs[0].Id;
    }
  }

  public void updateJobLog(String postGenJobId) {
    this.docGenModel.jobLog.Post_Generation_Job_Id__c = postGenJobId.substring(0, 15);
    update this.docGenModel.jobLog;
  }

  public void initDocumentTemplateData() {
    List<Document_Template__c> docTemplates = DocumentGenerationTemplateDataService.fetchDocTemplates(
      this.docGenModel.docTempId
    );
    if (docTemplates.isEmpty()) {
      return;
    }
    this.docGenModel.docTemp = docTemplates[0];
    this.docGenModel.docTempQueryList = DocumentGenerationTemplateDataService.fetchDocTemplateQueries(
      this.docGenModel.docTempId
    );
    this.docGenModel.docTempQuestionList = DocumentGenerationTemplateDataService.fetchDocTemplateQuestions(
      this.docGenModel.docTempId
    );
    this.docGenModel.docTempOptionList = DocumentGenerationTemplateDataService.fetchDocQuestionOptions(
      this.docGenModel.docTempId
    );

    // We only want to do the Document Post Generation Methods that are meant for the delivery option selected.
    List<Document_Post_Generation_Method__c> postMethods = DocumentGenerationTemplateDataService.fetchDocGenPostMethods(
      this.docGenModel.docTempId
    );
    for (Document_Post_Generation_Method__c postMethod : postMethods) {
      if (
        String.isNotBlank(postMethod.Delivery_Options__c) &&
        postMethod.Delivery_Options__c.contains(this.docGenModel.deliveryOption)
      ) {
        this.docGenModel.docTempPostMethodList.add(postMethod);
      }
    }
  }

  public void initDocumentQuestionMaps(Map<String, String> questionIdAnswerMap) {
    if (this.docGenModel.docTempQuestionList.isEmpty()) {
      return;
    }
    if (questionIdAnswerMap == null) {
      questionIdAnswerMap = new Map<String, String>();
      for (Document_Template_Question__c question : this.docGenModel.docTempQuestionList) {
        String answer = ApexPages.currentPage().getParameters().get(question.Id);
        questionIdAnswerMap.put(question.Id, answer);
      }
    }

    this.docGenModel.questionIdAnswerMap = questionIdAnswerMap;

    Map<Id, Document_Template_Question__c> docTempQuestionMap = new Map<Id, Document_Template_Question__c>(
      this.docGenModel.docTempQuestionList
    );

    for (String questionId : questionIdAnswerMap.keySet()) {
      Document_Template_Question__c docTempQuestion = docTempQuestionMap.get(questionId);
      if (docTempQuestion != null) {
        String answer = questionIdAnswerMap.get(questionId);
        if (
          String.isNotBlank(answer) &&
          answer != '\' ' + '\'' &&
          String.isNotBlank(docTempQuestion.Query_Merge_Override__c)
        ) {
          this.doMergeOverrideLogic(docTempQuestion, answer);
        }
        if (String.isNotBlank(docTempQuestion.Query_Merge_Field__c)) {
          // Add to the merge field map
          this.docGenModel.mergeFieldAnswerMap.put(
            docTempQuestion.Query_Merge_Field__c.toLowerCase(),
            answer
          );
        }
      }
    }
  }

  private void doMergeOverrideLogic(Document_Template_Question__c docTempQuestion, String answer) {
    if (docTempQuestion.Query_Merge_Override__c == 'Replace' && this.isValidAnswer(answer)) {
      this.docGenModel.queryIdReplaceMap.put(docTempQuestion.Document_Template_Query__c, answer);
    } else if (
      docTempQuestion.Query_Merge_Override__c == 'Append' &&
      (this.isValidAnswer(answer) || String.isNotBlank(docTempQuestion.Apply_Value_to__c))
    ) {
      List<String> appendList = this.docGenModel.queryIdAppendMap.get(
        docTempQuestion.Document_Template_Query__c
      );
      if (appendList == null) {
        appendList = new List<String>();
        this.docGenModel.queryIdAppendMap.put(
          docTempQuestion.Document_Template_Query__c,
          appendList
        );
      }

      if (String.isBlank(docTempQuestion.Apply_Value_to__c)) {
        appendList.add(answer);
      } else {
        appendList.add(docTempQuestion.Apply_Value_to__c);
        // Add to the mergeFieldDataTypeMap
        if (String.isNotBlank(docTempQuestion.Question_Field_Type__c)) {
          this.docGenModel.mergeFieldDataTypeMap.put(
            docTempQuestion.Query_Merge_Field__c.toLowerCase(),
            docTempQuestion.Question_Field_Type__c
          );
        }
      }
    }
  }

  private Boolean isValidAnswer(String answer) {
    if (String.isNotBlank(answer) && answer != '\' ' + '\'') {
      return true;
    }
    return false;
  }

  public void initDocumentTemplateQueries() {
    for (Document_Template_Query__c docTempQuery : this.docGenModel.docTempQueryList) {
      if (
        docTempQuery.RecordTypeId != null && String.isNotBlank(docTempQuery.RecordType.Name) &&
        String.isNotBlank(docTempQuery.Name) &&
        String.isNotBlank(docTempQuery.SOQL_Query__c)
      ) {
        if (
          docTempQuery.RecordType.Name == 'Primary SOQL Query' &&
          (this.docGenModel.docTempPrimaryQuery == null ||
          String.isBlank(this.docGenModel.docTempPrimaryQuery.SOQL_Query__c))
        ) {
          this.docGenModel.docTempPrimaryQuery = docTempQuery;
        } else if (docTempQuery.RecordType.Name == 'Custom Metadata SOQL Query') {
          this.docGenModel.docTempCustomMetadataQueryList.add(docTempQuery);
        } else if (
          docTempQuery.RecordType.Name == 'Secondary SOQL Query' &&
          String.isNotBlank(docTempQuery.Primary_Query_Correlation__c) &&
          String.isNotBlank(docTempQuery.Correlating_Query_Field__c)
        ) {
          this.docGenModel.docTempSecondaryQueryList.add(docTempQuery);
        } else if (
          docTempQuery.RecordType.Name == 'Aggregate SOQL Query' &&
          String.isNotBlank(docTempQuery.Primary_Query_Correlation__c) &&
          String.isNotBlank(docTempQuery.Correlating_Query_Field__c)
        ) {
          this.docGenModel.docTempAggregateQueryList.add(docTempQuery);
        }
      }
    }
  }

  public void initDocumentGenerationHandler() {
    String docType;
    if (
      this.docGenModel.deliveryOption == 'PDF - Email' ||
      this.docGenModel.deliveryOption == 'PDF - Direct Download'
    ) {
      docType = 'PDF';
    } else if (
      this.docGenModel.deliveryOption == 'CSV - Email' ||
      this.docGenModel.deliveryOption == 'CSV - Direct Download'
    ) {
      docType = 'CSV';
    }
    if (String.isNotBlank(docType)) {
      this.docGenServiceHandler = DocumentGenerationServiceFactory.getDocumentGenerationHandlerByType(
        docType
      );
      this.docGenServiceHandler.init(this.docGenModel);
    }
  }

  public String buildPrimarySOQLQueryString() {
    if (this.docGenModel.docTempPrimaryQuery != null) {
      this.docGenModel.primarySOQLString = this.getQueryString(
        this.docGenModel.docTempPrimaryQuery
      );
    }
    return this.docGenModel.primarySOQLString;
  }

  public String buildSelectCountSOQLQueryString() {
    String queryString;
    DocumentGenerationQueryHelper queryHelper = new DocumentGenerationQueryHelper(
      this.docGenModel.docTempPrimaryQuery
    );
    queryHelper.appendWhereClauseList = this.docGenModel.queryIdAppendMap.get(
      this.docGenModel.docTempPrimaryQuery.Id
    );
    queryHelper.replacementWhereClause = this.docGenModel.queryIdReplaceMap.get(
      this.docGenModel.docTempPrimaryQuery.Id
    );

    DocumentMergeFieldProcessor mergeFieldProcessor = new DocumentMergeFieldProcessor();
    queryString = queryHelper.buildSelectCountQueryString(this.recordIds);
    mergeFieldProcessor.deliveryOption = this.docGenModel.deliveryOption;
    mergeFieldProcessor.stringToParseThru = queryString;
    mergeFieldProcessor.mergeFieldAnswerMap = this.docGenModel.mergeFieldAnswerMap;
    if (this.docGenModel.jobLog != null) {
      mergeFieldProcessor.jobLogId = this.docGenModel.jobLog.Id;
    }
    queryString = mergeFieldProcessor.processString();
    return queryString;
  }

  public void setRecordList(List<SObject> records) {
    this.recordList = records;
  }

  public Document_Template__c getDocumentTemplate() {
    return this.docGenModel.docTemp;
  }

  public String getPrimarySOQLQueryString() {
    return this.docGenModel.primarySOQLString;
  }

  public List<String> getSecondarySOQLQueryStrings() {
    return this.docGenModel.queryIdSecondarySOQLStringMap.values();
  }

  public List<String> getAggregateSOQLQueryStrings() {
    return this.docGenModel.queryIdAggregateSOQLStringMap.values();
  }

  public List<String> getCustomMetadataSOQLQueryStrings() {
    return this.docGenModel.queryIdCustomMetadataSOQLStringMap.values();
  }

  public List<DocumentGeneratorModel.ErrorLog> getErrorLogs() {
    return this.docGenModel.errorLogs;
  }

  /**
   * Called from DocumentGeneratorCompController for One-Off emails
   * Called from DocumentGenerationBatchJob in the execute for each batch of records
   * Called from the DocumentGenerationController for One-Off Direct - Download
   *
   * For PDF - Email delivery option, we will execute the post generation methods
   * therefore creating/updating records such as tasks for each record within the batch.
   *
   * For CSV delivery options, we will build a list of inserts/updates from the post generation methods
   * then call a separate batch job to execute them when the batch job has completed.
   */
  public Boolean handleDocumentGeneration() {
    if (this.recordList == null || this.recordList.isEmpty() == true) {
      System.debug('DocumentGenerationEngine.handleDocumentGeneration: no records!');
      throw new DocumentGenerationException(
        'DocumentGenerationEngine.handleDocumentGeneration: no records!'
      );
    }
    if (String.isBlank(this.docGenModel.deliveryOption)) {
      throw new DocumentGenerationException(
        'DocumentGenerationEngine.handleDocumentGeneration: no delivery option!'
      );
    }
    if (this.docGenServiceHandler == null) {
      throw new DocumentGenerationException(
        'DocumentGenerationEngine.handleDocumentGeneration: docGenServiceHandler is null!'
      );
    }

    System.debug('this.docGenModel.jobLog = ' + this.docGenModel.jobLog);
    System.debug('deliveryOption = ' + this.docGenModel.deliveryOption);

    Boolean isSuccess = false;
    if (
      this.docGenModel.jobLog == null &&
      this.docGenModel.deliveryOption == 'PDF - Direct Download'
    ) {
      // One-off PDF - Direct Download or getting content of pdf
      isSuccess = true;
    } else if (
      this.docGenModel.jobLog == null &&
      this.docGenModel.deliveryOption == 'PDF - Email'
    ) {
      isSuccess = this.docGenServiceHandler.handleDocumentGeneration(this.recordList);
    } else if (
      this.docGenModel.jobLog != null &&
      (this.docGenModel.deliveryOption == 'PDF - Email' ||
      this.docGenModel.deliveryOption == 'PDF - Direct Download')
    ) {
      // Bulk PDF - Email or Bulk PDF - Direct Download. Initial call from DocumentGenerationBatchJob
      // buildDocumentModels will be called from the DocumentGenerationController when the PDF is rendered
      isSuccess = this.docGenServiceHandler.handleDocumentGeneration(this.recordList);
    } else if (
      this.docGenModel.jobLog != null &&
      (this.docGenModel.deliveryOption == 'CSV - Email' ||
      this.docGenModel.deliveryOption == 'CSV - Direct Download')
    ) {
      // Bulk CSV - Email or Bulk CSV - Direct Download
      List<DocumentGeneratorModel.Doc> documents = this.buildDocumentModels();
      isSuccess = this.docGenServiceHandler.handleDocumentGeneration(documents);
    }

    return isSuccess;
  }

  public void handlePostGenerationMethods() {
    if (
      this.docGenModel.isTestMode == true ||
      this.docGenModel.docTempPostMethodList.isEmpty() == true
    ) {
      return;
    }

    DocumentPostGenMethodService postGenMethodService = new DocumentPostGenMethodService(
      this.docGenModel.docTempPostMethodList,
      this.docGenModel.deliveryOption,
      this.docGenModel.mergeFieldAnswerMap,
      this.docGenModel.jobLog != null ? this.docGenModel.jobLog.Id : null
    );
    List<DocumentGeneratorModel.PostGenContainer> postGenContainers = postGenMethodService.processRecords(
      this.recordList
    );

    if (this.docGenModel.deliveryOption == 'PDF - Email') {
      // Execute post generation methods now that the emails have been sent.
      DocumentPostGenMethodService.executePostGenContainerMethods(
        postGenContainers,
        this.docGenModel.jobLog != null ? this.docGenModel.jobLog.Id : null
      );
    } else if (
      this.docGenModel.jobLog != null &&
      (this.docGenModel.deliveryOption == 'CSV - Email' ||
      this.docGenModel.deliveryOption == 'CSV - Direct Download' ||
      this.docGenModel.deliveryOption == 'PDF - Direct Download')
    ) {
      // Bulk generation - just build the post generation methods
      this.docGenModel.postGenContainers.addAll(postGenContainers);
    } else if (
      this.docGenModel.deliveryOption == 'PDF - Direct Download' &&
      this.docGenModel.jobLog == null
    ) {
      // NOTE: If jobLog is null, then we know that it is the render of the pdf
      // Add the document template name and queries to the emailcontentstring
      String emailContentString = 'Document Template: ' + this.docGenModel.docTemp.Name;
      emailContentString += '\n\nPrimary SOQL Query String: \n' + this.getPrimarySOQLQueryString();
      List<String> secondaryQueryStrings = this.getSecondarySOQLQueryStrings();
      for (String qs : secondaryQueryStrings) {
        emailContentString += '\n\nSecondary SOQL Query String: \n' + qs;
      }
      List<String> aggregateQueryStrings = this.getAggregateSOQLQueryStrings();
      for (String qs : aggregateQueryStrings) {
        emailContentString += '\n\nAggregate SOQL Query String: \n' + qs;
      }
      List<String> customMetadataQueryStrings = this.getCustomMetadataSOQLQueryStrings();
      for (String qs : customMetadataQueryStrings) {
        emailContentString += '\n\nCustom Metadata SOQL Query String: \n' + qs;
      }

      // Call future method to handle the inserts, updates, and emailing
      DocumentPostGenMethodService.finishPdfDirectDownloadPostMethods(
        JSON.serialize(postGenContainers)
      );
    }
  }

  public List<String> buildPostGenContainerJSONStrings() {
    List<String> postGenJSONs = new List<String>();
    for (
      DocumentGeneratorModel.PostGenContainer postGenContainer : this.docGenModel.postGenContainers
    ) {
      String postGenJSON = JSON.serialize(postGenContainer);
      postGenJSONs.add(postGenJSON);
    }
    return postGenJSONs;
  }

  /**
   * Called from DocumentGenerationBatchJob
   * Intermediary method used to call the batch job completion methods
   * which will email the CSV file or insert the CSV file as a Content Version record.
   * @param batchJobId
   * @return
   */
  public Boolean finishCSVGeneration() {
    return this.docGenServiceHandler.completeDocumentGeneration();
  }

  public List<DocumentGeneratorModel.Doc> buildDocumentModels() {
    List<DocumentGeneratorModel.Doc> documents = new List<DocumentGeneratorModel.Doc>();
    if (this.recordList == null || this.recordList.isEmpty()) {
      System.debug('DocumentGenerationEngine.buildDocumentModels: recordList is NULL or empty!');
      return documents;
    }
    Map<Id, Set<String>> queryResultJoinMap = this.buildQueryResultJoinMap();
    Map<String, List<SObject>> customMetadataQueryResultMap = this.getCustomMetadataQueriesResults();
    List<DocumentGeneratorModel.DocumentQueryResult> secondaryDocumentQueryResults = this.getSecondaryQueriesResults(
      queryResultJoinMap
    );
    List<DocumentGeneratorModel.DocumentQueryResult> aggregateDocumentQueryResults = this.getAggregateQueriesResults(
      queryResultJoinMap
    );

    for (SObject record : this.recordList) {
      DocumentGeneratorModel.Doc doc = new DocumentGeneratorModel.Doc();
      doc.primaryRecord = record;
      doc.customMetadataQueries = customMetadataQueryResultMap;

      for (
        DocumentGeneratorModel.DocumentQueryResult documentQueryResult : secondaryDocumentQueryResults
      ) {
        String secondaryQueryCorrelationFieldValue = DocGenFieldService.mergeRecordValue(
          record,
          documentQueryResult.primaryQueryCorrelationField
        );
        List<SObject> secondaryQueryResults = new List<SObject>();
        if (
          documentQueryResult.secondaryQueryResultMap.containsKey(
            secondaryQueryCorrelationFieldValue
          )
        ) {
          secondaryQueryResults = documentQueryResult.secondaryQueryResultMap.get(
            secondaryQueryCorrelationFieldValue
          );
        }
        doc.secondaryQueries.put(documentQueryResult.queryDeveloperName, secondaryQueryResults);
        doc.secondaryQuerySizes.put(
          documentQueryResult.queryDeveloperName,
          secondaryQueryResults.size()
        );
      }

      for (
        DocumentGeneratorModel.DocumentQueryResult documentQueryResult : aggregateDocumentQueryResults
      ) {
        System.debug(documentQueryResult);
        String aggregateQueryCorrelationFieldValue = DocGenFieldService.mergeRecordValue(
          record,
          documentQueryResult.primaryQueryCorrelationField
        );
        List<AggregateResult> aggregateQueryResults = new List<AggregateResult>();
        System.debug(aggregateQueryCorrelationFieldValue);
        if (
          documentQueryResult.aggregateQueryResultMap.containsKey(
            aggregateQueryCorrelationFieldValue
          )
        ) {
          aggregateQueryResults = documentQueryResult.aggregateQueryResultMap.get(
            aggregateQueryCorrelationFieldValue
          );
        }
        doc.aggregateQueries.put(documentQueryResult.queryDeveloperName, aggregateQueryResults);
        doc.aggregateQuerySizes.put(
          documentQueryResult.queryDeveloperName,
          aggregateQueryResults.size()
        );
      }

      documents.add(doc);
    }

    return documents;
  }

  /**
   * Sources:
   * buildPrimarySOQLQueryString
   * getCustomMetadataQueriesResults
   * getSecondaryQueriesResults
   * getAggregateQueriesResults
   *
   * @param templateQuery
   * @return
   */
  private String getQueryString(Document_Template_Query__c templateQuery) {
    String queryString;
    DocumentGenerationQueryHelper queryHelper = new DocumentGenerationQueryHelper(templateQuery);
    queryHelper.appendWhereClauseList = this.docGenModel.queryIdAppendMap.get(templateQuery.Id);
    queryHelper.replacementWhereClause = this.docGenModel.queryIdReplaceMap.get(templateQuery.Id);

    DocumentMergeFieldProcessor mergeFieldProcessor = new DocumentMergeFieldProcessor();
    if (templateQuery.Id == this.docGenModel.docTempPrimaryQuery.Id) {
      queryString = queryHelper.buildPrimarySOQLQueryString(
        this.recordIds,
        this.docGenModel.docTemp.Email_Recipient_Field_Path__c
      );
    } else {
      if (String.isNotBlank(templateQuery.Primary_Query_Correlation__c)) {
        if (templateQuery.Primary_Query_Correlation__c.startsWith('{!')) {
          templateQuery.Primary_Query_Correlation__c = templateQuery.Primary_Query_Correlation__c.substring(
            2,
            templateQuery.Primary_Query_Correlation__c.length() - 1
          );
        }
        templateQuery.Primary_Query_Correlation__c = templateQuery.Primary_Query_Correlation__c.toLowerCase();
        mergeFieldProcessor.primaryQueryCorrelation = templateQuery.Primary_Query_Correlation__c;
      }

      if (String.isNotBlank(templateQuery.Correlating_Query_Field__c)) {
        if (templateQuery.Correlating_Query_Field__c.startsWith('{!')) {
          templateQuery.Correlating_Query_Field__c = templateQuery.Correlating_Query_Field__c.substring(
            2,
            templateQuery.Correlating_Query_Field__c.length() - 1
          );
        }
        templateQuery.Correlating_Query_Field__c = templateQuery.Correlating_Query_Field__c.toLowerCase();
      }

      queryString = queryHelper.buildSOQLQueryString();
    }

    mergeFieldProcessor.deliveryOption = this.docGenModel.deliveryOption;
    mergeFieldProcessor.stringToParseThru = queryString;
    mergeFieldProcessor.mergeFieldAnswerMap = this.docGenModel.mergeFieldAnswerMap;
    if (this.docGenModel.jobLog != null) {
      mergeFieldProcessor.jobLogId = this.docGenModel.jobLog.Id;
    }
    queryString = mergeFieldProcessor.processString();
    return queryString;
  }

  private Map<Id, Set<String>> buildQueryResultJoinMap() {
    // Document Template Query Id : set of id values to join
    // the aggregate/secondary query results to the primary query results
    Map<Id, Set<String>> queryResultJoinMap = new Map<Id, Set<String>>();

    if (this.docGenModel.docTempQueryList == null || this.docGenModel.docTempQueryList.isEmpty()) {
      System.debug('ERROR: no document template queries!');
      return queryResultJoinMap;
    }

    for (SObject rec : this.recordList) {
      for (Document_Template_Query__c templateQuery : this.docGenModel.docTempQueryList) {
        if (
          String.isNotBlank(templateQuery.Primary_Query_Correlation__c) &&
          String.isNotBlank(templateQuery.Correlating_Query_Field__c)
        ) {
          // Primary Query Result values (Id type) to join to the aggregate/secondary query results
          Set<String> idJoinValues = queryResultJoinMap.get(templateQuery.Id);
          if (idJoinValues == null) {
            idJoinValues = new Set<String>();
          }
          String fieldValue = DocGenFieldService.mergeRecordValue(
            rec,
            templateQuery.Primary_Query_Correlation__c
          );
          idJoinValues.add(fieldValue);
          queryResultJoinMap.put(templateQuery.Id, idJoinValues);
        }
      }
    }
    return queryResultJoinMap;
  }

  private Map<String, List<SObject>> getCustomMetadataQueriesResults() {
    Map<String, List<SObject>> metadataQueryResultMap = new Map<String, List<SObject>>();
    for (
      Document_Template_Query__c templateQuery : this.docGenModel.docTempCustomMetadataQueryList
    ) {
      String developerName = templateQuery.Name.replaceAll(' ', '_');
      String queryString = this.getQueryString(templateQuery);
      metadataQueryResultMap.put(developerName, new List<SObject>());
      this.docGenModel.queryIdCustomMetadataSOQLStringMap.put(templateQuery.Id, queryString);
      List<SObject> metadataQueryResults = Database.query(queryString);
      for (SObject res : metadataQueryResults) {
        metadataQueryResultMap.get(developerName).add(res);
      }
    }
    return metadataQueryResultMap;
  }

  private List<DocumentGeneratorModel.DocumentQueryResult> getSecondaryQueriesResults(
    Map<Id, Set<String>> queryResultJoinMap
  ) {
    List<DocumentGeneratorModel.DocumentQueryResult> documentQueryResults = new List<DocumentGeneratorModel.DocumentQueryResult>();

    for (Document_Template_Query__c templateQuery : this.docGenModel.docTempSecondaryQueryList) {
      String queryString = this.getQueryString(templateQuery);
      this.docGenModel.queryIdSecondarySOQLStringMap.put(templateQuery.Id, queryString);

      DocumentGeneratorModel.DocumentQueryResult queryResultModel = new DocumentGeneratorModel.DocumentQueryResult();
      queryResultModel.primaryQueryCorrelationField = templateQuery.Primary_Query_Correlation__c;
      queryResultModel.queryDeveloperName = templateQuery.Name.replaceAll(' ', '_');
      documentQueryResults.add(queryResultModel);

      // Create local variable so that the dynamic soql query can reference it
      // NOTE: The variable is intentionally all lowercase!
      // Primary Query Result values (Id type) to join to the secondary query results
      Set<String> ids = queryResultJoinMap.get(templateQuery.Id);
      for (String idStr : ids) {
        if (String.isNotBlank(idStr)) {
          Id id = Id.valueOf(idStr);
          if (queryResultModel.secondaryQueryResultMap.containsKey(id) == false) {
            queryResultModel.secondaryQueryResultMap.put(id, new List<SObject>());
          }
        }
      }

      List<SObject> secondaryQueryResultList = Database.query(queryString);

      for (SObject res : secondaryQueryResultList) {
        String fieldValue = DocGenFieldService.mergeRecordValue(
          res,
          templateQuery.Correlating_Query_Field__c
        );
        if (String.isNotBlank(fieldValue)) {
          Id correlatingFieldValue = Id.valueOf(fieldValue);
          List<SObject> results = queryResultModel.secondaryQueryResultMap.get(
            correlatingFieldValue
          );
          if (results == null) {
            results = new List<SObject>();
          }
          results.add(res);
          queryResultModel.secondaryQueryResultMap.put(correlatingFieldValue, results);
        }
      }
    }
    return documentQueryResults;
  }

  private List<DocumentGeneratorModel.DocumentQueryResult> getAggregateQueriesResults(
    Map<Id, Set<String>> queryResultJoinMap
  ) {
    List<DocumentGeneratorModel.DocumentQueryResult> documentQueryResults = new List<DocumentGeneratorModel.DocumentQueryResult>();
    for (Document_Template_Query__c templateQuery : this.docGenModel.docTempAggregateQueryList) {
      String queryString = this.getQueryString(templateQuery);
      this.docGenModel.queryIdAggregateSOQLStringMap.put(templateQuery.Id, queryString);

      DocumentGeneratorModel.DocumentQueryResult queryResultModel = new DocumentGeneratorModel.DocumentQueryResult();
      queryResultModel.primaryQueryCorrelationField = templateQuery.Primary_Query_Correlation__c;
      queryResultModel.queryDeveloperName = templateQuery.Name.replaceAll(' ', '_');
      documentQueryResults.add(queryResultModel);

      // Create local variable so that the dynamic soql query can reference it
      // NOTE: The variable is intentionally all lowercase!
      // Primary Query Result values (Id type) to join to the aggregate query results
      Set<String> ids = queryResultJoinMap.get(templateQuery.Id);
      for (String idStr : ids) {
        if (String.isNotBlank(idStr)) {
          Id id = Id.valueOf(idStr);
          if (queryResultModel.aggregateQueryResultMap.containsKey(id) == false) {
            queryResultModel.aggregateQueryResultMap.put(id, new List<AggregateResult>());
          }
        }
      }

      System.debug(queryString);
      System.debug(ids);
      List<AggregateResult> aggregateResultList = Database.query(queryString);

      for (AggregateResult res : aggregateResultList) {
        String fieldValue = res.get(templateQuery.Correlating_Query_Field__c) != null
          ? (String) res.get(templateQuery.Correlating_Query_Field__c)
          : '';
        if (String.isNotBlank(fieldValue)) {
          Id correlatingFieldValue = Id.valueOf(fieldValue);
          List<AggregateResult> results = queryResultModel.aggregateQueryResultMap.get(
            correlatingFieldValue
          );
          if (results == null) {
            results = new List<AggregateResult>();
          }
          results.add(res);
          queryResultModel.aggregateQueryResultMap.put(correlatingFieldValue, results);
        }
      }
    }
    return documentQueryResults;
  }

  /**
   * This is called from the DocumentGeneration controller
   * for one-off pdf-direct download when attaching the file to the primary record
   */
  public String processMergeFields(
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
}