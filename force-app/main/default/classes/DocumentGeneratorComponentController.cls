public class DocumentGeneratorComponentController {
  private static Boolean isValidField(String sObjectName, String field) {
    Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(sObjectName);
    Schema.DescribeSObjectResult sObjResult = sObjType.getDescribe();
    Map<String, SObjectField> sObjFieldMap = sObjResult.fields.getMap();
    if (sObjFieldMap.containsKey(field)) {
      return true;
    }
    return false;
  }

  @AuraEnabled
  public static List<Document_Template__c> fetchDocumentTemplates(
    String sObjectName,
    Boolean isOneOff
  ) {
    Set<String> availableForSet = getAvailableForSet(isOneOff);
    String queryString =
      'SELECT ' +
      'Attach_PDF_to_Primary_Record__c, ' +
      'Delivery_Options__c, ' +
      'Id, ' +
      'Is_Default__c, ' +
      'Name, ' +
      'Salesforce_Object__c, ' +
      'Template_Instructions__c, ' +
      'Visualforce_Page__c, ' +
      '(SELECT Id, Delivery_Options__c FROM Document_Post_Generation_Methods__r) ' +
      'FROM Document_Template__c ' +
      'WHERE Is_Active__c = TRUE ' +
      'AND Available_For__c IN :availableForSet ';

    if (String.isNotBlank(sObjectName)) {
      queryString += 'AND Salesforce_Object__c = :sObjectName ';
    }
    queryString += 'ORDER BY Name';
    List<Document_Template__c> templates = Database.query(queryString);
    return templates;
  }

  @AuraEnabled
  public static List<Document_Template_Query__c> fetchTemplateQueries(String docTempId) {
    return [
      SELECT Id, RecordType.Name, SOQL_Query__c
      FROM Document_Template_Query__c
      WHERE Document_Template__c = :docTempId
      ORDER BY Query_Execution_Order__c
    ];
  }

  @AuraEnabled
  public static List<Document_Template_Question__c> fetchQuestions(
    String docTempId,
    Boolean isOneOff
  ) {
    Set<String> availableForSet = getAvailableForSet(isOneOff);
    return [
      SELECT
        Apply_Value_to__c,
        Available_for__c,
        Id,
        Is_Required__c,
        Query_Merge_Field__c,
        Query_Merge_Override__c,
        Question__c,
        Question_Field_Type__c,
        Question_Help_Text__c,
        URL_Parameter__c
      FROM Document_Template_Question__c
      WHERE Document_Template__c = :docTempId AND Available_for__c IN :availableForSet
      ORDER BY Question_Order__c
    ];
  }

  private static Set<String> getAvailableForSet(Boolean isOneOff) {
    Set<String> availableForSet = new Set<String>{ 'Both' };
    if (isOneOff) {
      availableForSet.add('Single');
    } else {
      availableForSet.add('Bulk');
    }
    return availableForSet;
  }

  @AuraEnabled
  public static List<Document_Template_Question_Option__c> fetchQuestionOptions(
    String docTempId,
    Boolean isOneOff
  ) {
    Set<String> availableForSet = getAvailableForSet(isOneOff);
    return [
      SELECT Default_Option__c, Document_Template_Question__c, Id, Name, Option_Value__c
      FROM Document_Template_Question_Option__c
      WHERE
        Document_Template__c = :docTempId
        AND Document_Template_Question__r.Available_for__c IN :availableForSet
      ORDER BY Document_Template_Question__r.Question_Order__c, CreatedDate DESC
    ];
  }

  @AuraEnabled
  public static String validatePrimaryQuery(String paramModelJSON) {
    DocumentGeneratorModel.Params paramModel = (DocumentGeneratorModel.Params) JSON.deserialize(
      paramModelJSON,
      DocumentGeneratorModel.Params.class
    );

    if (paramModel == null || String.isBlank(paramModel.deliveryOption)) {
      return null;
    }

    Map<String, String> questionIdAnswerMap = new Map<String, String>();
    if (String.isNotBlank(paramModel.questionAnswerMapJSON)) {
      questionIdAnswerMap = (Map<String, String>) JSON.deserialize(
        paramModel.questionAnswerMapJSON,
        Map<String, String>.class
      );
    }
    DocumentGeneratorModel docGenModel = new DocumentGeneratorModel(paramModel);
    List<String> recordIds = new List<String>();
    if (String.isNotBlank(paramModel.recordId)) {
      recordIds.add(paramModel.recordId);
    }
    DocumentGenerationEngine engine = new DocumentGenerationEngine(
      recordIds,
      paramModel.templateId,
      paramModel.deliveryOption,
      paramModel.isTestMode,
      false
    );
    engine.initDocumentTemplateData();
    engine.initDocumentQuestionMaps(questionIdAnswerMap);
    engine.initDocumentTemplateQueries();
    engine.initDocumentGenerationHandler();
    String primarySOQLQueryString = engine.buildPrimarySOQLQueryString();
    docGenModel.pqValidator.primaryQueryString = primarySOQLQueryString;

    if (String.isNotBlank(primarySOQLQueryString)) {
      if (primarySOQLQueryString.containsIgnoreCase('limit') == false) {
        primarySOQLQueryString += ' LIMIT 1';
      } else {
        primarySOQLQueryString = primarySOQLQueryString.toLowerCase().substringBeforeLast('limit');
        primarySOQLQueryString += ' LIMIT 1';
      }
    }

    try {
      List<SObject> sObjList = engine.getSObjectRecords(primarySOQLQueryString);

      if (sObjList.isEmpty() == true) {
        docGenModel.pqValidator.isValid = false;
        docGenModel.pqValidator.statusMessage = 'The primary SOQL query returned no results.';
      } else {
        docGenModel.pqValidator.isValid = true;
      }
    } catch (Exception e) {
      docGenModel.pqValidator.isValid = false;
      docGenModel.pqValidator.statusMessage = e.getMessage();
    }

    docGenModel.pqValidator.selectCountQueryString = engine.buildSelectCountSOQLQueryString();
    docGenModel.pqValidator.count = Database.countQuery(
      docGenModel.pqValidator.selectCountQueryString
    );

    String pqValidationJSON = JSON.serialize(docGenModel.pqValidator);
    return pqValidationJSON;
  }

  @AuraEnabled
  public static void initSingleDocumentEmail(String paramModelJSON) {
    DocumentGeneratorModel.Params paramModel = (DocumentGeneratorModel.Params) JSON.deserialize(
      paramModelJSON,
      DocumentGeneratorModel.Params.class
    );

    Map<String, String> questionIdAnswerMap = new Map<String, String>();
    if (String.isNotBlank(paramModel.questionAnswerMapJSON)) {
      questionIdAnswerMap = (Map<String, String>) JSON.deserialize(
        paramModel.questionAnswerMapJSON,
        Map<String, String>.class
      );
    }

    DocumentGenerationEngine engine = new DocumentGenerationEngine(
      new List<String>{ paramModel.recordId },
      paramModel.templateId,
      paramModel.deliveryOption,
      paramModel.isTestMode,
      false
    );
    engine.initDocumentTemplateData();
    engine.initDocumentQuestionMaps(questionIdAnswerMap);
    engine.initDocumentTemplateQueries();
    engine.initDocumentGenerationHandler();

    // This is pretty much just to get the ids so we can loop through them in the processPDFGeneration
    // which gets the visualforce page content.
    // Therefore we do not need to execute the aggregate result queries here.
    String primarySOQLQueryString = engine.buildPrimarySOQLQueryString();
    List<SObject> sObjList = engine.getSObjectRecords(primarySOQLQueryString);

    engine.setRecordList(sObjList);
    Boolean isSuccess = engine.handleDocumentGeneration();
    if (isSuccess) {
      engine.handlePostGenerationMethods();
    }
  }

  @AuraEnabled
  public static void processMassDocuments(String paramModelJSON) {
    DocumentGeneratorModel.Params paramModel = (DocumentGeneratorModel.Params) JSON.deserialize(
      paramModelJSON,
      DocumentGeneratorModel.Params.class
    );

    Map<String, String> questionIdAnswerMap = new Map<String, String>();
    if (String.isNotBlank(paramModel.questionAnswerMapJSON)) {
      questionIdAnswerMap = (Map<String, String>) JSON.deserialize(
        paramModel.questionAnswerMapJSON,
        Map<String, String>.class
      );
    }

    List<Document_Template_Query__c> docTempQueryList = DocumentGenerationTemplateDataService.fetchDocTemplateQueries(
      paramModel.templateId
    );
    Integer numQueries = countNumQueries(docTempQueryList);
    Integer batchSize = determineBatchSize(numQueries);

    String jobId = Database.executeBatch(
      new DocumentGenerationBatchJob(
        paramModel.templateId,
        paramModel.deliveryOption,
        paramModel.isTestMode,
        questionIdAnswerMap
      ),
      batchSize
    );
    Document_Generation_Job_Log__c jobLog = new Document_Generation_Job_Log__c();
    jobLog.Async_Apex_Job_Id__c = jobId.substring(0, 15);
    jobLog.Delivery_Option__c = paramModel.deliveryOption;
    jobLog.Document_Template__c = paramModel.templateId;
    if (paramModel.questionAnswerMapJSON != '{}') {
      jobLog.Question_Answer_JSON__c = paramModel.questionAnswerMapJSON;
    }
    insert jobLog;
  }

  private static Integer countNumQueries(List<Document_Template_Query__c> docTempQueryList) {
    Integer numQueries = 0;

    if (docTempQueryList != null && docTempQueryList.isEmpty() == false) {
      // Factor in queries (and subqueries) as part of the count
      for (Document_Template_Query__c query : docTempQueryList) {
        if (String.isNotBlank(query.SOQL_Query__c)) {
          Integer regexFindLimit = 1000;
          Integer regexFindCount = 0;
          Matcher matcher = Pattern.compile('select').matcher(query.SOQL_Query__c.toLowerCase());
          Integer lastEnd = 0;

          while (!matcher.hitEnd()) {
            while (regexFindCount < regexFindLimit && !matcher.hitEnd()) {
              if (matcher.find()) {
                numQueries++;
                lastEnd = matcher.end();
              } else {
                lastEnd = query.SOQL_Query__c.length();
              }
              regexFindCount++;
            }
            matcher.reset(query.SOQL_Query__c);
            matcher.region(lastEnd, matcher.regionEnd());
            regexFindCount = 0;
          }
        }
      }
    }
    return numQueries;
  }

  private static Integer determineBatchSize(Integer numQueries) {
    DocGenSettings__c docGenSettings = DocGenSettings__c.getInstance();
    Integer batchSize = 200; // Default batch size

    if (
      docGenSettings != null &&
      docGenSettings.Max_Batch_Size__c != null &&
      docGenSettings.Max_Batch_Size__c > 0
    ) {
      batchSize = Integer.valueOf(docGenSettings.Max_Batch_Size__c);
    }

    if (numQueries != null && numQueries > 0 && numQueries <= batchSize) {
      batchSize = batchSize / numQueries;
    }
    return batchSize;
  }
}