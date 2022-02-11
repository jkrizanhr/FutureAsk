trigger GPExportBundleTrigger on GP_Export_Bundle__c(after insert, before update) {
  new GPExportBundleTriggerHandler().run();
}