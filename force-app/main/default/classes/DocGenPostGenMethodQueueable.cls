global class DocGenPostGenMethodQueueable implements Queueable, Database.AllowsCallouts {
  private String templateId;
  private Map<String, List<SObject>> sObjectInsertMap;
  private Map<String, List<SObject>> sObjectUpdateMap;
  private final Integer MAX = 2500;

  global DocGenPostGenMethodQueueable(
    String templateId,
    Map<String, List<SObject>> sObjectInsertMap,
    Map<String, List<SObject>> sObjectUpdateMap
  ) {
    this.templateId = templateId;
    this.sObjectInsertMap = sObjectInsertMap;
    this.sObjectUpdateMap = sObjectUpdateMap;
  }

  global void execute(QueueableContext qc) {
    if (
      (this.sObjectInsertMap == null || this.sObjectInsertMap.isEmpty()) &&
      (this.sObjectUpdateMap == null || this.sObjectUpdateMap.isEmpty())
    ) {
      System.debug('DocGenPostMethodQueueable.execute: No records to insert or update!');
      return;
    }

    List<SObject> insertList = this.buildListForDML(this.sObjectInsertMap);
    if (!insertList.isEmpty()) {
      this.handleInsert(insertList);
    } else {
      List<SObject> updateList = this.buildListForDML(this.sObjectUpdateMap);
      if (!updateList.isEmpty()) {
        this.handleUpdate(updateList);
      }
    }

    if (
      !Test.isRunningTest() &&
      (!this.sObjectInsertMap.isEmpty() || !this.sObjectUpdateMap.isEmpty())
    ) {
      System.enqueueJob(
        new DocGenPostGenMethodQueueable(
          this.templateId,
          this.sObjectInsertMap,
          this.sObjectUpdateMap
        )
      );
    }
  }

  private List<SObject> buildListForDML(Map<String, List<SObject>> sObjectMap) {
    List<SObject> records = new List<SObject>();

    for (String key : sObjectMap.keySet()) {
      List<SObject> recordList = sObjectMap.get(key);
      if (recordList.isEmpty()) {
        sObjectMap.remove(key);
        continue;
      }

      Integer count = 0;
      List<SObject> remainingSObjects = new List<SObject>();
      for (SObject rec : recordList) {
        count++;
        if (count <= this.MAX) {
          records.add(rec);
        } else {
          remainingSObjects.add(rec);
        }
      }
      sObjectMap.put(key, remainingSObjects);
      if (recordList.isEmpty()) {
        sObjectMap.remove(key);
      }
      break;
    }

    return records;
  }

  private void handleInsert(List<SObject> insertList) {
    List<SObject> errorInserts = new List<SObject>();

    try {
      List<Database.SaveResult> insertResults = Database.insert(insertList, false);
      for (Integer i = 0; i < insertResults.size(); i++) {
        Database.SaveResult res = insertResults[i];
        if (!res.isSuccess()) {
          errorInserts.add(insertList[i]);
        }
      }
    } catch (DmlException e) {
      errorInserts.addAll(insertList);
    }

    if (!errorInserts.isEmpty()) {
      String csv = this.convertSObjectsToCSV(errorInserts);
      this.sendErrorEmail(csv, 'insert');
    }
  }

  private void handleUpdate(List<SObject> updateList) {
    List<SObject> errorUpdates = new List<SObject>();

    try {
      List<Database.SaveResult> updateResults = Database.update(updateList, false);
      for (Integer i = 0; i < updateResults.size(); i++) {
        Database.SaveResult res = updateResults[i];
        if (!res.isSuccess()) {
          errorUpdates.add(updateList[i]);
        }
      }
    } catch (DmlException e) {
      errorUpdates.addAll(updateList);
    }

    if (!errorUpdates.isEmpty()) {
      String csv = this.convertSObjectsToCSV(errorUpdates);
      this.sendErrorEmail(csv, 'update');
    }
  }

  private String convertSObjectsToCSV(List<SObject> sObjects) {
    List<String> fields = new List<String>();
    for (SObject sObj : sObjects) {
      Map<String, Object> fieldMap = sObj.getPopulatedFieldsAsMap();
      for (String str : fieldMap.keySet()) {
        if (!fields.contains(str)) {
          fields.add(str);
        }
      }
    }
    String headerRow = String.join(fields, ', ');
    String csv = headerRow;

    for (SObject sObj : sObjects) {
      List<String> rowValues = new List<String>();
      for (String str : fields) {
        if (sObj.get(str) != null) {
          rowValues.add(String.valueOf(sObj.get(str)));
        } else {
          rowValues.add(' ');
        }
      }
      String row = String.join(rowValues, ', ');
      csv += '\n' + row;
    }
    return csv;
  }

  private void sendErrorEmail(String csv, String insertOrUpdate) {
    DocGenSettings__c docGenSettings = DocGenSettings__c.getInstance();
    if (docGenSettings == null || String.isBlank(docGenSettings.Email_Service__c)) {
      return;
    }

    DocumentEmail email = new DocumentEmail();
    email.blobContent = Blob.valueOf(csv);
    email.emailContent = 'Attached are the objects that failed to ' + insertOrUpdate + '.';
    email.fileName = 'Document Generation Post Generation Method Errors';
    email.contentType = 'csv';
    email.emailSubject = 'Document Generation Post Generation Method Errors';

    Document_Template__c docTemp = [
      SELECT FROM_Address__c
      FROM Document_Template__c
      WHERE Id = :this.templateId
    ];

    email.toAddress = UserInfo.getUserEmail();
    email.fromAddress = docTemp.FROM_Address__c;
    DocumentEmailService emailService = DocumentEmailServiceFactory.getEmailServiceByType(
      docGenSettings.Email_Service__c
    );
    if (!Test.isRunningTest()) {
      emailService.sendEmails(new List<DocumentEmail>{ email });
    }
  }
}