public class DocumentGenerationTemplateDataService {
  public static List<Document_Template__c> fetchDocTemplates(Id documentTemplateId) {
    return [
      SELECT
        Attach_PDF_to_Primary_Record__c,
        CSV_Columns__c,
        Delivery_Options__c,
        Email_Recipient_Field_Path__c,
        Email_Subject__c,
        Email_Template__c,
        Filename__c,
        FROM_Address__c,
        Id,
        Name,
        Primary_Query__c,
        Salesforce_Object__c,
        Scheduled_Delivery_Option__c,
        Scheduled_TO_Address__c,
        Show_Headers__c,
        Test_Mode_TO_Address__c,
        Visualforce_Page__c
      FROM Document_Template__c
      WHERE Is_Active__c = true AND Id = :documentTemplateId
    ];
  }

  public static List<Document_Template_Query__c> fetchDocTemplateQueries(Id documentTemplateId) {
    return [
      SELECT
        Correlating_Query_Field__c,
        Document_Template__c,
        FROM_Object__c,
        GROUP_BY_Statement__c,
        HAVING_Statement__c,
        Id,
        LIMIT__c,
        Name,
        ORDER_BY_Statement__c,
        Primary_Query_Correlation__c,
        Query_Execution_Order__c,
        RecordTypeId,
        RecordType.Name,
        SELECT_Statement__c,
        SOQL_Query__c,
        WHERE_Clause__c
      FROM Document_Template_Query__c
      WHERE Document_Template__c = :documentTemplateId
      ORDER BY Query_Execution_Order__c
    ];
  }

  public static List<Document_Template_Question__c> fetchDocTemplateQuestions(
    Id documentTemplateId
  ) {
    return [
      SELECT
        Apply_Value_to__c,
        Document_Template__c,
        Document_Template_Query__c,
        Id,
        Is_Required__c,
        Name,
        Query_Merge_Field__c,
        Query_Merge_Override__c,
        Question__c,
        Question_Field_Type__c,
        Question_Order__c,
        URL_Parameter__c
      FROM Document_Template_Question__c
      WHERE Document_Template__c = :documentTemplateId
      ORDER BY Question_Order__c
    ];
  }

  public static List<Document_Template_Question_Option__c> fetchDocQuestionOptions(
    Id documentTemplateId
  ) {
    return [
      SELECT
        Default_Option__c,
        Document_Template__c,
        Document_Template_Question__c,
        Id,
        Name,
        Option_Value__c
      FROM Document_Template_Question_Option__c
      WHERE Document_Template__c = :documentTemplateId
      ORDER BY Document_Template_Question__r.Question_Order__c, CreatedDate DESC
    ];
  }

  public static List<Document_Post_Generation_Method__c> fetchDocGenPostMethods(
    Id documentTemplateId
  ) {
    return [
      SELECT
        Data_to_Insert_Update__c,
        Delivery_Options__c,
        Document_Template__c,
        Id,
        Method_Execution_Order__c,
        Name,
        Object__c,
        RecordTypeId
      FROM Document_Post_Generation_Method__c
      WHERE Document_Template__c = :documentTemplateId
      ORDER BY Method_Execution_Order__c
    ];
  }
}