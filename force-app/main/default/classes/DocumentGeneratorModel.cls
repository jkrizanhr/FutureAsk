public class DocumentGeneratorModel {
  public Boolean isTestMode;
  public Boolean isScheduled;
  public Document_Generation_Job_Log__c jobLog;
  public Document_Template__c docTemp;
  public Document_Template_Query__c docTempPrimaryQuery;
  public DocumentFieldLibrary fieldLib;
  public Id docTempId;
  public List<ErrorLog> errorLogs;
  public List<Document_Post_Generation_Method__c> docTempPostMethodList;
  public List<Document_Template_Query__c> docTempAggregateQueryList;
  public List<Document_Template_Query__c> docTempCustomMetadataQueryList;
  public List<Document_Template_Query__c> docTempQueryList;
  public List<Document_Template_Query__c> docTempSecondaryQueryList;
  public List<Document_Template_Question__c> docTempQuestionList;
  public List<Document_Template_Question_Option__c> docTempOptionList;
  public List<PostGenContainer> postGenContainers;
  public Map<Id, List<String>> queryIdAppendMap;
  public Map<Id, String> queryIdReplaceMap;
  public Map<Id, String> queryIdAggregateSOQLStringMap;
  public Map<Id, String> queryIdCustomMetadataSOQLStringMap;
  public Map<Id, String> queryIdSecondarySOQLStringMap;
  public Map<String, String> mergeFieldAnswerMap;
  public Map<String, String> mergeFieldDataTypeMap;
  public Map<String, String> questionIdAnswerMap;
  public PrimaryQueryValidator pqValidator;
  public String deliveryOption;
  public String primarySOQLString;

  public DocumentGeneratorModel(
    String deliveryOption,
    String docTempId,
    Boolean isTestMode,
    Boolean isScheduled
  ) {
    this.deliveryOption = deliveryOption;
    this.docTempId = docTempId;
    this.isTestMode = isTestMode;
    this.isScheduled = isScheduled;
    this.init();
  }

  public DocumentGeneratorModel(Params paramModel) {
    this.deliveryOption = paramModel.deliveryOption;
    this.docTempId = paramModel.templateId;
    this.isTestMode = paramModel.isTestMode;
    this.isScheduled = false;
    this.init();
  }

  private void init() {
    this.docTemp = new Document_Template__c();
    this.docTempQueryList = new List<Document_Template_Query__c>();
    this.docTempQuestionList = new List<Document_Template_Question__c>();
    this.docTempOptionList = new List<Document_Template_Question_Option__c>();
    this.docTempPostMethodList = new List<Document_Post_Generation_Method__c>();
    this.mergeFieldAnswerMap = new Map<String, String>();
    this.mergeFieldDataTypeMap = new Map<String, String>();
    this.questionIdAnswerMap = new Map<String, String>();
    this.queryIdAppendMap = new Map<Id, List<String>>();
    this.queryIdReplaceMap = new Map<Id, String>();
    this.docTempPrimaryQuery = new Document_Template_Query__c();
    this.docTempAggregateQueryList = new List<Document_Template_Query__c>();
    this.docTempCustomMetadataQueryList = new List<Document_Template_Query__c>();
    this.docTempSecondaryQueryList = new List<Document_Template_Query__c>();
    this.postGenContainers = new List<PostGenContainer>();
    this.fieldLib = new DocumentFieldLibrary();
    this.pqValidator = new PrimaryQueryValidator();
    this.errorLogs = new List<ErrorLog>();
    this.queryIdAggregateSOQLStringMap = new Map<Id, String>();
    this.queryIdSecondarySOQLStringMap = new Map<Id, String>();
    this.queryIdCustomMetadataSOQLStringMap = new Map<Id, String>();
  }

  public class PrimaryQueryValidator {
    public String primaryQueryString;
    public String statusMessage;
    public Boolean isValid;
    public Integer count;
    public String selectCountQueryString;
  }

  public class Params {
    public Boolean isTestMode;
    public String deliveryOption;
    public String questionAnswerMapJSON;
    public String recordId;
    public String templateId;
  }

  public class ErrorLog {
    public String className;
    public String methodName;
    public String errMessage;
  }

  public class PostGenContainer {
    public SObject record;
    public Map<String, List<SObject>> postGenInsertMap;
    public Map<String, List<SObject>> postGenUpdateMap;

    public PostGenContainer(SObject record) {
      this.record = record;
      this.postGenInsertMap = new Map<String, List<SObject>>();
      this.postGenUpdateMap = new Map<String, List<SObject>>();
    }
  }

  public class DocumentQueryResult {
    public String primaryQueryCorrelationField;
    public String queryDeveloperName;
    public Map<Id, List<SObject>> secondaryQueryResultMap; // Primary correlation field value => List of sobjects returned from the query
    public Map<Id, List<AggregateResult>> aggregateQueryResultMap; // Primary correlation field value => List of aggregate results returned from the query

    public DocumentQueryResult() {
      this.secondaryQueryResultMap = new Map<Id, List<SObject>>();
      this.aggregateQueryResultMap = new Map<Id, List<AggregateResult>>();
    }
  }

  public class Doc {
    public SObject primaryRecord { get; set; }
    public Map<String, List<AggregateResult>> aggregateQueries { get; set; } // Developer Name of Document Template Query Record : List of Aggregate Results
    public Map<String, List<SObject>> customMetadataQueries { get; set; } // Developer Name of Document Template Query Record : List of Custom Metadata Results
    public Map<String, List<SObject>> secondaryQueries { get; set; } // Developer Name of Document Template Query Record : List of SObject Results
    public Map<String, Integer> aggregateQuerySizes { get; set; }
    public Map<String, Integer> secondaryQuerySizes { get; set; }

    public Doc() {
      this.aggregateQueries = new Map<String, List<AggregateResult>>();
      this.customMetadataQueries = new Map<String, List<SObject>>();
      this.secondaryQueries = new Map<String, List<SObject>>();
      this.aggregateQuerySizes = new Map<String, Integer>();
      this.secondaryQuerySizes = new Map<String, Integer>();
    }
  }
}