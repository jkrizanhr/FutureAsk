public with sharing class CurrencyExchangeRateMetadataUtils implements System.Queueable, Metadata.DeployCallback {
  
  Map<String, Decimal> foreignRatesMap;

  public CurrencyExchangeRateMetadataUtils(){}

  public CurrencyExchangeRateMetadataUtils(Map<String, Decimal> foreignRatesMap){
    this.foreignRatesMap = foreignRatesMap;
  }

  public void execute(System.QueueableContext qc) {
    updateCurrencyExchangeRateMetadata(foreignRatesMap);
  }

  /* Below method recieves the 2 parameters - needed for metadata deployment results
    1 - Metadata.DeployResult => Object of MetadataContainer class where this method has been implemented.
    2 - Metadata.DeployCallbackContext => Object of the class where this method has been implemented
  */
  public static void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
    if (result.status == Metadata.DeployStatus.Succeeded) {
      // Deployment was successful
    } else {
      // Deployment was not successful
    }
  }

  /* Build and return container - separate method to allow for code coverage */
  public static Metadata.DeployContainer buildContainer(Map<String, Decimal> foreignRatesMap){
    Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
    customMetadata.fullName = 'Current_Exchange_Rate.Today';
    customMetadata.label = 'Today';
    
    /* Create the Object of CustomMetadataValue */
    for (String label : foreignRatesMap.keySet()){
      Decimal value = foreignRatesMap.get(label);
      
      Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
      customField.field = label;
      customField.value = value;
      customMetadata.values.add(customField);
    }

    Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
    mdContainer.addMetadata(customMetadata);

    return mdContainer;
  }

  /* Main method: Calls buildContainer then runs the update */
  public static void updateCurrencyExchangeRateMetadata(Map<String, Decimal> foreignRatesMap){
    Metadata.DeployContainer mdContainer = buildContainer(foreignRatesMap);
    CurrencyExchangeRateMetadataUtils callback = new CurrencyExchangeRateMetadataUtils();
    if (!Test.isRunningTest()){
      Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
    }
  }
}