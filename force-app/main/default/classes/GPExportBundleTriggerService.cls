/**
 * @author Candoris
 * August 2020
 * GP Export Bundle object's trigger service class.
 */
public inherited sharing class GPExportBundleTriggerService {
  /**
   * After Insert.
   * Retrieve cash batch records that are within the start and end date
   * of the gp export bundle record, and then start the gp export bundle job.
   * @param bundles - A list of gp export bundle records from Trigger.new
   */
  public static void bundleBatches(List<GP_Export_Bundle__c> bundles) {
    if (
      bundles[0].RecordTypeId ==
      Utils.getRecordTypeId('GP_Export_Bundle__c', 'Donation Income')
    ) {
      List<Cash_Batch__c> batches = [
        SELECT Id, GP_Export_Bundle__c
        FROM Cash_Batch__c
        WHERE
          Status__c = 'Approved'
          AND Date__c >= :bundles[0].Start_Date__c
          AND Date__c <= :bundles[0].End_Date__c
          AND GP_Export_Bundle__c = null
        // AND Region_Category__c = :bundles[0].Region_Category__c
      ];

      if (!batches.isEmpty()) {
        for (Cash_Batch__c batch : batches) {
          batch.GP_Export_Bundle__c = bundles[0].Id;
        }

        update batches;

        Database.executeBatch(new GPExportBundleJob(bundles[0].Id), 1);
      } else {
        // Throw error for user
        bundles[0]
          .addError(
            'No approved cash batches found that have a date between the gp export bundle\'s start and end date.'
          );
      }
    }
  }

  /**
   * After Insert.
   * Get the count of transfer records that are within the start and end date of the gp export
   * bundle record, and then start the batch job.
   * @param bundles - A list of gp export bundle records from Trigger.new
   */
  public static void bundleTransfers(List<GP_Export_Bundle__c> bundles) {
    if (
      bundles[0].RecordTypeId ==
      Utils.getRecordTypeId('GP_Export_Bundle__c', 'GAU Reclass')
    ) {
      List<Transfer__c> transfers = [
        SELECT Id, GP_Export_Bundle__c
        FROM Transfer__c
        WHERE
          Date__c >= :bundles[0].Start_Date__c
          AND Date__c <= :bundles[0].End_Date__c
          AND GP_Export_Bundle__c = null
      ];

      if (!transfers.isEmpty()) {
        for (Transfer__c transfer : transfers) {
          transfer.GP_Export_Bundle__c = bundles[0].Id;
        }

        update transfers;

        new GPExportBundleTransferService(bundles[0].Id).run();
      } else {
        // Throw error for user
        bundles[0]
          .addError(
            'No transfers found that have a date between the gp export bundle\'s start and end date.'
          );
      }
    }
  }

  /**
   * Before Update.
   * Set the Validation Error checkbox to true if the Fund GL Error Message is populated,
   * otherwise set the checkbox to false.
   * @param bundles - A list of gp export bundle records from Trigger.new
   */
  public static void manageValidationErrorCheckbox(
    List<GP_Export_Bundle__c> bundles
  ) {
    for (GP_Export_Bundle__c bundle : bundles) {
      bundle.Validation_Error__c = String.isNotBlank(
        bundle.Fund_GL_Error_Message__c
      );
    }
  }

  /**
   * Before Update
   * If the Fund GL Validation Check on the GP Export Bundle has been changed to 'Validation Completed'
   * or if the Validation Error has been changed and the GP Export Bundle Job has finished running
   * then send out the email notifications.
   * @param bundles - Trigger.new
   * @param oldMap - Trigger.oldMap
   */
  public static void sendEmailNotifications(
    List<GP_Export_Bundle__c> bundles,
    Map<Id, GP_Export_Bundle__c> oldMap
  ) {
    List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

    for (GP_Export_Bundle__c bundle : bundles) {
      if (
        bundle.Fund_GL_Validation_Check__c !=
        oldMap.get(bundle.Id).Fund_GL_Validation_Check__c &&
        bundle.Fund_GL_Validation_Check__c == 'Validation Completed'
      ) {
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        emailMessage.setSubject('GP Export Bundle Job');
        String body =
          'The GP Export Bundle has finished processing and has validated successfully. The record can be accessed here: ' +
          Url.getSalesforceBaseUrl().toExternalForm() +
          '/' +
          bundle.Id;
        emailMessage.setPlainTextBody(body);
        emailMessages.add(emailMessage);
      } else if (
        bundle.Apex_Job_Completed__c &&
        bundle.Validation_Error__c &&
        (!oldMap.get(bundle.Id).Apex_Job_Completed__c ||
        !oldMap.get(bundle.Id).Validation_Error__c)
      ) {
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        emailMessage.setSubject('GP Export Bundle Job');
        String body =
          'The GP Export Bundle has finished processing and has found a validation error. The record can be accessed here: ' +
          Url.getSalesforceBaseUrl().toExternalForm() +
          '/' +
          bundle.Id;
        emailMessage.setPlainTextBody(body);
        emailMessages.add(emailMessage);
      }
    }

    if (!emailMessages.isEmpty()) {
      List<User> users = [
        SELECT Email
        FROM User
        WHERE Id = :UserInfo.getUserId()
      ];
      List<String> toAddresses = new List<String>{ users[0].Email };

      Map<String, GP_Export_Bundle_Settings__c> settingsMap = GP_Export_Bundle_Settings__c.getAll();
      for (GP_Export_Bundle_Settings__c setting : settingsMap.values()) {
        toAddresses.add(setting.Notification_Recipient_Email__c);
      }

      for (Messaging.SingleEmailMessage emailMessage : emailMessages) {
        emailMessage.setToAddresses(toAddresses);
      }

      if (!Test.isRunningTest()) {
        Messaging.sendEmail(emailMessages, true);
      }
    }
  }
}