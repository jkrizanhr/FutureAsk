public class CAND_BT_Service {
  private static Map<String, List<CAND_BT_Models.Column>> buildListViewColumnModelMap(
    List<CAND_BT_Column__mdt> mdtList
  ) {
    Map<String, List<CAND_BT_Models.Column>> columnModelMap = new Map<String, List<CAND_BT_Models.Column>>();
    for (CAND_BT_Column__mdt colMdt : mdtList) {
      CAND_BT_Models.Column column = new CAND_BT_Models.Column();
      column.dataType = colMdt.Data_Type__c;
      column.fieldAPIName = colMdt.Field_API_Name__c;
      column.label = colMdt.Column_Label__c;
      column.isSortable = colMdt.Is_Sortable__c;
      column.order = (Integer) colMdt.Order__c;
      column.objectAPIName = colMdt.Object_API_Name__c;
      column.fieldPath = colMdt.Field_Path__c;
      if (!columnModelMap.containsKey(colMdt.CAND_BT_List_View__c)) {
        columnModelMap.put(colMdt.CAND_BT_List_View__c, new List<CAND_BT_Models.Column>());
      }
      columnModelMap.get(colMdt.CAND_BT_List_View__c).add(column);
    }
    return columnModelMap;
  }

  private static Map<String, Map<String, String>> buildListViewFilterMap(List<CAND_BT_List_View_Filter__mdt> mdtList) {
    Map<String, Map<String, String>> lvFilterMap = new Map<String, Map<String, String>>();
    for (CAND_BT_List_View_Filter__mdt mdt : mdtList) {
      if (!lvFilterMap.containsKey(mdt.CAND_BT_List_View__c)) {
        lvFilterMap.put(mdt.CAND_BT_List_View__c, new Map<String, String>());
      }
      lvFilterMap.get(mdt.CAND_BT_List_View__c).put(mdt.Filter_Label__c, mdt.Filter_Where_Clause__c);
    }
    return lvFilterMap;
  }

  public static void buildListViewModels(
    CAND_BT_Models btModels,
    List<CAND_BT_List_View__mdt> mdtList,
    List<CAND_BT_Column__mdt> colMdt,
    List<CAND_BT_List_View_Filter__mdt> filterMdt
  ) {
    Map<String, List<CAND_BT_Models.Column>> columnModelMap = buildListViewColumnModelMap(colMdt);
    Map<String, Map<String, String>> filterMap = buildListViewFilterMap(filterMdt);
    btModels.listViewMap = new Map<String, CAND_BT_Models.ListView>();

    for (CAND_BT_List_View__mdt lvMdt : mdtList) {
      CAND_BT_Models.ListView listView = new CAND_BT_Models.ListView();
      listView.label = lvMdt.MasterLabel;
      listView.isTopLevelListView = lvMdt.Is_Top_Level_List_View_del__c;
      listView.isBottomLevelListView = lvMdt.Is_Bottom_Level_List_View__c;
      listView.objectAPIName = lvMdt.Object_API_Name__c;
      listView.queryRowLimit = (Integer) lvMdt.Query_Row_Limit__c;
      listView.columns = new List<CAND_BT_Models.Column>();
      listView.fieldAPINames = new List<String>();
      listView.filters = new Map<String, String>();

      if (columnModelMap.containsKey(lvMdt.Id)) {
        List<CAND_BT_Models.Column> colList = columnModelMap.get(lvMdt.Id);
        for (CAND_BT_Models.Column col : colList) {
          listView.columns.add(col);
          listView.fieldAPINames.add(col.fieldPath);
        }
      }

      if (filterMap.containsKey(lvMdt.Id)) {
        Map<String, String> filters = filterMap.get(lvMdt.Id);
        listView.filters.putAll(filters);
      }

      btModels.listViewMap.put(listView.objectAPIName, listView);

      if (listView.isTopLevelListView) {
        btModels.topLevelListView = listView;
      }
      if (listView.isBottomLevelListView) {
        btModels.bottomLevelListView = listView;
      }
    }
  }

  public static void buildFormModels(CAND_BT_Models btModels, List<CAND_BT_Form_Setting__mdt> formMdtList) {
    btModels.form = new CAND_BT_Models.DataEntryForm();
    btModels.form.requiredFields = new List<String>();

    if (formMdtList.isEmpty() == false) {
      btModels.form.id = formMdtList[0].Id;
      btModels.form.objectLabel = formMdtList[0].Form_Object_Label__c;
      System.debug(formMdtList[0]);
      btModels.form.objectAPIName = formMdtList[0].Form_Object_API_Name__c;
      if (String.isNotBlank(formMdtList[0].Form_Picklist_Fields__c)) {
        btModels.form.picklistFields = formMdtList[0].Form_Picklist_Fields__c.split(';');
      }
      if (String.isNotBlank(formMdtList[0].Required_Fields__c)) {
        List<String> reqFields = formMdtList[0].Required_Fields__c.split(';');
        for (String r : reqFields) {
          btModels.form.requiredFields.add(r.trim());
        }
      }
      btModels.form.defaultRecordTypeId = formMdtList[0].Default_Record_Type_Id__c;
      btModels.form.formTitle = formMdtList[0].Form_Title__c;
    }
  }

  public static void buildFormFieldModels(CAND_BT_Models btModels, List<CAND_BT_Form_Field__mdt> formFieldMdtList) {
    btModels.form.formFieldMap = new Map<String, CAND_BT_Models.FormField>();
    for (CAND_BT_Form_Field__mdt formFieldMdt : formFieldMdtList) {
      CAND_BT_Models.FormField formField = new CAND_BT_Models.FormField();
      formField.dataType = formFieldMdt.Data_Type__c;
      formField.fieldAPIName = formFieldMdt.Field_API_Name__c;
      formField.fieldLabel = formFieldMdt.Field_Label__c;
      formField.isLookup = formFieldMdt.Is_Lookup__c;
      formField.lookupWhereClause = formFieldMdt.Lookup_Where_Clause__c;
      formField.lookupOrderBy = formFieldMdt.Lookup_Order_By__c;
      formField.objectAPIName = formFieldMdt.Object_API_Name__c;
      formField.maxNumberOfResultsDisplayed = (Integer) formFieldMdt.Max_Number_of_Results_Displayed__c;
      formField.useSOSL = formFieldMdt.Use_SOSL__c;
      formField.soslSearchGroup = formFieldMdt.SOSL_Search_Group__c;
      formfield.additionalSoslQuery = formFieldMdt.Additional_SOSL_Query__c;
      formField.lookupDialogs = new List<CAND_BT_Models.LookupDialog>();
      btModels.form.formFieldMap.put(formField.fieldAPIName, formField);
    }
  }

  public static void buildLookupDialogModels(CAND_BT_Models btModels, List<CAND_BT_Lookup_Dialog__mdt> lookupMdtList) {
    for (CAND_BT_Lookup_Dialog__mdt lookupMdt : lookupMdtList) {
      CAND_BT_Models.LookupDialog dialog = new CAND_BT_Models.LookupDialog();
      dialog.formFieldAPIName = lookupMdt.Form_Field_API_Name__c;
      dialog.fieldPath = lookupMdt.Field_Path__c;
      dialog.lineNumber = (Integer) lookupMdt.Line_Number__c;
      dialog.order = (Integer) lookupMdt.Order__c;
      if (btModels.form.formFieldMap.containsKey(dialog.formFieldAPIName)) {
        CAND_BT_Models.FormField formField = btModels.form.formFieldMap.get(dialog.formFieldAPIName);
        formField.lookupDialogs.add(dialog);
      }
    }
  }

  public static String buildDynamicSOSLString(String queryParamsJSON) {
    CAND_BT_Models.QueryParams params = (CAND_BT_Models.QueryParams) JSON.deserialize(
      queryParamsJSON,
      CAND_BT_Models.QueryParams.class
    );
    String queryString = 'FIND \'';

    List<String> searchWildcardValues = new List<String>();
    for (String searchVal : params.searchValues) {
      searchWildcardValues.add(searchVal + '*');
    }
    queryString += String.join(searchWildcardValues, ' AND ') + '\'';
    if (String.isBlank(params.soslSearchGroup)) {
      params.soslSearchGroup = 'ALL FIELDS';
    }
    queryString += (' IN ' + params.soslSearchGroup + ' RETURNING ');
    queryString += params.fromObject;
    if (params.selectFields == null || params.selectFields.isEmpty()) {
      params.selectFields = new List<String>{'Id'};
    }
    queryString += ' (' + String.join(params.selectFields, ', ');
    if (String.isNotBlank(params.whereClause)) {
      if (!params.whereClause.startsWithIgnoreCase('WHERE')) {
        queryString += ' WHERE ';
      }
      queryString += (' ' + params.whereClause);
    }
    if (String.isNotBlank(params.orderBy)) {
      if (!params.orderBy.startsWithIgnoreCase('ORDER BY')) {
        queryString += ' ORDER BY ';
      }
      queryString += params.orderBy;
    }
    if (String.isNotBlank(params.lim)) {
      queryString += ' LIMIT ' + params.lim;
    }
    if (String.isNotEmpty(params.offSet)) {
      queryString += ' OFFSET ' + params.offSet;
    }
    queryString += ')';
    if (params.additionalSoslQueries != null && !params.additionalSoslQueries.isEmpty()){
      for (String adtlQuery : params.additionalSoslQueries){
        queryString += ', ' + adtlQuery;
      }
    }
    return queryString;
  }


  public static String buildDynamicQueryString(String queryParamsJSON) {
    CAND_BT_Models.QueryParams params = (CAND_BT_Models.QueryParams) JSON.deserialize(
      queryParamsJSON,
      CAND_BT_Models.QueryParams.class
    );
    System.debug(params);

    String queryString = '';

    // Build the SELECT Statement
    if (params.selectFields == null || params.selectFields.isEmpty()) {
      params.selectFields = new List<String>{'Id'};
    }

    String selectFields = String.join(params.selectFields, ', ');

    if (!selectFields.startsWithIgnoreCase('SELECT')) {
      queryString += 'SELECT ';
    }
    queryString += selectFields;

    // FROM Object
    queryString += ' FROM ' + params.fromObject;

    // Build the WHERE Clause
    if (String.isNotBlank(params.whereClause)) {
      if (!params.whereClause.startsWithIgnoreCase('WHERE')) {
        queryString += ' WHERE ';
      }
      queryString += params.whereClause;
    }

    // ORDER BY
    if (String.isNotBlank(params.orderBy)) {
      if (!params.orderBy.startsWithIgnoreCase('ORDER BY')) {
        queryString += ' ORDER BY ';
      }
      queryString += params.orderBy;
    }

    // LIMIT
    if (String.isNotEmpty(params.lim)) {
      queryString += ' LIMIT ' + params.lim;
    }

    // OFFSET
    if (String.isNotEmpty(params.offSet)) {
      queryString += ' OFFSET ' + params.offSet;
    }

    System.debug(queryString);
    return queryString;
  }
}