/**
 * @author - Candoris
 * @date - June 2020
 * @description - Service class for the DocumentTemplateCloningCtrl to perform a clone of the
 * document template record and related document generation records.
 */
public inherited sharing class DocumentTemplateCloningService {
  /**
   * @description - Dynamically retrieve a list of fields for a given sObject
   * @param sObjectApiName - Api name of the salesforce object
   * @return List<String> - List of strings of field api names
   */
  public static List<String> getFields(String sObjectApiName) {
    Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sObjectAPIName);
    SObject newSObject = targetType.newSObject();
    Map<String, Schema.SObjectField> targetFields = targetType.getDescribe().fields.getMap();
    List<String> fields = new List<String>(targetFields.keySet());
    return fields;
  }

  /**
   * @description - Dynamically retrieve fields on the document template object, clone the
   * document template record, and then insert the new copy
   * @param templateId - Original document template record id
   * @return Document_Template__c - New copy of the document template record
   */
  public static Document_Template__c cloneTemplate(Id templateId) {
    // Get the field api names on the document template object and retrieve the data
    List<String> fields = getFields('Document_Template__c');
    String queryString =
      'SELECT ' +
      String.join(fields, ', ') +
      ' FROM Document_Template__c WHERE Id = :templateId';
    List<Document_Template__c> templates = Database.query(queryString);

    // Clone the document template record
    Document_Template__c templateCopy = templates[0].clone(false, true, false, false);
    // Clear out the lookup so that it doesn't reference the original primary query
    templateCopy.Primary_Query__c = null;
    templateCopy.Name += '(1)';
    // Insert and return the new document template record
    insert templateCopy;
    return templateCopy;
  }

  /**
   * @description - Dynamically retrieve fields on the document template query object, clone the
   * original document template query records, and then insert the new copies
   * @param templateId - Original document template record id
   * @param templateCopyId - New copy document template record id
   * @return Map<Id, Document_Template_Query__c> - New copies of the document template query records
   * where the key is the original record's id
   */
  public static Map<Id, Document_Template_Query__c> cloneTemplateQueries(
    Id templateId,
    Id templateCopyId
  ) {
    // Get the field api names on the document template query object and retrieve the data
    List<String> fields = getFields('Document_Template_Query__c');
    String queryString =
      'SELECT ' +
      String.join(fields, ', ') +
      ' FROM Document_Template_Query__c WHERE Document_Template__c = :templateId';
    List<Document_Template_Query__c> templateQueries = Database.query(queryString);

    // Clone the document template query record(s)
    Map<Id, Document_Template_Query__c> templateQueryCopyMap = new Map<Id, Document_Template_Query__c>();
    for (Document_Template_Query__c templateQuery : templateQueries) {
      Document_Template_Query__c templateQueryCopy = templateQuery.clone(false, true, false, false);
      templateQueryCopy.Document_Template__c = templateCopyId;
      templateQueryCopyMap.put(templateQuery.Id, templateQueryCopy);
    }

    // Insert and return the new document template query record(s)
    insert templateQueryCopyMap.values();
    return templateQueryCopyMap;
  }

  /**
   * @description - Dynamically retrieve fields on the document template question object, clone the
   * original document template question records, and then insert the new copies
   * @param templateId - Original document template record id
   * @param templateCopyId - New copy document template record id
   * @param templateQueryCopyMap - New Document Template Query Map where the key is the original record's id
   * @return Map<Id, Document_Template_Question__c> - New copies of the document template question records
   * where the key is the old record's id
   */
  public static Map<Id, Document_Template_Question__c> cloneTemplateQuestions(
    Id templateId,
    Id templateCopyId,
    Map<Id, Document_Template_Query__c> templateQueryCopyMap
  ) {
    // Get the field api names on the document template question object and retrieve the data
    List<String> fields = getFields('Document_Template_Question__c');
    String queryString =
      'SELECT ' +
      String.join(fields, ', ') +
      ' FROM Document_Template_Question__c WHERE Document_Template__c = :templateId';
    List<Document_Template_Question__c> templateQuestions = Database.query(queryString);

    // Clone the document template question record(s)
    Map<Id, Document_Template_Question__c> templateQuestionCopyMap = new Map<Id, Document_Template_Question__c>();
    for (Document_Template_Question__c templateQuestion : templateQuestions) {
      Document_Template_Question__c templateQuestionCopy = templateQuestion.clone(
        false,
        true,
        false,
        false
      );
      templateQuestionCopy.Document_Template__c = templateCopyId;
      if (templateQuestion.Document_Template_Query__c != null) {
        Document_Template_Query__c templateQueryCopy = templateQueryCopyMap.get(
          templateQuestion.Document_Template_Query__c
        );
        templateQuestionCopy.Document_Template_Query__c = templateQueryCopy.Id;
      }
      templateQuestionCopyMap.put(templateQuestion.Id, templateQuestionCopy);
    }

    // Insert and return the new document template question record(s)
    insert templateQuestionCopyMap.values();
    return templateQuestionCopyMap;
  }

  /**
   * @description - Dynamically retrieve fields on the document template question options object, clone the
   * original document post generation records, and then insert the new copies
   * @param templateId - Original document template record id
   * @param templateCopyId - New copy document template record id
   * @param templateQuestionCopyMap - New Document Template Question Map where the key is the original record's id
   * @return List<Document_Template_Question_Option__c> - New copies of the document template question options
   */
  public static List<Document_Template_Question_Option__c> cloneQuestionOptions(
    Id templateId,
    Id templateCopyId,
    Map<Id, Document_Template_Question__c> templateQuestionCopyMap
  ) {
    // Get the field api names on the document template question option object and retrieve the data
    List<String> fields = getFields('Document_Template_Question_Option__c');
    String queryString =
      'SELECT ' +
      String.join(fields, ', ') +
      ' FROM Document_Template_Question_Option__c WHERE Document_Template__c = :templateId';
    List<Document_Template_Question_Option__c> questionOptions = Database.query(queryString);

    // Clone the document template question option record(s)
    List<Document_Template_Question_Option__c> questionOptionCopies = new List<Document_Template_Question_Option__c>();
    for (Document_Template_Question_Option__c questionOption : questionOptions) {
      Document_Template_Question_Option__c questionOptionCopy = questionOption.clone(
        false,
        true,
        false,
        false
      );
      questionOptionCopy.Document_Template__c = templateCopyId;
      Document_Template_Question__c templateQuestionCopy = templateQuestionCopyMap.get(
        questionOption.Document_Template_Question__c
      );
      questionOptionCopy.Document_Template_Question__c = templateQuestionCopy.Id;
      questionOptionCopies.add(questionOptionCopy);
    }

    // Insert and return the new document template question option record(s)
    insert questionOptionCopies;
    return questionOptionCopies;
  }

  /**
   * @description - Dynamically retrieve fields on the document post generation object, clone the
   * original document post generation records, and then insert the new copies
   * @param templateId - Original document template record id
   * @param templateCopyId - New copy document template record id
   * @return List<Document_Post_Generation_Method__c> - New copies of the document post generation records
   */
  public static List<Document_Post_Generation_Method__c> clonePostGenerationMethods(
    Id templateId,
    Id templateCopyId
  ) {
    // Get the field api names on the document post generation method object and retrieve the data
    List<String> fields = getFields('Document_Post_Generation_Method__c');
    String queryString =
      'SELECT ' +
      String.join(fields, ', ') +
      ' FROM Document_Post_Generation_Method__c WHERE Document_Template__c = :templateId';
    List<Document_Post_Generation_Method__c> postGenMethods = Database.query(queryString);

    // Clone the document post generation method record(s)
    List<Document_Post_Generation_Method__c> postGenMethodCopies = new List<Document_Post_Generation_Method__c>();
    for (Document_Post_Generation_Method__c postGenMethod : postGenMethods) {
      Document_Post_Generation_Method__c postGenMethodCopy = postGenMethod.clone(
        false,
        true,
        false,
        false
      );
      postGenMethodCopy.Document_Template__c = templateCopyId;
      postGenMethodCopies.add(postGenMethodCopy);
    }

    // Insert and return the new document post generation method record(s)
    insert postGenMethodCopies;
    return postGenMethodCopies;
  }
}