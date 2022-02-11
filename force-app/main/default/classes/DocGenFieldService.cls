public class DocGenFieldService {
  public static Boolean validateField(SObject sObj, String fieldPath) {
    if (sObj == null || String.isBlank(fieldPath)) {
      return false;
    }

    String objectName = sObj.getSObjectType().getDescribe().getName();
    if (String.isBlank(objectName)) {
      return false;
    }

    Schema.SObjectType currentSObjType = Schema.getGlobalDescribe().get(objectName);
    fieldPath = fieldPath.toLowerCase();
    List<String> arr = fieldPath.split('\\.');

    // Iterate over the field path
    for (Integer i = 0; i < arr.size(); i++) {
      // Get the fields for the current SObject Type
      Map<String, Schema.SObjectField> fieldMap = currentSObjType.getDescribe().fields.getMap();

      if (i == arr.size() - 1) {
        // Reached end of path
        if (fieldMap.containsKey(arr[i])) {
          return true;
        } else {
          return false;
        }
      } else {
        currentSObjType = validateObjectRelationship(currentSObjType, fieldMap, arr[i]);
        if (currentSObjType == null) {
          return false;
        }
      }
    }
    return false;
  }

  private static Schema.SObjectType validateObjectRelationship(
      Schema.SObjectType currentSObjType,
      Map<String, Schema.SObjectField> fieldMap,
      String field) {

    if (String.isNotBlank(field)) {
      Integer i = field.indexOf('[');
      if (i != -1) {
        // Is array of subquery results
        field = field.substring(0, i);
      }
    }

    for (Schema.SObjectField sObjField : fieldMap.values()) {
      if (sObjField.getDescribe().getRelationshipName() == field) {
        currentSObjType = sObjField.getDescribe().getReferenceTo()[0];
        return currentSObjType;
      }
    }

    List<Schema.ChildRelationship> childRelationships = currentSObjType.getDescribe().getChildRelationships();
    for (Schema.ChildRelationship cr : childRelationships) {
      if (cr.getRelationshipName() == field) {
        return cr.getChildSObject();
      }
    }
    return null;
  }

  public static String mergeRecordValue(SObject sObj, String fieldPath) {
    String result = '';
    fieldPath = fieldPath.toLowerCase();
    List<String> arr = fieldPath.split('\\.');
    for (Integer i = 0; i < arr.size(); i++) {
      if (i == arr.size() - 1) {
        // Reached end of path
        Map<String, Object> populatedFieldMap = sObj.getPopulatedFieldsAsMap();
        Map<String, Object> fieldValueMap = new Map<String, Object>();
        for (String field : populatedFieldMap.keySet()) {
          fieldValueMap.put(field.toLowerCase(), populatedFieldMap.get(field));
        }

        if (fieldValueMap.containsKey(arr[i]) && arr[i] != null) {
          String sObjectName = String.valueOf(sObj.getSObjectType());
          result = DocGenFieldService.formatFieldValue(sObj.get(arr[i]), sObjectName, arr[i]);
        } else {
          result = '';
        }
      } else {
        sObj = sObj.getSObject(arr[i]);
      }
    }
    return result;
  }

  public static String formatFieldValue(Object val, String objectAPIName, String fieldName) {
    // Determine the data type
    String dataType = getDataType(val);

    Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectAPIName);
    Schema.DescribeSObjectResult sObjResult = sObjType.getDescribe();
    Schema.DescribeFieldResult fieldResult = sObjResult.fields.getMap().get(fieldName).getDescribe();
    Schema.DisplayType dispType = fieldResult.getType();
    String stringVal = String.valueOf(val);

    if (dataType == 'Date') {
      stringVal = Date.valueOf(val).format();
    } else if (dataType == 'DateTime') {
      stringVal = Datetime.valueOf(val).format();
    } else if (dataType == 'Decimal') {
      Decimal decimalVal = Decimal.valueOf(stringVal.replaceAll(',', ''));
      decimalVal = decimalVal.setScale(2);
      List<String> args = new String[]{
          '0', 'number', '###,###,##0.00'
      };
      stringVal = String.format(decimalVal.format(), args);
      if (dispType == Schema.DisplayType.CURRENCY) {
        stringVal = formatCurrency(stringVal);
      }
    }
    return stringVal;
  }

  public static String getDataType(Object obj) {
    if (obj == null) return '';
    if (obj instanceof SObject) return ((SObject) obj).getSObjectType().getDescribe().getName() + '';
    if (obj instanceof Boolean) return 'Boolean';
    if (obj instanceof Id) return 'Id';
    if (obj instanceof String) return 'String';
    if (obj instanceof Blob) return 'Blob';
    if (obj instanceof Date) return 'Date';
    if (obj instanceof Datetime) return 'Datetime';
    if (obj instanceof Time) return 'Time';
    if (obj instanceof Integer) return 'Integer';
    if (obj instanceof Long) return 'Long';
    if (obj instanceof Decimal) return 'Decimal';  // We can't distinguish between Decimal and Double
    if (obj instanceof Double) return 'Double';
    if (obj instanceof List<Object>) return 'List';
    return 'Object';                    // We can't detect Maps and Sets
  }

  public static String doSpecificFormat(Object val, String format) {
    String stringVal = String.valueOf(val);
    if (String.isNotBlank(format)) {
      if (format == 'date') {
        try {
          Date dateValue = Date.valueOf(val);
          return dateValue.format();
        } catch (TypeException e) {
          System.debug(e.getMessage());
        }
      } else if (format == 'datetime') {
        return Datetime.valueOf(val).format();
      } else if (format == 'currency') {
        return formatCurrency(stringVal);
      } else if (format == 'dateyyyy') {
        return String.valueOf(Date.valueOf(val).year());
      }
    }
    return stringVal;
  }

  public static String formatCurrency(String stringVal) {
    if (String.isBlank(stringVal)) {
      return '';
    }
    Decimal decimalVal = Decimal.valueOf(stringVal.replaceAll(',', ''));
    decimalVal = decimalVal.setScale(2);
    List<String> args = new List<String>{
        '0', 'number', '###,###,###.##'
    };
    stringVal = String.format(decimalVal.format(), args);
    if (stringVal.contains('.')) {
      String str = stringVal.substringAfter('.');
      if (str.length() < 2) {
        stringVal += '0';
      }
    } else {
      stringVal += '.00';
    }
    stringVal = ('$' + stringVal).unescapeCsv();
    return stringVal;
  }
}