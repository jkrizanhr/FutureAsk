public inherited sharing class CurrencyExchangeRateFetcher implements Database.AllowsCallouts, System.Queueable {

  // Class instance variables.
  private static final String BASE_URL = 'http://data.fixer.io/api/latest';
  private String url;

  // Custom exception class for throwing errors.
  public class CurrencyExchangeRateFetcherException extends Exception {}

  // Main method for calling out using the http request to retrieve the currency exchange rate data
  // and then saving the results to a Currency Exchange Rate record.
  public void execute(System.QueueableContext qc) {
    // Get the API key from the Custom Setting
    Fixer_Settings__c fixerSettings = Fixer_Settings__c.getOrgDefaults();
    if (fixerSettings == null || String.isBlank(fixerSettings.API_Key__c)) {
      // Throw exception
      throw new CurrencyExchangeRateFetcherException('Fixer API Key not found.');
    }

    // Build URL endpoint
    this.url = BASE_URL + '?access_key=' + fixerSettings.API_Key__c;

    // Callout to fixer.io API
    HttpResponse res = this.sendRequest();

    // Handle the response
    String respBody = res.getBody();
    Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(respBody);

    if (resultMap.get('success') != null && (Boolean) resultMap.get('success') != true) {
      throw new CurrencyExchangeRateFetcherException(
        'Failed to retrieve the currency exchange rate data.'
      );
    }

    // Save results to a new Currency Exchange Rate record
    Currency_Exchange_Rate__c currencyExchangeRate = createCurrencyExchangeRateRecord(resultMap, respBody);
    insert currencyExchangeRate;

    // Update the Custom Metadata Records
    updateMetadataRecords(resultMap);
  }

  // Send GET http request using the class instance variable "url".
  private HttpResponse sendRequest() {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(this.url);
    req.setMethod('GET');
    req.setTimeout(30000);
    Http http = new Http();
    return http.send(req);
  }

  // Get Currency Options dynamically from the Currency Options picklist on the Currency Exchange Rate object
  public static List<String> getForeignCurrencyTypes(){
    List<String> foreignRates = new List<String>();
    Schema.SObjectType sObjType = Schema.getGlobalDescribe().get('User');
    Schema.DescribeSObjectResult res = sObjType.getDescribe();
    Map<String, Schema.SobjectField> fields = res.fields.getMap();
    Schema.DescribeFieldResult fieldResult = fields.get('Currency_Preference__c').getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for (Schema.PicklistEntry pe : ple){
      if (pe.isActive()){
        foreignRates.add(pe.getValue().substring(0, 3));
      }
    }
    return foreignRates;
  }

  // Handle Creating Currency Exchange Rate record and updating the metadata
  private Currency_Exchange_Rate__c createCurrencyExchangeRateRecord(Map<String, Object> resultMap, String respBody){
    // Create Currency Exchange Rate Record
    Currency_Exchange_Rate__c currencyExchangeRate = new Currency_Exchange_Rate__c();
    if (resultMap.get('base') != null) {
      currencyExchangeRate.Base__c = (String) resultMap.get('base');
    }
    if (resultMap.get('date') != null) {
      String dte = (String) resultMap.get('date');
      currencyExchangeRate.Exchange_Rate_Collected_Date__c = Date.valueOf(dte);
    }
    currencyExchangeRate.Api_Response__c = respBody;
    return currencyExchangeRate;
  }

  private void updateMetadataRecords(Map<String, Object> resultMap){
    // Update the Metadata Records with today's exchange rates
    List<String> foreignRates = getForeignCurrencyTypes();
    Map<String, Object> ratesMap = (Map<String, Object>) resultMap.get('rates');
    Map<String, Decimal> foreignRatesMap = new Map<String, Decimal>();

    for (String fr : foreignRates){
      String field = fr + '__c';
      Decimal rate = ((1 / (Decimal)ratesMap.get(fr)) * (Decimal)ratesMap.get('USD')).setScale(6, RoundingMode.HALF_UP);
      foreignRatesMap.put(field, rate);
    }  
    if (!Test.isRunningTest()){
      System.enqueueJob(new CurrencyExchangeRateMetadataUtils(foreignRatesMap));
    }
  }
}