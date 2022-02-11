public class DocumentMergeFieldProcessor {
  private DocumentFieldLibrary fieldLib;
  private final String mergeFieldStartTag = '{!';
  private final String mergeFieldEndTag = '}';
  public Map<String, String> mergeFieldAnswerMap;
  public Map<String, String> mergeFieldDataTypeMap;
  public SObject record;
  public String deliveryOption;
  public String jobLogId;
  public String stringToParseThru;
  public String primaryQueryCorrelation;
  public Map<String, String> recordFieldMap;

  public DocumentMergeFieldProcessor() {
    this.fieldLib = new DocumentFieldLibrary();
    this.mergeFieldAnswerMap = new Map<String, String>();
    this.mergeFieldDataTypeMap = new Map<String, String>();
    this.recordFieldMap = new Map<String, String>();
  }

  public String processString() {
    String resultString = '';
    if (String.isBlank(this.stringToParseThru)) {
      return resultString;
    }

    if (String.isNotBlank(this.primaryQueryCorrelation)) {
      this.primaryQueryCorrelation = this.primaryQueryCorrelation.toLowerCase();
    }

    resultString = stringToParseThru;
    Integer lastStart = 0;
    Integer startMergeFieldIndex = stringToParseThru.indexOf(this.mergeFieldStartTag, lastStart);
    Integer endMergeFieldIndex = stringToParseThru.indexOf(this.mergeFieldEndTag, startMergeFieldIndex);

    if (startMergeFieldIndex == -1 || endMergeFieldIndex == -1) {
      return resultString;
    }

    do {
      lastStart = endMergeFieldIndex;

      String mergeField = stringToParseThru.substring(startMergeFieldIndex, endMergeFieldIndex + this.mergeFieldEndTag.length());

      resultString = resultString.replace(mergeField, mergeField.toLowerCase());
      mergeField = mergeField.toLowerCase();

      String field = mergeField.substring(this.mergeFieldStartTag.length(), mergeField.length() - this.mergeFieldEndTag.length());

      field = field.toLowerCase();

      resultString = handleMergeFieldReplacementLogic(resultString, mergeField, field);
      startMergeFieldIndex = stringToParseThru.indexOf(this.mergeFieldStartTag, lastStart);
      endMergeFieldIndex = stringToParseThru.indexOf(this.mergeFieldEndTag, startMergeFieldIndex);
    } while (startMergeFieldIndex != -1 && endMergeFieldIndex != -1);

    return resultString;
  }

  private String handleMergeFieldReplacementLogic(String resultString, String mergeField, String field) {
    // Only replace the = or IN of the where clause if it is for the query correlation field
    if (String.isNotBlank(this.primaryQueryCorrelation)
        && (this.primaryQueryCorrelation == mergeField || this.primaryQueryCorrelation == field)) {
      if (this.record != null) {
        resultString = replaceOneOffWhereClause(resultString, mergeField);
      } else {
        resultString = replaceBulkWhereClause(resultString, mergeField);
      }
    }

    if (this.mergeFieldAnswerMap != null && this.mergeFieldAnswerMap.containsKey(mergeField)) {
      // Replace merge fields using mergeFieldAnswerMap(question answer map)
      String answer = this.mergeFieldAnswerMap.get(mergeField);
      if (answer != null) {
        resultString = resultString.replace(mergeField, answer);
      }

    } else if (this.fieldLib.mergeFieldMap.containsKey(mergeField)) {
      // Replace merge fields using DocumentFieldLibrary fields
      String fieldLibValue = this.fieldLib.mergeFieldMap.get(mergeField);
      resultString = resultString.replace(mergeField, fieldLibValue);

    } else if (mergeField == '{!deliveryOption}') {
      // Replace misc merge fields that could be the delivery option, etc.
      resultString = resultString.replace(mergeField, this.deliveryOption);

    } else if (this.jobLogId != null && mergeField == '{!jobLogId}') {
      // Replace misc merge fields that could be the delivery option, etc.
      resultString = resultString.replace(mergeField, this.jobLogId);

    } else if (this.record != null) {
      // Replace merge fields using populated fields from the Primary SOQL Query result
      // Check that it is a real field before replacing/clearing out the text
      Boolean isValidField = DocGenFieldService.validateField(this.record, field);

      if (isValidField == false) {
        return resultString;
      }

      String value;
      if (this.recordFieldMap.isEmpty()) {
        value = DocGenFieldService.mergeRecordValue(this.record, field);
      } else {
        value = this.recordFieldMap.get(field);
      }

      if (value == null) {
        System.debug('unable to replace field: ' + field);
        value = '';
      }
      // Use the mergeFieldDataTypeMap to escape quotes as needed when replacing the string
      if (this.mergeFieldDataTypeMap.containsKey(mergeField)) {
        if (this.mergeFieldDataTypeMap.get(mergeField) == 'Date' && String.isNotBlank(value)) {
          value = '\' + Date.valueOf(value) + \'';
        }
      } else {
        value = DocGenFieldService.mergeRecordValue(this.record, field);
      }
      value = value.replaceAll('\r\n', '\\\\r\\\\n');
      resultString = resultString.replace(mergeField, value);
    } else {
      resultString = resultString.replace(mergeField, '');
    }

    return resultString;
  }

  // Dynamically replace the field. It could be Id, AccountId or another Id datatype field
  private String replaceOneOffWhereClause(String queryString, String mergeField) {
    if (String.isNotBlank(queryString)) {
      queryString = replaceMergeField(queryString, 'IN :' + mergeField, '= \'' + mergeField + '\'');
      queryString = replaceMergeField(queryString, 'IN \'' + mergeField + '\'', '= \'' + mergeField + '\'');
      queryString = replaceMergeField(queryString, 'IN \':' + mergeField + '\'', '= \'' + mergeField + '\'');
      queryString = replaceMergeField(queryString, '= :' + mergeField, '= \'' + mergeField + '\'');
      queryString = replaceMergeField(queryString, '= \':' + mergeField + '\'', '= \'' + mergeField + '\'');
      queryString = replaceMergeField(queryString, '= ' + mergeField, '= \'' + mergeField + '\'');
    }
    return queryString;
  }

  // Dynamically replace the field. It could be Id, AccountId or another Id datatype field
  private String replaceBulkWhereClause(String queryString, String mergeField) {
    if (String.isNotBlank(queryString)) {
      queryString = replaceMergeField(queryString, '= :' + mergeField, 'IN :ids');
      queryString = replaceMergeField(queryString, '= \'' + mergeField + '\'', 'IN :ids');
      queryString = replaceMergeField(queryString, '= \':' + mergeField + '\'', 'IN :ids');
      queryString = replaceMergeField(queryString, 'IN :' + mergeField, 'IN :ids');
      queryString = replaceMergeField(queryString, 'IN \':' + mergeField + '\'', 'IN :ids');
    }
    return queryString;
  }

  private String replaceMergeField(String queryString, String mergeField, String newValue) {
    if (String.isNotBlank(queryString) && queryString.indexOf(mergeField) != -1) {
      queryString = queryString.replace(mergeField, newValue);
    }
    return queryString;
  }
}