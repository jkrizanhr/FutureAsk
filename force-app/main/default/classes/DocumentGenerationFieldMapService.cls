public class DocumentGenerationFieldMapService {
  public Map<String, String> createRecordFieldMap(SObject record) {
    // Map containing the field path to value of the record data
    Map<String, String> recordMergeFieldMap = new Map<String, String>();
    String objectAPIName = record.getSObjectType().getDescribe().getName();
    iterateFields(objectAPIName, record.getPopulatedFieldsAsMap(), '', recordMergeFieldMap);
    return recordMergeFieldMap;
  }

  private Map<String, String> iterateFields(String objectAPIName, Map<String, Object> fieldsToValueMap, String path, Map<String, String> recordMergeFieldMap) {
    for (String fieldName : fieldsToValueMap.keySet()) {
      if (fieldsToValueMap.get(fieldName) instanceof List<SObject>) {
        iterateChildRecord((List<SObject>) fieldsToValueMap.get(fieldName), path + fieldName, recordMergeFieldMap);
      } else if (fieldsToValueMap.get(fieldName) instanceof SObject) {
        SObject obj = (SObject) fieldsToValueMap.get(fieldName);
        String parentObjectAPIName = obj.getSObjectType().getDescribe().getName();
        path = path + fieldName + '.';
        iterateFields(parentObjectAPIName, obj.getPopulatedFieldsAsMap(), path, recordMergeFieldMap);
      } else {
        Object val = fieldsToValueMap.get(fieldName);
        String stringVal = DocGenFieldService.formatFieldValue(val, objectAPIName, fieldName);

        // Add to the recordMergeFieldMap
        String endPath = path + fieldName;
        if (recordMergeFieldMap.containsKey(endPath) == false) {
          recordMergeFieldMap.put(endPath.toLowerCase(), stringVal);
        }
      }
    }
    return recordMergeFieldMap;
  }

  private void iterateChildRecord(List<SObject> objs, String path, Map<String, String> recordMergeFieldMap) {
    for (Integer i = 0; i < objs.size(); i++) {
      String objectAPIName = objs[i].getSObjectType().getDescribe().getName();
      String newPath = path + '[' + i + '].';
      iterateFields(objectAPIName, objs[i].getPopulatedFieldsAsMap(), newPath, recordMergeFieldMap);
    }
  }
}