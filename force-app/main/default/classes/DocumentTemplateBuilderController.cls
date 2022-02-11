public class DocumentTemplateBuilderController {
  @AuraEnabled
  public static Map<String, String> fetchSObjects() {
    Map<String, Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();
    Schema.DescribeSObjectResult[] descResultList = Schema.describeSObjects(new String[globalDesc.keySet()]);

    Map<String, String> sObjectMap = new Map<String, String>();
    for (Schema.DescribeSObjectResult res : descResultList) {
      if (res.isAccessible()) {
        sObjectMap.put(res.getName(), res.getLabel());
      }
    }
    return sObjectMap;
  }

  @AuraEnabled
  public static List<ApexPage> fetchVisualForcePages() {
    return [
        SELECT
            Name
        FROM ApexPage
        ORDER BY Name
    ];
  }

  @AuraEnabled
  public static List<Document_Template__c> fetchDocumentTemplates(String docTempId) {
    return [
        SELECT
            CSV_Columns__c,
            Delivery_Options__c,
            Id,
            Name,
            Primary_Query__c,
            Salesforce_Object__c,
            Visualforce_Page__c
        FROM Document_Template__c
        WHERE Id = :docTempId
    ];
  }

  @AuraEnabled
  public static List<Document_Template_Query__c> fetchTemplateQueries(String docTempId) {
    return [
        SELECT
            Id,
            Name,
            RecordType.Name,
            SOQL_Query__c
        FROM Document_Template_Query__c
        WHERE Document_Template__c = :docTempId
    ];
  }

  @AuraEnabled
  public static List<DocumentTemplateColumnConfig> fetchDefaultCSVConfig(String docTempId) {
    DocumentGenerationCSVService csvService = new DocumentGenerationCSVService();
    return csvService.automateCSVHeaderBuild(docTempId);
  }

  @AuraEnabled
  public static Boolean updateDocumentTemplate(String templateJSON) {
    Document_Template__c docTemp = (Document_Template__c) JSON.deserialize(templateJSON, Document_Template__c.class);
    Boolean isSuccess = true;
    DocumentGenerationCSVService csvService = new DocumentGenerationCSVService();
    docTemp.CSV_Columns__c = csvService.completeCSVColumnProperties(docTemp.CSV_Columns__c);

    if (String.isBlank(docTemp.CSV_Columns__c)) {
      isSuccess = false;
      throw new AuraHandledException('Error completing csv columns');
    } else {
      try {
        update docTemp;
      } catch (DmlException e) {
        isSuccess = false;
        throw new AuraHandledException('Error: ' + e.getMessage());
      }
    }

    return isSuccess;
  }
}