@isTest
private class CurrencyExchangeRateMetadataUtilsTest {
  
  // Test successful end to end test where the result is the Currency Exchange Rate record.
  @IsTest (SeeAllData=true)
  static void testBuildMetadataContainer() {
    Map<String, Decimal> foreignRatesMap = new Map<String, Decimal>();
    foreignRatesMap.put('USD', 1.00);
    foreignRatesMap.put('CAD', 0.75);
    foreignRatesMap.put('GBP', 1.27);
    foreignRatesMap.put('EUR', 1.15);

    Test.startTest();
      Metadata.DeployContainer res = CurrencyExchangeRateMetadataUtils.buildContainer(foreignRatesMap);
    Test.stopTest();

    List<Metadata.Metadata> resList = res.getMetadata();
    Metadata.Metadata md = resList[0];

    System.assertEquals(1, resList.size());
    System.assertEquals('Current_Exchange_Rate.Today', md.fullName);
  }

  @isTest (SeeAllData=true)
  static void testUpdateCurrencyMetadata(){
    Map<String, Decimal> foreignRatesMap = new Map<String, Decimal>();
    foreignRatesMap.put('USD', 1.00);
    foreignRatesMap.put('CAD', 0.75);
    foreignRatesMap.put('GBP', 1.27);
    foreignRatesMap.put('EUR', 1.15);
    
    Test.startTest();
      CurrencyExchangeRateMetadataUtils.updateCurrencyExchangeRateMetadata(foreignRatesMap);
    Test.stopTest();
  }
  
  @isTest (SeeAllData=true)
  static void testHandleResult(){
    
    Test.startTest();
      CurrencyExchangeRateMetadataUtils.handleResult(new Metadata.DeployResult(), new Metadata.DeployCallbackContext());
    Test.stopTest();
  }
}