public class CurrencyExchangeRateCalculator {

  // Class instance variables.
  private Currency_Exchange_Rate__c currencyExchangeRate;
  private Map<String, Decimal> exchangeRateMap;

  // Custom exception class for throwing errors.
  public class CurrencyExchangeRateCalculatorException extends Exception {}

  // Constructor
  public CurrencyExchangeRateCalculator() {
    this.exchangeRateMap = new Map<String, Decimal>();
    this.loadCurrencyExchangeRates();
    this.buildExchangeRatesMap();
  }

  // Retrieve the most recent currency exchange rate record. 
  private void loadCurrencyExchangeRates() {
    List<Currency_Exchange_Rate__c> currencyExchangeRates = [
      SELECT Api_Response__c, Id
      FROM Currency_Exchange_Rate__c
      WHERE Base__c = 'EUR'
      ORDER BY Exchange_Rate_Collected_Date__c DESC, CreatedDate DESC
      LIMIT 1
    ];

    System.debug(currencyExchangeRates);

    if (currencyExchangeRates.isEmpty()) {
      // Throw exception
      throw new CurrencyExchangeRateCalculatorException(
        'CurrencyExchangeRateCalculator :: loadCurrencyExchangeRates :: Currency Exchange Rate Record not found.'
      );
    }

    this.currencyExchangeRate = currencyExchangeRates[0];
  }

  // Build a map of currency types to the exchange rate using the currency exchange rate record.
  private void buildExchangeRatesMap() {
    Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(
      this.currencyExchangeRate.Api_Response__c
    );

    Map<String, Object> rates = (Map<String, Object>) resultMap.get('rates');

    for (String key : rates.keySet()) {
      this.exchangeRateMap.put(key, (Decimal) rates.get(key));
    }
  }

  // Generic conversion of SObjects with Original_Amount__c, and Original_Currency__c fields.
      // USD - US Dollars
      // GBP - British Pounds
      // EUR - Euros
      // INR - Indian Rupees
      // KES - Kenyan Shillings
      // CAD - Canadian Dollars
  public List<SObject> handleBulkConversion(List<SObject> sObjects, String amountFieldName, String originalAmountFieldName) {
    for (SObject sObj : sObjects) {
      String currencyType = (String) sObj.get('Original_Currency__c');
      Decimal amount = 0;
      if (originalAmountFieldName != null){
        amount = sObj.get(originalAmountFieldName) != null 
            ? (Decimal) sObj.get(originalAmountFieldName) 
            : 0;
      } else {
        amount = sObj.get('Original_Amount__c') != null 
            ? (Decimal) sObj.get('Original_Amount__c') 
            : 0;
      }

      Set<String> validCurrencyTypes = new Set<String>{'AED','AFN','ALL','AMD','ANG','AOA','ARS','AUD','AWG','AZN','BAM','BBD','BDT','BGN','BHD','BIF','BMD','BND','BOB','BRL','BSD','BTC','BTN','BWP','BYN','BYR','BZD','CAD','CDF','CHF','CLF','CLP','CNY','COP','CRC','CUC','CUP','CVE','CZK','DJF','DKK','DOP','DZD','EGP','ERN','ETB','EUR','FJD','FKP','GBP','GEL','GGP','GHS','GIP','GMD','GNF','GTQ','GYD','HKD','HNL','HRK','HTG','HUF','IDR','ILS','IMP','INR','IQD','IRR','ISK','JEP','JMD','JOD','JPY','KES','KGS','KHR','KMF','KPW','KRW','KWD','KYD','KZT','LAK','LBP','LKR','LRD','LSL','LTL','LVL','LYD','MAD','MDL','MGA','MKD','MMK','MNT','MOP','MRO','MUR','MVR','MWK','MXN','MYR','MZN','NAD','NGN','NIO','NOK','NPR','NZD','OMR','PAB','PEN','PGK','PHP','PKR','PLN','PYG','QAR','RON','RSD','RUB','RWF','SAR','SBD','SCR','SDG','SEK','SGD','SHP','SLL','SOS','SRD','STD','SVC','SYP','SZL','THB','TJS','TMT','TND','TOP','TRY','TTD','TWD','TZS','UAH','UGX','USD','UYU','UZS','VEF','VND','VUV','WST','XAF','XAG','XAU','XCD','XDR','XOF','XPF','YER','ZAR','ZMK','ZMW','ZWL'};

      if (currencyType == 'USD'){
        sObj.put(amountFieldName, amount);
      } else if (validCurrencyTypes.contains(currencyType)){
        Decimal convertedAmount = this.convert(currencyType, 'USD', amount);
        sObj.put(amountFieldName, convertedAmount);
      } else {
        sObj.put(amountFieldName, 0);
      }
      
    }
    return sObjects;
  }

  // Method to convert currencies for a given source currency type, target currency type, 
  // and the source currency type's amount.
  // NOTES:
  //   - We will need to translate from GBP/INR/EUR/KES -> EUR -> USD 
  //   - Formula: 
  //     USD_Amount = (Opportunity.Original_Amount__c / Foreign_Rate) * USD_Rate
  //   - Rounding Half Up even though the Salesfore UI rounds currency fields automatically, 
  //   it will still be a decimal past 2 places if you were to query the field in soql.
  public Decimal convert(String srcCurrency, String targetCurrency, Decimal amount) {
    Decimal srcRate = this.exchangeRateMap.get(srcCurrency);
    Decimal targetRate = this.exchangeRateMap.get(targetCurrency);

    if (srcRate == null || targetRate == null) {
      // Throw exception
      throw new CurrencyExchangeRateCalculatorException(
        'CurrencyExchangeRateCalculator :: convert :: currency type not found.'
      );
    } else if (srcRate <= 0 || targetRate <= 0) {
      // Throw exception
      throw new CurrencyExchangeRateCalculatorException(
        'CurrencyExchangeRateCalculator :: convert :: currency rate is invalid.'
      );
    }

    Decimal result = (amount / srcRate) * targetRate;
    result = result.setScale(2, RoundingMode.HALF_UP);

    return result;
  }
}