public inherited sharing class SmartUpsert {
  // TODO: Handle single objects
  // TODO: Handle External IDs
  private class SmartException extends Exception {
  }

  private static String processResults(List<Database.SaveResult> results) {
    String ids;

    for (Database.SaveResult saveResult : results) {
      if (!saveResult.isSuccess()) {
        for (Database.Error error : saveResult.getErrors()) {
          throw new SmartException(error.getStatusCode() + ' :: ' + error.getMessage());
        }
      } else {
        if (String.isBlank(ids)) {
          ids = '\'' + saveResult.getId() + '\'';
        } else {
          ids += ',\'' + saveResult.getId() + '\'';
        }
      }
    }

    return ids;
  }

  public static void go(List<SObject> objects) {
    Database.DMLOptions options = new Database.DMLOptions();
    go(objects, options);
  }

  public static void go(List<SObject> objects, Database.DMLOptions options) {
    List<SObject> changedRecords = new List<SObject>();

    if (objects.size() > 0) {
      Set<String> allFields = new Set<String>();

      for (SObject record : objects) {
        Map<String, Object> recordFields = record.getPopulatedFieldsAsMap();

        for (String fieldName : recordFields.keySet()) {
          allFields.add(fieldName);
        }
      }

      String fields;
      String ids;
      String type = String.valueOf(objects[0].getSObjectType());

      for (String fieldName : allFields) {
        if (String.isBlank(fields)) {
          fields = fieldName;
        } else {
          fields += ',' + fieldName;
        }
      }

      for (SObject record : objects) {
        if (record.Id == null) {
          // Skip
        } else if (String.isBlank(ids)) {
          ids = '\'' + record.Id + '\'';
        } else {
          ids += ',\'' + record.Id + '\'';
        }
      }

      String query;
      Map<Id, SObject> existingMap = new Map<Id, SObject>();

      if (String.isNotBlank(fields) && String.isNotBlank(ids)) {
        query = 'SELECT ' + fields + ' FROM ' + type + ' WHERE Id IN (' + ids + ')';

        existingMap = new Map<Id, SObject>((List<SObject>) Database.query(query));
      }

      List<SObject> updateRecords = new List<SObject>();
      List<SObject> insertRecords = new List<SObject>();

      for (SObject record : objects) {
        if (String.isBlank(record.Id)) {
          insertRecords.add(record);
        } else if (record != existingMap.get(record.Id)) {
          updateRecords.add(record);
        } else {
          // Do nothing.
        }
      }

      String newIds = '';

      // if (options != null) {
      if (insertRecords.size() > 0) {
        newIds += processResults(Database.insert(insertRecords, options));
      }

      if (updateRecords.size() > 0) {
        if (String.isNotBlank(newIds)) {
          newIds += ',';
        }

        newIds += processResults(Database.update(updateRecords, options));
      }

      if (String.isNotBlank(newIds)) {
        //  Query and set values to the new values.
        query = 'SELECT ' + fields + ' FROM ' + type + ' WHERE Id IN (' + newIds + ')';
        objects.clear();
        objects.addAll(Database.query(query));
      }
    }
  }
}