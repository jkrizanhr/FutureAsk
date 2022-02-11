public class DocumentTemplateColumnConfig {
    @AuraEnabled public Integer index; // Index in it's list
    @AuraEnabled public Integer parentIndex; // Index of parent column if this is a subcolumn
    @AuraEnabled public Integer columnNum; // Column # in the csv export
    @AuraEnabled public Integer numResults;
    @AuraEnabled public Integer selectIndex; // Signifies the select statement
    @AuraEnabled public String altValue;
    @AuraEnabled public String apiName; // This is really just the record's field reference (alias or field api name).
    @AuraEnabled public String field; // What is shown in the query string which would include the aggregate function/alias/etc.
    @AuraEnabled public String formatting;
    @AuraEnabled public String groupingValue; // Applies to subquery results and aggregate results
    @AuraEnabled public String key; // queryId (unless its a primary query) + '_' + apiName
    @AuraEnabled public String label; // What will be shown in the column header
    @AuraEnabled public String parentKey;
    @AuraEnabled public String queryId; // The Document Template Query Id
    @AuraEnabled public String selectSource; // Contacts Subquery, Opportunities Subquery, etc
    @AuraEnabled public List<DocumentTemplateColumnConfig> subColumns;
}