public class DocumentPostGenMethodService {
  private List<Document_Post_Generation_Method__c> postMethods;
  private String deliveryOption;
  private Map<String, String> mergeFieldAnswerMap;
  private Id jobLogId;

  public DocumentPostGenMethodService(
      List<Document_Post_Generation_Method__c> postMethods,
      String deliveryOption,
      Map<String, String> mergeFieldAnswerMap,
      Id jobLogId) {
    this.postMethods = postMethods;
    this.deliveryOption = deliveryOption;
    this.mergeFieldAnswerMap = mergeFieldAnswerMap;
    this.jobLogId = jobLogId;
  }

  public List<DocumentGeneratorModel.PostGenContainer> processRecords(List<SObject> records) {
    List<DocumentGeneratorModel.PostGenContainer> postGenContainers
        = new List<DocumentGeneratorModel.PostGenContainer>();

    if (records == null
        || records.isEmpty()
        || this.postMethods == null
        || this.postMethods.isEmpty()) {
      return postGenContainers;
    }

    for (SObject record : records) {
      DocumentGeneratorModel.PostGenContainer postGenContainer
          = new DocumentGeneratorModel.PostGenContainer(record);

      for (Document_Post_Generation_Method__c postMethod : this.postMethods) {
        // We only want to do the Document Post Generation Methods that are meant for the delivery option selected.
        if (String.isBlank(postMethod.Delivery_Options__c)
            || !postMethod.Delivery_Options__c.contains(this.deliveryOption)) {
          continue;
        }
        // Replace merge fields in the method.Data_to_Insert_Update__c field with the results in the sObj record
        DocumentMergeFieldProcessor mergeFieldProcessor = new DocumentMergeFieldProcessor();
        mergeFieldProcessor.deliveryOption = this.deliveryOption;
        mergeFieldProcessor.stringToParseThru = postMethod.Data_to_Insert_Update__c;
        mergeFieldProcessor.record = record;
        mergeFieldProcessor.mergeFieldAnswerMap = this.mergeFieldAnswerMap;
        mergeFieldProcessor.jobLogId = this.jobLogId;

        String dataJSON = mergeFieldProcessor.processString();

        // Get the api name of the salesforce object to deserialize to
        String sObjectAPIName = postMethod.Object__c;

        // Deserialize the method.Data_to_Insert_Update__c JSON object
        dataJSON = dataJSON.replaceAll('/\\/g', '');
        SObject newSObj = this.buildObjectDataToInsertOrUpdate(sObjectAPIName, dataJSON);
        this.addObjectToMap(newSObj, sObjectAPIName, postGenContainer);
      }
      postGenContainers.add(postGenContainer);
    }
    return postGenContainers;
  }

  private SObject buildObjectDataToInsertOrUpdate(String sObjectAPIName, String dataJSON) {
    Map<String, Object> fieldMap = (Map<String, Object>) JSON.deserializeUntyped(dataJSON);
    Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sObjectAPIName);
    SObject newSObject = targetType.newSObject();
    Map<String, Schema.SObjectField> targetFields = targetType.getDescribe().fields.getMap();

    for (String key : fieldMap.keySet()) {
      Object value = fieldMap.get(key);
      if (!targetFields.containsKey(key)) {
        if (this.jobLogId != null) {
          Document_Generation_Error_Event__e errorEvent = new Document_Generation_Error_Event__e();
          errorEvent.Apex_Class_Name__c = 'DocumentPostGenMethodService';
          errorEvent.Apex_Method_Name__c = 'buildObjectDataToInsertOrUpdate';
          errorEvent.Document_Generation_Job_Id__c = this.jobLogId;
          errorEvent.Error_Message__c = 'The Data to Insert/Update on the Document Post Generation Method contains a'
              + ' field that is not found on the target object.'
              + '\nDataJSON: ' + dataJSON
              + '\nObject: ' + sObjectAPIName
              + '\nInvalid field: ' + key;
          EventBus.publish(errorEvent);
        }

        throw new DocumentGenerationException('DocumentPostGenMethodService.buildObjectDataToInsertOrUpdate: Error! '
            + 'The Data to Insert/Update on the Document Post Generation Method contains a field that is not found on the target object.');
      }

      Schema.DisplayType valueType = targetFields.get(key).getDescribe().getType();
      if (value != null && value instanceof String && valueType != Schema.DisplayType.STRING) {
        String stringValue = (String) value;
        if (valueType == Schema.DisplayType.DATE) {
          newSObject.put(key, Date.valueOf(stringValue));
        } else if (valueType == Schema.DisplayType.DATETIME) {
          newSObject.put(key, Datetime.valueOf(stringValue));
        } else if (valueType == Schema.DisplayType.PERCENT || valueType == Schema.DisplayType.CURRENCY) {
          newSObject.put(key, Decimal.valueOf(stringValue).setScale(2));
        } else if (valueType == Schema.DisplayType.DOUBLE) {
          newSObject.put(key, Double.valueOf(stringValue));
        } else if (valueType == Schema.DisplayType.INTEGER) {
          newSObject.put(key, Integer.valueOf(stringValue));
        } else if (valueType == Schema.DisplayType.BASE64) {
          newSObject.put(key, Blob.valueOf(stringValue));
        } else {
          newSObject.put(key, stringValue);
        }
      } else {
        newSObject.put(key, value);
      }
    }
    return newSObject;
  }

  private void addObjectToMap(
      SObject newSObj,
      String sObjectAPIName,
      DocumentGeneratorModel.PostGenContainer postGenContainer) {
    if (newSObj.get('Id') == null) {
      // Use insert map
      List<SObject> sObjects = postGenContainer.postGenInsertMap.get(sObjectAPIName);
      if (sObjects == null) {
        sObjects = new List<SObject>();
        postGenContainer.postGenInsertMap.put(sObjectAPIName, sObjects);
      }
      sObjects.add(newSObj);
    } else {
      // Use update map
      List<SObject> sObjects = postGenContainer.postGenUpdateMap.get(sObjectAPIName);
      if (sObjects == null) {
        sObjects = new List<SObject>();
        postGenContainer.postGenUpdateMap.put(sObjectAPIName, sObjects);
      }
      sObjects.add(newSObj);
    }
  }

  public static void executePostGenContainerMethods(
      List<DocumentGeneratorModel.PostGenContainer> postGenContainers,
      Id jobLogId) {

    // Build insert/update maps
    Map<String, List<SObject>> sObjectInsertMap = new Map<String, List<SObject>>();
    Map<String, List<SObject>> sObjectUpdateMap = new Map<String, List<SObject>>();

    for (DocumentGeneratorModel.PostGenContainer postGenContainer : postGenContainers) {
      // Build insert map by object type
      for (String objectNameKey : postGenContainer.postGenInsertMap.keySet()) {
        List<SObject> insertList = postGenContainer.postGenInsertMap.get(objectNameKey);
        if (!insertList.isEmpty()) {
          List<SObject> newInsertList = sObjectInsertMap.get(objectNameKey);
          if (newInsertList == null) {
            newInsertList = new List<SObject>();
            sObjectInsertMap.put(objectNameKey, newInsertList);
          }
          newInsertList.addAll(insertList);
        }
      }

      // Build update map by object type
      for (String objectNameKey : postGenContainer.postGenUpdateMap.keySet()) {
        List<SObject> updateList = postGenContainer.postGenUpdateMap.get(objectNameKey);
        if (!updateList.isEmpty()) {
          List<SObject> newUpdateList = sObjectUpdateMap.get(objectNameKey);
          if (newUpdateList == null) {
            newUpdateList = new List<SObject>();
            sObjectUpdateMap.put(objectNameKey, newUpdateList);
          }
          newUpdateList.addAll(updateList);
        }
      }
    }

    doInserts(sObjectInsertMap, jobLogId);
    doUpdates(sObjectUpdateMap, jobLogId);
  }

  private static void doInserts(Map<String, List<SObject>> sObjectInsertMap, Id jobLogId) {
    List<String> insertErrors = new List<String>();
    Integer numUnknownErrors = 0;

    for (String key : sObjectInsertMap.keySet()) {
      List<SObject> recordsToInsert = sObjectInsertMap.get(key);
      List<Database.SaveResult> insertResults = Database.insert(recordsToInsert, false);
      numUnknownErrors += buildErrorMessageList(insertResults, insertErrors);
    }

    if (!insertErrors.isEmpty() || numUnknownErrors > 0) {
      // Handle insertErrors by creating a platform event

      String insertErrorMessage = 'Post generation method insert errors:';

      if (numUnknownErrors > 0) {
        insertErrorMessage += '\n' + numUnknownErrors + ' unknown errors.';
      }

      if (!insertErrors.isEmpty()) {
        insertErrorMessage += '\n' + String.join(insertErrors, ',');
      }
      if(insertErrorMessage.length() > 131072) {
        insertErrorMessage = insertErrorMessage.substring(0, 131072);
      }

      Document_Generation_Error_Event__e errorEvent = new Document_Generation_Error_Event__e();
      errorEvent.Apex_Class_Name__c = 'DocumentPostGenMethodService';
      errorEvent.Apex_Method_Name__c = 'doInserts';
      errorEvent.Document_Generation_Job_Id__c = jobLogId;
      errorEvent.Error_Message__c = insertErrorMessage;
      EventBus.publish(errorEvent);
    }
  }

  private static void doUpdates(Map<String, List<SObject>> sObjectUpdateMap, Id jobLogId) {
    List<String> updateErrors = new List<String>();
    Integer numUnknownErrors = 0;

    for (String key : sObjectUpdateMap.keySet()) {
      List<SObject> recordsToUpdate = sObjectUpdateMap.get(key);
      List<Database.SaveResult> updateResults = Database.update(recordsToUpdate, false);
      numUnknownErrors += buildErrorMessageList(updateResults, updateErrors);
    }

    if (!updateErrors.isEmpty() || numUnknownErrors > 0) {
      // Handle updateErrors by creating a platform event

      String insertErrorMessage = 'Post generation method update errors:';

      if (numUnknownErrors > 0) {
        insertErrorMessage += '\n' + numUnknownErrors + ' unknown errors.';
      }

      if (!updateErrors.isEmpty()) {
        insertErrorMessage += '\n' + String.join(updateErrors, ',');
      }
      insertErrorMessage = insertErrorMessage.substring(0, 131072);

      Document_Generation_Error_Event__e errorEvent = new Document_Generation_Error_Event__e();
      errorEvent.Apex_Class_Name__c = 'DocumentPostGenMethodService';
      errorEvent.Apex_Method_Name__c = 'doUpdates';
      errorEvent.Document_Generation_Job_Id__c = jobLogId;
      errorEvent.Error_Message__c = insertErrorMessage;
      EventBus.publish(errorEvent);
    }
  }

  private static Integer buildErrorMessageList(List<Database.SaveResult> results, List<String> errors) {
    Integer numUnknownErrors = 0;

    for (Database.SaveResult res : results) {
      if (!res.isSuccess()) {
        if (res.getErrors() != null && !res.getErrors().isEmpty()) {
          for (Database.Error err : res.getErrors()) {
            if (String.isNotBlank(err.getMessage())) {
              errors.add(err.getMessage());
            } else {
              // Unknown error
              numUnknownErrors++;
            }
          }
        } else {
          // Unknown error
          numUnknownErrors++;
        }
      }
    }

    return numUnknownErrors;
  }

  /**
   * Used for One-Off PDF - Direct Download delivery option
   *
   * This method serves as an intermediary because a Visualforce Page cannot have an
   * action method (controller method) that performs DML statements.
   *
   * We cannot call a future from a batch job method so we have another method in this class
   * named executeBulkFinishPostGenerationMethods for that scenario.
   *
   * @param emailContentString
   * @param recordInsertJSON
   * @param recordUpdateJSON
   */
  @Future(Callout=true)
  public static void finishPdfDirectDownloadPostMethods(String postGenContainersJSON) {

    List<DocumentGeneratorModel.PostGenContainer> postGenContainers = new List<DocumentGeneratorModel.PostGenContainer>();
    if (String.isNotBlank(postGenContainersJSON)) {
      postGenContainers = (List<DocumentGeneratorModel.PostGenContainer>) JSON.deserialize(
          postGenContainersJSON, List<DocumentGeneratorModel.PostGenContainer>.class);
    }

    executePostGenContainerMethods(postGenContainers, null);
  }
}