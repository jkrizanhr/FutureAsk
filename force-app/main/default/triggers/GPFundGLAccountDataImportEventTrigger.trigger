trigger GPFundGLAccountDataImportEventTrigger on GP_Fund_GL_Account_Data_Import_Event__e(
  after insert
) {
  Integer batchSize = GPDataImportHelper.getBatchSize('GP_Fund_GL_Account_Data_Import_Event__e');
  Integer counter = 0;
  List<Platform_Event_Error__c> eventErrors = new List<Platform_Event_Error__c>();

  // Iterate over the platform events from Trigger.new
  for (GP_Fund_GL_Account_Data_Import_Event__e event : Trigger.new) {
    // Increase batch counter.
    counter++;
    if (counter > batchSize) {
      // Resume after the last successfully processed event after the trigger stops running.
      // Exit for loop.
      break;
    }

    // Set the savepoint
    SavePoint sp = Database.setSavepoint();

    try {
      // Import the data
      new GPFundGLAccountDataImportService(event).run();
    } catch (Exception e) {
      // ERROR! Rollback the database and create a platform event error record.
      Database.rollback(sp);
      Platform_Event_Error__c eventError = new Platform_Event_Error__c();
      eventError.Data__c = event.Data__c;
      eventError.Origin__c = 'AAG00201';
      eventError.Error__c = e.getMessage() + '\n' + e.getStackTraceString();
      eventErrors.add(eventError);
    }

    // Set Replay ID after which to resume event processing in a new trigger execution.
    EventBus.TriggerContext.currentContext().setResumeCheckpoint(event.ReplayId);
  }

  if (!eventErrors.isEmpty()) {
    Database.insert(eventErrors, false);
  }
}