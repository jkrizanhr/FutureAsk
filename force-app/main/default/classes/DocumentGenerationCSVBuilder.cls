public class DocumentGenerationCSVBuilder {
  private DocumentGeneratorModel docGenModel;
  private List<DocumentGeneratorModel.Doc> documents;
  private Map<Integer, String> csvIndexMap;
  private List<String> rows;
  private Map<String, Map<String, DocumentTemplateColumnConfig>> columnKeyGroupingMap;
  private Map<String, Id> queryDevNameIdMap;

  public DocumentGenerationCSVBuilder(
      DocumentGeneratorModel docGenModel,
      List<DocumentGeneratorModel.Doc> documents) {
    this.docGenModel = docGenModel;
    this.documents = documents;
    this.csvIndexMap = new Map<Integer, String>();
    this.queryDevNameIdMap = new Map<String, Id>();
    this.rows = new List<String>();
    this.columnKeyGroupingMap = new Map<String, Map<String, DocumentTemplateColumnConfig>>();
  }

  public List<String> buildCSVRows() {
    if (documents.isEmpty()) {
      return this.rows;
    }

    this.getCSVColumnMaps();
    if (this.csvIndexMap.isEmpty()) {
      return this.rows;
    }

    String objectAPIName = documents[0].primaryRecord.getSObjectType().getDescribe().getName();

    // Build map of document template query name to id
    for (Document_Template_Query__c templateQuery : this.docGenModel.docTempQueryList) {
      String developerName = templateQuery.Name.replaceAll(' ', '_');
      this.queryDevNameIdMap.put(developerName, templateQuery.Id);
    }

    // Iterate the records returned from the query
    for (DocumentGeneratorModel.Doc doc : this.documents) {
      Map<Integer, String> currentRowIndexMap = new Map<Integer, String>();
      // Add the default value into the new map so that the previous row's values are not referenced.
      for (Integer i : this.csvIndexMap.keySet()) {
        currentRowIndexMap.put(i, this.csvIndexMap.get(i));
      }
      // Build out the row from the primary query results
      Map<Integer, String> rowIndexResultMap = iterateFields(
          objectAPIName,
          this.docGenModel.docTempPrimaryQuery.Id,
          doc.primaryRecord.getPopulatedFieldsAsMap(),
          '',
          currentRowIndexMap
      );

      this.addSecondaryQueryResultsToRow(rowIndexResultMap, doc);
      this.addAggregateResultsToRow(rowIndexResultMap, doc);
      this.addCustomMetadataQueryResultsToRow(rowIndexResultMap, doc);
      this.rows.add(String.join(rowIndexResultMap.values(), ','));
    }

    return this.rows;
  }

  private void getCSVColumnMaps() {
    DocumentGenerationCSVService csvService = new DocumentGenerationCSVService();
    Map<Integer, String> csvColMap = csvService.generateColumnMap(this.docGenModel.docTemp.CSV_Columns__c);
    this.csvIndexMap.putAll(csvColMap);
    this.columnKeyGroupingMap = csvService.generateColumnKeyGroupingMap(this.docGenModel.docTemp.CSV_Columns__c);
  }

  // NOTE: In the future, we should support relationship queries for secondary queries? use iterateFields method
  private void addSecondaryQueryResultsToRow(Map<Integer, String> rowIndexResultMap, DocumentGeneratorModel.Doc doc) {
    for (String queryDevName : doc.secondaryQueries.keySet()) {
      Id queryId = this.queryDevNameIdMap.get(queryDevName);
      if (queryId == null) {
        System.debug('DocumentGenerationCSVBuilder.addSecondaryQueryResultsToRow: ERROR: query developer name not found in map!');
        continue;
      }

      String queryIdStr = String.valueOf(queryId).toLowerCase();
      List<SObject> secondaryQueryResults = doc.secondaryQueries.get(queryDevName);

      // Iterate over the secondary query result records
      Integer groupingIntegerValue = 0;
      for (SObject record : secondaryQueryResults) {
        // Get a map of the properties to the object values for the secondary query result record
        Map<String, Object> recordPropertiesMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(record));
        // Loop through the properties of the record
        for (String prop : recordPropertiesMap.keySet()) {
          String val = String.valueOf(recordPropertiesMap.get(prop));
          // Get the index of the property using the getColumnIndex method
          DocumentTemplateColumnConfig docCol = getColumnIndex(queryIdStr, prop.toLowerCase(), val, String.valueOf(groupingIntegerValue));

          // Add to the rowIndexResultMap
          if (docCol != null && docCol.columnNum != null) {
            if (String.isNotBlank(docCol.formatting)) {
              val = DocGenFieldService.doSpecificFormat(val, docCol.formatting);
            }
            if (val == null) {
              val = '';
            }
            rowIndexResultMap.put(docCol.columnNum, '"' + val.unescapeCsv() + '"');
          }
        }
        groupingIntegerValue++;
      }
    }
  }

  private void addAggregateResultsToRow(Map<Integer, String> rowIndexResultMap, DocumentGeneratorModel.Doc doc) {
    for (String queryDevName : doc.aggregateQueries.keySet()) {
      Id queryId = this.queryDevNameIdMap.get(queryDevName);
      if (queryId == null) {
        System.debug('DocumentGenerationCSVBuilder.addAggregateQueryResultsToRow: ERROR: query developer name not found in map!');
        continue;
      }

      String queryIdStr = String.valueOf(queryId).toLowerCase();
      List<AggregateResult> aggregateQueryResults = doc.aggregateQueries.get(queryDevName);

      // Iterate over the secondary query result records
      for (AggregateResult result : aggregateQueryResults) {
        // Get a map of the properties to the object values for the secondary query result record
        Map<String, Object> resultPropertiesMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(result));
        // Loop through the properties of the record
        String groupingVal;
        List<String> potentialGroupingValues = new List<String>();

        for (String prop : resultPropertiesMap.keySet()) {
          String val = String.valueOf(resultPropertiesMap.get(prop));
          potentialGroupingValues.add(val);
          // Get the index of the property using the getColumnIndex method
          DocumentTemplateColumnConfig docCol = getColumnIndex(queryIdStr, prop.toLowerCase(), val, groupingVal);
          if (docCol != null && String.isNotBlank(docCol.groupingValue)) {
            groupingVal = docCol.groupingValue;
          }
        }

        /* In the event that the aggregate result's property containing the value that
        matches the groupingValue key is NOT one of the document column headers, then we need
        to work around that to still use the value to assist in matching the other aggregate result
        properties to their appropriate columns.

        For example, if we have an aggregate result for SUM(Amount) but we don't want to use
        the field that is grouped by such as CALENDAR_MONTH(CloseDate), then we still need to use
        the value of CALENDAR_MONTH(CloseDate) to matching SUM(Amount) to the correct column.
         */
        if (String.isBlank(groupingVal)) {
          for (String prop : resultPropertiesMap.keySet()) {
            // Conditions are met. Aggregate Result belongs to the record (row)
            // Get the index of the property using the getColumnIndex method
            String val = String.valueOf(resultPropertiesMap.get(prop));
            for (String v : potentialGroupingValues) {
              DocumentTemplateColumnConfig docCol = getColumnIndex(queryIdStr, prop.toLowerCase(), val, v);
              if (docCol != null && String.isNotBlank(docCol.groupingValue)) {
                groupingVal = docCol.groupingValue;
                break;
              }
            }
            if (String.isNotBlank(groupingVal)) {
              break;
            }
          }
        }

        // Use the grouping value to help determine the index
        for (String prop : resultPropertiesMap.keySet()) {
          // Conditions are met. Aggregate Result belongs to the record (row)
          // Get the index of the property using the getColumnIndex method
          String val = String.valueOf(resultPropertiesMap.get(prop));
          DocumentTemplateColumnConfig docCol = getColumnIndex(queryIdStr, prop.toLowerCase(), val, groupingVal);
          if (docCol != null && String.isNotBlank(docCol.groupingValue)) {
            groupingVal = docCol.groupingValue;
          }
          // Add to the rowIndexResultMap
          if (docCol != null && docCol.columnNum != null) {
            if (String.isNotBlank(docCol.formatting) && val != null) {
              val = DocGenFieldService.doSpecificFormat(resultPropertiesMap.get(prop), docCol.formatting);
            }
            if (val == null) {
              val = '';
            }
            rowIndexResultMap.put(docCol.columnNum, '"' + val.unescapeCsv() + '"');
          }
        }
      }
    }
  }

  private void addCustomMetadataQueryResultsToRow(Map<Integer, String> rowIndexResultMap, DocumentGeneratorModel.Doc doc) {
    Map<Integer, String> currentRowIndexMap = new Map<Integer, String>();
    // Add the default value into the new map so that the previous row's values are not referenced.
    for (Integer i : this.csvIndexMap.keySet()) {
      currentRowIndexMap.put(i, this.csvIndexMap.get(i));
    }

    for (String queryDevName : doc.customMetadataQueries.keySet()) {
      Id queryId = this.queryDevNameIdMap.get(queryDevName);
      if (queryId == null) {
        System.debug('DocumentGenerationCSVBuilder.addCustomMetadataQueryResultsToRow: ERROR: query developer name not found in map!');
        continue;
      }

      List<SObject> customMetadataQueryResults = doc.customMetadataQueries.get(queryDevName);
      if (customMetadataQueryResults.isEmpty() == false) {
        String objectAPIName = customMetadataQueryResults[0].getSObjectType().getDescribe().getName();
        for (SObject record : customMetadataQueryResults) {
          this.iterateFields(objectAPIName, queryId, record.getPopulatedFieldsAsMap(), '', rowIndexResultMap);
        }
      }
    }
  }

  private DocumentTemplateColumnConfig getColumnIndex(String queryId, String fieldReference, String value, String groupingVal) {
    String key = queryId + '_' + fieldReference;
    key = key.toLowerCase();

    Map<String, DocumentTemplateColumnConfig> groupingValColMap = this.columnKeyGroupingMap.get(key);

    if (groupingValColMap == null) {
      // Key not found in the map signifies that we don't have a column for it
      // which is likely because it is an Id for a relationship field.
      return null;
    }

    DocumentTemplateColumnConfig config = groupingValColMap.get(key);

    if (config != null) {
      // Is not an aggregate result or subquery and therefore there is only one column with the key
      return config;
    } else if (groupingVal != null) {
      config = groupingValColMap.get(groupingVal);
      if (config != null) {
        return config;
      }
    }

    return groupingValColMap.get(value);
  }

  private Map<Integer, String> iterateFields(String objectAPIName, String queryId, Map<String, Object> fieldsToValueMap, String path, Map<Integer, String> csvRowMap) {
    for (String fieldName : fieldsToValueMap.keySet()) {
      if (fieldsToValueMap.get(fieldName) instanceof List<SObject>) {
        // ------Begin Child------
        this.iterateChildRecord((List<SObject>) fieldsToValueMap.get(fieldName), queryId, path + fieldName, csvRowMap);
        // ------End Child------
      } else if (fieldsToValueMap.get(fieldName) instanceof SObject) {
        // ------Begin Parent------
        SObject obj = (SObject) fieldsToValueMap.get(fieldName);
        String parentObjectAPIName = obj.getSObjectType().getDescribe().getName();
        this.iterateFields(parentObjectAPIName, queryId, obj.getPopulatedFieldsAsMap(), path + fieldName + '.', csvRowMap);
        // ------End Parent------
      } else {
        Object val = fieldsToValueMap.get(fieldName);
//        String stringVal = DocGenFieldService.formatFieldValue(val, objectAPIName, fieldName);
        String stringVal = val != null ? String.valueOf(val) : '';
        if (fieldName == 'BillingStreet' && String.isNotBlank(stringVal)) {
          stringVal = stringVal.replaceAll('\r\n', ',').replaceAll('\r', ',').replaceAll('\n', '');
        }

        // Add to the csvRowMap
        String endPath = path + fieldName;

        String groupingVal;
        if (endPath != null && endPath.contains('[') && endPath.contains(']')) {
          groupingVal = endPath.substringBetween('[', ']');
        }

        DocumentTemplateColumnConfig docCol = getColumnIndex(queryId, endPath, stringVal, groupingVal);

        if (docCol != null && docCol.columnNum != null) {
          if (String.isNotBlank(docCol.formatting) && val != null) {
            // Use the docCol config to format the field value
            stringVal = DocGenFieldService.doSpecificFormat(val, docCol.formatting);
          }
          csvRowMap.put(docCol.columnNum, '"' + stringVal.unescapeCsv() + '"');
        } else {
//          System.debug('DocumentGenerationCSVBuilder.iterateFields: DocumentTemplateColumnConfig IS NULL!');
        }
      }
    }
    return csvRowMap;
  }

  private void iterateChildRecord(List<SObject> objs, String queryId, String path, Map<Integer, String> csvRowMap) {
    for (Integer i = 0; i < objs.size(); i++) {
      String objectAPIName = objs[i].getSObjectType().getDescribe().getName();
      String newPath = path + '[' + i + '].';
      this.iterateFields(objectAPIName, queryId, objs[i].getPopulatedFieldsAsMap(), newPath, csvRowMap);
    }
  }
}