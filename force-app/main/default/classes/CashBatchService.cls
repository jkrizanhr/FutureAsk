public inherited sharing class CashBatchService {
  
  // Trigger Context: Before Insert. Also used as a utility method.
  public static void handleCurrencyConversion(List<Cash_Batch__c> batches) {
    // Initialize the calculator class because we are assuming that the Original_Currency__c field is populated.
    CurrencyExchangeRateCalculator calculator = new CurrencyExchangeRateCalculator();
    batches = (List<Cash_Batch__c>) calculator.handleBulkConversion(batches, 'Control_Batch_Total__c', 'Original_Control_Batch_Total__c');
  }

  // Trigger Context: Before Update.
  // Convert currencies if Amount, Original_Control_Batch_Total__c, or Original_Currency__c field has changed.
  public static void handleCurrencyConversionBeforeUpdate(List<Cash_Batch__c> newBatches, Map<Id, Cash_Batch__c> oldBatchMap) {
    List<Cash_Batch__c> batchesToConvert = new List<Cash_Batch__c>();

    // Determine if there are batches to convert so that we don't have to waste a soql query when
    // initalizing the CurrencyExchangeRateCalculator
    for (Cash_Batch__c newBatch : newBatches) {
      if (String.isBlank(newBatch.Original_Currency__c)) {
        newBatch.Control_Batch_Total__c = 0;
      } else {
        Cash_Batch__c oldBatch = oldBatchMap.get(newBatch.Id);
        if (oldBatch.Original_Control_Batch_Total__c != newBatch.Original_Control_Batch_Total__c ||
          oldBatch.Original_Currency__c != newBatch.Original_Currency__c
        ) {
          // Before Update, field changed
          batchesToConvert.add(newBatch);
        }
      }
    }

    if (!batchesToConvert.isEmpty()) {
      handleCurrencyConversion(batchesToConvert);
    }
  }
  
  public static void ensureBatchIsEditable(List<Cash_Batch__c> batches, Map<Id, Cash_Batch__c> oldMap) {
    // Make it so only certain fields get locked when the batch is locked.
    // - Date
    // - Opportunity Type
    // - Batch Variation
    // - Type
    // - Original Currency
    // - Original Control Batch Total
    // - Control batch total
    // - Control batch size
    for (Cash_Batch__c batch : batches) {
      if (oldMap != null && oldMap.containsKey(batch.Id)) {
        Cash_Batch__c oldBatch = oldMap.get(batch.Id);
        if (batch.Is_Locked__c == true) {
          if (
            oldBatch.Date__c != batch.Date__c ||
            oldBatch.Opportunity_Type__c != batch.Opportunity_Type__c ||
            oldBatch.Batch_Variation__c != batch.Batch_Variation__c ||
            oldBatch.Type__c != batch.Type__c ||
            oldBatch.Original_Currency__c != batch.Original_Currency__c ||
            oldBatch.Original_Control_Batch_Total__c != batch.Original_Control_Batch_Total__c ||
            oldBatch.Control_Batch_Total__c != batch.Control_Batch_Total__c ||
            oldBatch.Control_Batch_Size__c != batch.Control_Batch_Size__c
            ) {
            batch.addError('The following fields cannot edited if the Batch is locked: Date, Opportunity Type, Batch Variation, Type, Original Currency, Original Control Batch Total, Control Batch Total and Control Batch Size.');
          }
        } else if (oldBatch.Status__c == 'Under Review' && batch.Status__c == 'New') {
          batch.addError('Under Review Batches can not be moved back to New status.');
        }
      }
    }
  }

  public static void ensureBatchConfigurationIsUnique(List<Cash_Batch__c> batches) {
    Set<String> batchVariationList = new Set<String>();
    Set<Date> batchDateList = new Set<Date>();
    for (Cash_Batch__c batch : batches) {
      batchVariationList.add(batch.Batch_Variation__c);
      batchDateList.add(batch.Date__c);
    }
    List<Cash_Batch__c> batchesToCheck = [
      SELECT 
        Id, Date__c, Batch_Variation__c, Type__c, Original_Currency__c, Region_Category__c
      FROM Cash_Batch__c
      WHERE 
        Status__c = 'New'
        AND Batch_Variation__c IN :batchVariationList
        AND Date__c IN :batchDateList
    ];
    if (!batchesToCheck.isEmpty()) {
      for (Cash_Batch__c batch : batches) {
        for (Cash_Batch__c checkBatch : batchesToCheck) {
          if (
            batch.Id != checkBatch.Id &&
            batch.Type__c == checkBatch.Type__c &&
            batch.Batch_Variation__c == checkBatch.Batch_Variation__c &&
            batch.Original_Currency__c == checkBatch.Original_Currency__c &&
            batch.Date__c == checkBatch.Date__c &&
            batch.Region_Category__c == checkBatch.Region_Category__c
          ) {
            batch.addError('There is already an open Batch with this Date, Type, Batch Variation, Region and Original Currency.');
          }
        }
      }
    }
  }

  public static void setApprovedByOnBatch(List<Cash_Batch__c> batches, Map<Id, Cash_Batch__c> oldMap) {
    // Indicate who approved the batch.
    for (Cash_Batch__c batch : batches) {
      if (oldMap != null && oldMap.containsKey(batch.Id)) {
        Cash_Batch__c oldBatch = oldMap.get(batch.Id);
        if (batch.Status__c != oldBatch.Status__c && batch.Status__c == 'Approved') {
          batch.Approved_by__c = UserInfo.getUserId();
          batch.Approved_Date__c = Date.today();
        }
      }
    }
  }
}