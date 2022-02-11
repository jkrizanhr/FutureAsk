public class DocumentGenerationCSVService {
  public List<DocumentTemplateColumnConfig> columnConfigList;

  public DocumentGenerationCSVService() {
    this.columnConfigList = new List<DocumentTemplateColumnConfig>();
  }

  @TestVisible
  private List<Document_Template_Query__c> fetchDocumentTemplateQueries(String docTempId) {
    return [
        SELECT
            FROM_Object__c,
            GROUP_BY_Statement__c,
            Id,
            Name,
            RecordType.Name,
            SELECT_Statement__c
        FROM Document_Template_Query__c
        WHERE Document_Template__c = :docTempId
        ORDER BY Query_Execution_Order__c
    ];
  }

  public List<DocumentTemplateColumnConfig> automateCSVHeaderBuild(String docTempId) {
    List<Document_Template_Query__c> templateQueryList = fetchDocumentTemplateQueries(docTempId);
    Integer num = 0;
    for (Document_Template_Query__c templateQuery : templateQueryList) {
      num = generateCSVHeaders(templateQuery, num);
    }
    setConfigIndex();
    return this.columnConfigList;
  }

  public void setConfigIndex() {
    Integer index = 0;
    for (DocumentTemplateColumnConfig colConfig : this.columnConfigList) {
      colConfig.index = index;
      index++;
      if (colConfig.subColumns != null) {
        Integer subIndex = 0;
        for (DocumentTemplateColumnConfig subColConfig : colConfig.subColumns) {
          subColConfig.index = subIndex;
          subColConfig.parentIndex = colConfig.index;
          subIndex++;
        }
      }
    }
  }

  private Integer generateCSVHeaders(Document_Template_Query__c templateQuery, Integer num) {
    String queryString = templateQuery.SELECT_Statement__c + ' FROM ' + templateQuery.FROM_Object__c;
    if (String.isNotBlank(templateQuery.GROUP_BY_Statement__c)) {
      queryString += ' ' + templateQuery.GROUP_BY_Statement__c;
    }
    DocumentQueryFieldParser parser = new DocumentQueryFieldParser(queryString);
    parser.parseQueryString();

    List<DocumentQueryFieldParser.DocumentQueryField> dqFieldList = parser.getDocumentQueryFields();
    Map<Integer, DocumentTemplateColumnConfig> subColMap = new Map<Integer, DocumentTemplateColumnConfig>();

    for (DocumentQueryFieldParser.DocumentQueryField queryField : dqFieldList) {
      if (templateQuery.RecordType.Name == 'Secondary SOQL Query') {
        queryField.source = 'Secondary';
      } else if (templateQuery.RecordType.Name == 'Custom Metadata SOQL Query') {
        queryField.source = 'Custom Metadata';
      }

      DocumentTemplateColumnConfig col = new DocumentTemplateColumnConfig();
      col.columnNum = num;
      col.queryId = templateQuery.Id;
      col.parentIndex = null;
      col.parentKey = null;
      col.numResults = null;

      if (queryField.source == 'Subquery'
          || queryField.source == 'Aggregate'
          || queryField.source == 'Secondary') {
        col.key = templateQuery.Id + '_' + queryField.fromObject;
        col.selectSource = queryField.fromObject + ' ' + queryField.source;
        col.selectIndex = queryField.selectNum;
        col.numResults = 1;
        col.field = col.selectSource;
        col.apiName = queryField.source;

        DocumentTemplateColumnConfig subCol = new DocumentTemplateColumnConfig();
        subCol.columnNum = num;
        subCol.queryId = templateQuery.Id;
        subCol.parentKey = col.key;
        if (subColMap.containsKey(queryField.selectNum) == false) {
          subColMap.put(queryField.selectNum, col);
          col.subColumns = new List<DocumentTemplateColumnConfig>{
              subCol
          };
          this.columnConfigList.add(col);
        } else {
          // Add to the existing subcolumn list
          subColMap.get(queryField.selectNum).subColumns.add(subCol);
        }
        num++;
        assignColumnAttributes(subCol, queryField);
      } else {
        num++;
        assignColumnAttributes(col, queryField);
        this.columnConfigList.add(col);
      }
    }
    return num;
  }

  public void assignColumnAttributes(DocumentTemplateColumnConfig col, DocumentQueryFieldParser.DocumentQueryField queryField) {
    col.field = queryField.selectField;
    col.selectIndex = queryField.selectNum;
    col.groupingValue = '';
    col.altValue = '';
    col.subColumns = new List<DocumentTemplateColumnConfig>();

    if (queryField.source == 'Subquery' || queryField.source == 'Secondary') {
      col.selectSource = queryField.fromObject + ' ' + queryField.source;
      col.groupingValue = '0';
    } else if (queryField.source == 'Aggregate' || queryField.source == 'Custom Metadata') {
      col.selectSource = queryField.source;
    } else {
      col.selectSource = 'Primary';
    }

    if (queryField.source == 'Subquery' || queryField.source == 'Secondary') {
      if (queryField.apiName.contains('.')) {
        String s1 = queryField.apiName.substringBefore('.');
        String s2 = queryField.apiName.substringAfter('.');
        queryField.apiName = s1 + '[0].' + s2;
      }
      if (queryField.sfFieldLabel != null && queryField.sfFieldLabel.contains('.')) {
        String s1 = queryField.sfFieldLabel.substringBefore('.');
        String s2 = queryField.sfFieldLabel.substringAfter('.');
        queryField.sfFieldLabel = s1 + '[0] ' + s2;
      }
      col.groupingValue = '0';
    }

    col.apiName = String.isNotBlank(queryField.alias) ? queryField.alias : queryField.apiName;
    col.label = String.isNotBlank(queryField.alias) ? queryField.alias : queryField.sfFieldLabel;
    col.key = col.queryId + '_' + col.apiName;
    col.formatting = queryField.dataType;
    if (col.formatting == 'currency') {
      col.altValue = '$0.00';
    }
  }

  public String completeCSVColumnProperties(String csvColumnJSON) {
    String newCSVColumnJSON = '';
    List<DocumentTemplateColumnConfig> columnList = getColumnHeaderList(csvColumnJSON);
    if (columnList.isEmpty()) {
      return newCSVColumnJSON;
    }

    for (DocumentTemplateColumnConfig col : columnList) {
      String field = col.field;
      if (String.isNotBlank(field) && field.contains(' ')) {
        List<String> fieldParts = field.split(' ');
        field = fieldParts[fieldParts.size() - 1];
      }
      if (String.isBlank(col.key)) {
        String k = col.queryId + '_' + field;
        col.key = k.toLowerCase();
      }
      col.apiName = field;
    }

    try {
      newCSVColumnJSON = JSON.serialize(columnList);
    } catch (JSONException e) {
      newCSVColumnJSON = '';
      System.debug('DocumentGenerationCSVService Error: ' + e.getMessage());
    }
    return newCSVColumnJSON;
  }

  private List<DocumentTemplateColumnConfig> getColumnHeaderList(String csvColumnJSON) {
    List<DocumentTemplateColumnConfig> columns = new List<DocumentTemplateColumnConfig>();
    if (String.isNotBlank(csvColumnJSON) && csvColumnJSON.indexOf('[') == 0 && csvColumnJSON.length() > 2) {
      try {
        columns = (List<DocumentTemplateColumnConfig>) JSON.deserialize(csvColumnJSON, List<DocumentTemplateColumnConfig>.class);
      } catch (Exception e) {
        System.debug('Error: ' + e.getMessage());
      }
    }
    System.debug('columnConfigList = ' + columns);
    return columns;
  }

  public String generateHeaderRow(String csvColumnJSON) {
    String headerRow = '';
    List<String> cols = new List<String>();
    List<DocumentTemplateColumnConfig> columnConfigList = getColumnHeaderList(csvColumnJSON);
    for (DocumentTemplateColumnConfig col : columnConfigList) {
      if (col.subColumns == null || col.subColumns.isEmpty()) {
        cols.add('"' + col.label + '"');
      } else {
        for (DocumentTemplateColumnConfig subCol : col.subColumns) {
          cols.add('"' + subCol.label + '"');
        }
      }
    }
    headerRow = String.join(cols, ',');
    return headerRow;
  }

  public Map<Integer, String> generateColumnMap(String csvColumnJSON) {
    Map<Integer, String> csvColumnMap = new Map<Integer, String>();
    List<DocumentTemplateColumnConfig> columnConfigList = getColumnHeaderList(csvColumnJSON);
    for (DocumentTemplateColumnConfig col : columnConfigList) {
      if (col.subColumns == null || col.subColumns.isEmpty()) {
        if (col.altValue != null) {
          csvColumnMap.put(col.columnNum, '"' + col.altValue + '"');
        } else {
          csvColumnMap.put(col.columnNum, '""');
        }
      } else {
        for (DocumentTemplateColumnConfig subCol : col.subColumns) {
          if (subCol.altValue != null) {
            csvColumnMap.put(subCol.columnNum, '"' + subCol.altValue + '"');
          } else {
            csvColumnMap.put(subCol.columnNum, '""');
          }
        }
      }
    }
    return csvColumnMap;
  }

  // Key => Map (GroupingValue => DocumentTemplateColumnConfig)
  public Map<String, Map<String, DocumentTemplateColumnConfig>> generateColumnKeyGroupingMap(String csvColumnJSON) {
    Map<String, Map<String, DocumentTemplateColumnConfig>> columnKeyGroupingMap
        = new Map<String, Map<String, DocumentTemplateColumnConfig>>();
    List<DocumentTemplateColumnConfig> columnConfigList = getColumnHeaderList(csvColumnJSON);
    for (DocumentTemplateColumnConfig col : columnConfigList) {
      if (col.subColumns == null || col.subColumns.isEmpty()) {
        addColumnToMap(columnKeyGroupingMap, col);
      } else {
        for (DocumentTemplateColumnConfig subCol : col.subColumns) {
          addColumnToMap(columnKeyGroupingMap, subCol);
        }
      }
    }
    return columnKeyGroupingMap;
  }

  private void addColumnToMap(
      Map<String, Map<String, DocumentTemplateColumnConfig>> columnKeyGroupingMap,
      DocumentTemplateColumnConfig column) {
    if (columnKeyGroupingMap.containsKey(column.key.toLowerCase()) == false) {
      Map<String, DocumentTemplateColumnConfig> groupingMap = new Map<String, DocumentTemplateColumnConfig>();
      columnKeyGroupingMap.put(column.key.toLowerCase(), groupingMap);
    }
    Map<String, DocumentTemplateColumnConfig> groupingMap = columnKeyGroupingMap.get(column.key.toLowerCase());
    if (String.isBlank(column.groupingValue)) {
      column.groupingValue = column.key.toLowerCase();
    }
    groupingMap.put(column.groupingValue.toLowerCase(), column);
    columnKeyGroupingMap.put(column.key.toLowerCase(), groupingMap);
  }
}