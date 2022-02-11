global class CAND_BT_Models {
  @AuraEnabled
  public User user;
  @AuraEnabled
  public Map<String, ListView> listViewMap;
  @AuraEnabled
  public ListView topLevelListView;
  @AuraEnabled
  public ListView bottomLevelListView;
  @AuraEnabled
  public DataEntryForm form;

  public class ListView {
    @AuraEnabled
    public List<Column> columns;
    @AuraEnabled
    public List<String> fieldAPINames;
    @AuraEnabled
    public Boolean isTopLevelListView;
    @AuraEnabled
    public Boolean isBottomLevelListView;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String objectAPIName;
    @AuraEnabled
    public Map<String, String> filters;
    @AuraEnabled
    public Integer queryRowLimit;
  }

  public class Column {
    @AuraEnabled
    public String dataType;
    @AuraEnabled
    public String fieldAPIName;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public Boolean isSortable;
    @AuraEnabled
    public String objectAPIName;
    @AuraEnabled
    public Integer order;
    @AuraEnabled
    public String fieldPath;
  }

  public class QueryParams {
    @AuraEnabled
    public List<String> selectFields;
    @AuraEnabled
    public List<String> searchValues;
    @AuraEnabled
    public String fromObject;
    @AuraEnabled
    public String whereClause;
    @AuraEnabled
    public String orderBy;
    @AuraEnabled
    public String lim;
    @AuraEnabled
    public String offSet;
    @AuraEnabled
    public String searchText;
    @AuraEnabled
    public List<String> additionalSoslQueries;
    @AuraEnabled
    public String soslSearchGroup;
  }

  public class DataEntryForm {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String formTitle;
    @AuraEnabled
    public String objectLabel;
    @AuraEnabled
    public String objectAPIName;
    @AuraEnabled
    public List<String> picklistFields;
    @AuraEnabled
    public List<String> requiredFields;
    @AuraEnabled
    public Map<String, FormField> formFieldMap;
    @AuraEnabled
    public String defaultRecordTypeId;
  }

  public class FormField {
    @AuraEnabled
    public String dataType;
    @AuraEnabled
    public String fieldAPIName;
    @AuraEnabled
    public String fieldLabel;
    @AuraEnabled
    public Boolean isLookup;
    @AuraEnabled
    public String lookupWhereClause;
    @AuraEnabled
    public String lookupOrderBy;
    @AuraEnabled
    public String objectAPIName;
    @AuraEnabled
    public List<LookupDialog> lookupDialogs;
    @AuraEnabled
    public Integer maxNumberOfResultsDisplayed;
    @AuraEnabled
    public String additionalSoslQuery;
    @AuraEnabled
    public Boolean useSOSL;
    @AuraEnabled
    public String soslSearchGroup;
  }

  public class LookupDialog {
    @AuraEnabled
    public String formFieldAPIName;
    @AuraEnabled
    public String fieldPath;
    @AuraEnabled
    public Integer lineNumber;
    @AuraEnabled
    public Integer order;
  }

  public class PickList {
    @AuraEnabled
    public Map<String, PicklistField> picklistFieldMap;
  }

  public class PicklistField {
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String type;
    @AuraEnabled
    public List<String> values;

    public PicklistField(String label, String name, String type, List<Schema.PicklistEntry> picklistValues) {
      this.label = label;
      this.name = name;
      this.type = type;
      this.values = new List<String>();
      for (Schema.PicklistEntry ple : picklistValues) {
        this.values.add(ple.getValue());
      }
    }
  }
}