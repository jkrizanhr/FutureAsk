/**
 * @author - Candoris
 * @date - June 2020
 * @description - Quick action controller for the Document Template record page
 * to perform a clone of the document template record and related document generation records.
 */
public class DocumentTemplateCloningCtrl {
  /**
   * @description - Clone the document template record and related document generation records
   * @param templateId - Document template record id
   * @return Id - New copy document template record id
   */
  @AuraEnabled
  public static Id clone(Id templateId) {
    // Clone and insert document template
    Document_Template__c templateCopy = DocumentTemplateCloningService.cloneTemplate(templateId);

    // Clone and insert document template queries
    Map<Id, Document_Template_Query__c> templateQueryCopyMap = DocumentTemplateCloningService.cloneTemplateQueries(
      templateId,
      templateCopy.Id
    );

    // NOTE:This may need to be done with a matcher instead depending on the length of the string
    if (String.isNotBlank(templateCopy.CSV_Columns__c)) {
      for (Id templateQueryId : templateQueryCopyMap.keySet()) {
        Document_Template_Query__c templateQueryCopy = templateQueryCopyMap.get(templateQueryId);
        templateCopy.CSV_Columns__c = templateCopy.CSV_Columns__c.replaceAll(
          templateQueryId,
          templateQueryCopy.Id
        );
      }
      update templateCopy;
    }

    // Update the document template's primary query lookup
    Id primaryQueryRecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName()
      .get('Primary SOQL Query')
      .getRecordTypeId();
    for (Document_Template_Query__c templateQueryCopy : templateQueryCopyMap.values()) {
      if (templateQueryCopy.RecordTypeId == primaryQueryRecordTypeId) {
        templateCopy.Primary_Query__c = templateQueryCopy.Id;
        update templateCopy;
        break;
      }
    }

    // Clone and insert document template questions
    Map<Id, Document_Template_Question__c> questionCopyMap = DocumentTemplateCloningService.cloneTemplateQuestions(
      templateId,
      templateCopy.Id,
      templateQueryCopyMap
    );

    // Clone and insert document template question options
    List<Document_Template_Question_Option__c> questionOptionCopies = DocumentTemplateCloningService.cloneQuestionOptions(
      templateId,
      templateCopy.Id,
      questionCopyMap
    );

    // Clone and insert document post generation methods
    List<Document_Post_Generation_Method__c> postGenMethodCopies = DocumentTemplateCloningService.clonePostGenerationMethods(
      templateId,
      templateCopy.Id
    );

    // Return the newly cloned document template record id
    return templateCopy.Id;
  }
}