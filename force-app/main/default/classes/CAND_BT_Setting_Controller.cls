public class CAND_BT_Setting_Controller {
  private static List<CAND_BT_List_View__mdt> retrieveListViewMetadata() {
    List<CAND_BT_List_View__mdt> metadata = [
      SELECT
        Id,
        Is_Bottom_Level_List_View__c,
        Is_Top_Level_List_View_del__c,
        MasterLabel,
        Object_API_Name__c,
        Query_Row_Limit__c
      FROM CAND_BT_List_View__mdt
      WHERE Is_Active__c = true
    ];
    return metadata;
  }

  private static List<CAND_BT_Column__mdt> retrieveListViewColumnMetadata() {
    List<CAND_BT_Column__mdt> metadata = [
      SELECT
        CAND_BT_List_View__c,
        Column_Label__c,
        Data_Type__c,
        Field_API_Name__c,
        Field_Path__c,
        Is_Sortable__c,
        Object_API_Name__c,
        Order__c
      FROM CAND_BT_Column__mdt
      WHERE Is_Active__c = true
      ORDER BY CAND_BT_List_View__c, Order__c
    ];
    return metadata;
  }

  private static List<CAND_BT_List_View_Filter__mdt> retrieveListViewFilterMetadata() {
    List<CAND_BT_List_View_Filter__mdt> metadata = [
      SELECT CAND_BT_List_View__c, Filter_Label__c, Filter_Where_Clause__c, Order__c
      FROM CAND_BT_List_View_Filter__mdt
      WHERE Is_Active__c = true
      ORDER BY CAND_BT_List_View__c, Order__c DESC
    ];
    return metadata;
  }

  private static List<CAND_BT_Form_Setting__mdt> retrieveFormSettingMetadata() {
    List<CAND_BT_Form_Setting__mdt> metadata = [
      SELECT
        Id,
        Default_Record_Type_Id__c,
        Form_Object_API_Name__c,
        Form_Object_Label__c,
        Form_Picklist_Fields__c,
        Form_Title__c,
        Required_Fields__c
      FROM CAND_BT_Form_Setting__mdt
      WHERE Is_Active__c = true
      LIMIT 1
    ];
    return metadata;
  }

  private static List<CAND_BT_Form_Field__mdt> retrieveFormFieldMetadata(String formMetadataId) {
    /*
          Not all lookup dialog metadata records were returned when using a subquery
          for the lookup dialog metadata from the form field metadata
          which is why it have it's own method and query.
        */

    List<CAND_BT_Form_Field__mdt> metadata = [
      SELECT
        Id,
        CAND_BT_Form_Setting__c,
        Data_Type__c,
        Field_API_Name__c,
        Field_Label__c,
        Is_Lookup__c,
        Lookup_Where_Clause__c,
        Lookup_Order_By__c,
        Max_Number_of_Results_Displayed__c,
        Object_API_Name__c,
        Additional_SOSL_Query__c,
        Use_SOSL__c,
        SOSL_Search_Group__c
      FROM CAND_BT_Form_Field__mdt
      WHERE Is_Active__c = true AND CAND_BT_Form_Setting__c = :formMetadataId
      ORDER BY CAND_BT_Form_Setting__c
    ];
    return metadata;
  }

  private static List<CAND_BT_Lookup_Dialog__mdt> retrieveLookupDialogMetadata(String formMetadataId) {
    List<CAND_BT_Lookup_Dialog__mdt> metadata = [
      SELECT CAND_BT_Form_Field__c, Form_Field_API_Name__c, Field_Path__c, Line_Number__c, Order__c
      FROM CAND_BT_Lookup_Dialog__mdt
      WHERE Is_Active__c = true AND CAND_BT_Form_Field__r.CAND_BT_Form_Setting__c = :formMetadataId
      ORDER BY CAND_BT_Form_Field__c, Line_Number__c, Order__c
    ];
    return metadata;
  }

  private static User retrieveApprovalPerrmission() {
    User currentUser = [SELECT Can_Approve_Batches__c, Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
    return currentUser;
  }

  @AuraEnabled
  public static String getBTSettings() {
    CAND_BT_Models btModels = new CAND_BT_Models();
    btModels.user = retrieveApprovalPerrmission();

    List<CAND_BT_List_View__mdt> lvMdt = retrieveListViewMetadata();
    List<CAND_BT_Column__mdt> colMdt = retrieveListViewColumnMetadata();
    List<CAND_BT_List_View_Filter__mdt> filterMdt = retrieveListViewFilterMetadata();
    CAND_BT_Service.buildListViewModels(btModels, lvMdt, colMdt, filterMdt);

    List<CAND_BT_Form_Setting__mdt> formMdt = retrieveFormSettingMetadata();
    System.debug(formMdt);
    CAND_BT_Service.buildFormModels(btModels, formMdt);

    List<CAND_BT_Form_Field__mdt> formFieldMdt = retrieveFormFieldMetadata(btModels.form.id);
    CAND_BT_Service.buildFormFieldModels(btModels, formFieldMdt);

    List<CAND_BT_Lookup_Dialog__mdt> lookupDialogMdt = retrieveLookupDialogMetadata(btModels.form.id);
    CAND_BT_Service.buildLookupDialogModels(btModels, lookupDialogMdt);

    System.debug(btModels);
    return JSON.serialize(btModels);
  }

  @AuraEnabled
  public static Cash_batch__c getBatchForNavigationFromRecord(String parentRecordId) {
    Cash_Batch__c cb = [
      SELECT
        Id,
        Name,
        Status__c,
        Date__c,
        Control_Batch_Size__c,
        Control_Batch_Total__c,
        Original_Control_Batch_Total__c,
        Original_Currency__c,
        Records_included_in_Batch__c,
        Total_Included_in_Batch__c,
        Opportunity_Type__c,
        Balance__c,
        CreatedDate,
        Type__c
      FROM Cash_Batch__c
      WHERE id = :parentRecordId
      LIMIT 1
    ];
    return cb;
  }
}