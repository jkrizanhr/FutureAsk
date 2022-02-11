public without sharing class DonationPageAuthNetSubscriptionJob implements Database.Batchable<SObject>, Schedulable, Database.AllowsCallouts {
  private List<Id> submissionIds;

  public DonationPageAuthNetSubscriptionJob(List<Id> submissionIds) {
    this.submissionIds = submissionIds;
  }

  public void execute(SchedulableContext sc) {
    Database.executeBatch(new DonationPageAuthNetSubscriptionJob(null), 1);
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    String query =
      'SELECT ' +
      getQueryFields() +
      ' FROM Donation_Form_Submission__c WHERE Frequency__c != \'One-time\'' +
      ' AND Payment_Processor_Subscription_Id__c = NULL';

    if (submissionIds != null) {
      List<Id> dfsIds = submissionIds;
      query += ' AND Id IN :dfsIds';
    } else {
      query +=
        ' AND CreatedDate < ' +
        Datetime.now().addMinutes(-5).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
    }
    return Database.getQueryLocator(query);
  }

  public void execute(
    Database.BatchableContext bc,
    List<Donation_Form_Submission__c> submissions
  ) {
    List<Donation_Form_Submission__c> submissionsToUpdate = new List<Donation_Form_Submission__c>();
    for (Donation_Form_Submission__c dfs : submissions) {
      // do not process anything that has errors
      if (String.isBlank(dfs.Errors__c)) {
        try {
          DonationPageAuthNetSubscriptionHandler handler = new DonationPageAuthNetSubscriptionHandler(
            dfs
          );
          dfs = handler.run();
        } catch (DonationPagePaymentServiceException e) {
          dfs.Errors__c = e.getMessage();
        } catch (Exception ex) {
          dfs.Errors__c = ex.getMessage() + '\r\n' + ex.getStackTraceString();
        }
        submissionsToUpdate.add(dfs);
      }
    }

    if (!submissionsToUpdate.isEmpty()) {
      update submissionsToUpdate;
    }
  }

  public void finish(Database.BatchableContext bc) {
  }

  private static String getQueryFields() {
    Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Donation_Form_Submission__c.fields.getMap();
    List<String> fields = new List<String>();
    for (Schema.SObjectField sObjField : fieldMap.values()) {
      Schema.DescribeFieldResult dfr = sObjField.getDescribe();
      fields.add(dfr.getName());
    }
    return String.join(fields, ',');
  }
}