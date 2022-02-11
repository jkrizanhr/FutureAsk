public class GPExportBundleJob implements Database.Batchable<SObject> {
  private Id bundleId;

  public GPExportBundleJob(Id bundleId) {
    this.bundleId = bundleId;
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(
      [
        SELECT Date__c, GP_Export_Error__c, Id, Name, Type__c
        FROM Cash_Batch__c
        WHERE GP_Export_Bundle__c = :this.bundleId
      ]
    );
  }

  public void execute(Database.BatchableContext bc, List<Cash_Batch__c> batches) {
    // NOTE: The batch size for this job should be 1
    new GPExportBundleService(this.bundleId, batches[0]).run();
  }

  public void finish(Database.BatchableContext bc) {
    List<GP_Export_Bundle__c> bundles = [
      SELECT Fund_GL_Error_Message__c, Fund_GL_Validation_Check__c, Id
      FROM GP_Export_Bundle__c
      WHERE Id = :bundleId
    ];

    if (!bundles.isEmpty()) {
      if (String.isBlank(bundles[0].Fund_GL_Error_Message__c)) {
        bundles[0].Fund_GL_Validation_Check__c = 'Check Transaction Numbers';
      }

      bundles[0].Apex_Job_Completed__c = true;

      update bundles;
    }
  }
}