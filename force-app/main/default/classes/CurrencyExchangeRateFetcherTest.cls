@IsTest
private class CurrencyExchangeRateFetcherTest {

  // Test the utility method for scheduling the fetch job.
  @IsTest
  static void testScheduleJob() {
    Fixer_Settings__c fixerSettings = new Fixer_Settings__c();
    fixerSettings.API_Key__c = '123';
    insert fixerSettings;

    String testCronExp = '0 0 17 * * ?';

    Map<String, HttpResponse> responseMap = new Map<String, HttpResponse>();

    String respBody = CurrencyExchangeRateTestHelper.getResponseString(null, null, null);
    
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    res.setStatusCode(200);
    res.setBody(respBody);
  
    responseMap.put('http://data.fixer.io/api/latest?access_key=123', res);
    
    HttpMock httpMock = new HttpMock(responseMap);
    
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, httpMock);
    String jobId = CurrencyExchangeRateFetchJob.schedule(
      'Currency Exchange Rate Fetch Job Unit Test',
      testCronExp
    );
    Test.stopTest();

    CronTrigger ct = [
      SELECT Id, CronExpression, TimesTriggered, NextFireTime
      FROM CronTrigger
      WHERE Id = :jobId
    ];

    System.assert(String.isNotBlank(jobId));
    System.assertEquals(testCronExp, ct.CronExpression);
    System.assertEquals(0, ct.TimesTriggered);
    System.assert(ct.NextFireTime != null);
  }

  // Test for code coverage and that an error was thrown if we do not have the api key. 
  @IsTest
  static void testExceptionApiKeyNotFound() {
    Boolean errorThrown = false;

    Test.startTest();
    try {
      new CurrencyExchangeRateFetcher().execute(null);
    } catch (Exception e) {
      errorThrown = true;
    }
    Test.stopTest();

    System.assertEquals(true, errorThrown);
  }

  // Test successful end to end test where the result is the Currency Exchange Rate record.
  @IsTest
  static void testSuccess() {
    Fixer_Settings__c fixerSettings = new Fixer_Settings__c();
    fixerSettings.API_Key__c = '123';
    insert fixerSettings;

    Map<String, HttpResponse> responseMap = new Map<String, HttpResponse>();

    String respBody = CurrencyExchangeRateTestHelper.getResponseString(null, null, null);
    
    HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setStatusCode(200);
      res.setBody(respBody);
    
      responseMap.put('http://data.fixer.io/api/latest?access_key=123', res);
    
    HttpMock httpMock = new HttpMock(responseMap);

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, httpMock);
    new CurrencyExchangeRateFetchJob().execute(null);
    Test.stopTest();

    List<Currency_Exchange_Rate__c> results = [
      SELECT API_Response__c, Base__c, Exchange_Rate_Collected_Date__c, Id
      FROM Currency_Exchange_Rate__c
    ];

    System.assertEquals(1, results.size());
    System.assertEquals(respBody, results[0].API_Response__c);
    System.assertEquals('EUR', results[0].Base__c);
    System.assertEquals(Date.today(), results[0].Exchange_Rate_Collected_Date__c);
  }

  @isTest 
  static void testGetForeignCurrencyTypes(){
    Test.startTest();
      List<String> res = CurrencyExchangeRateFetcher.getForeignCurrencyTypes();
    Test.stopTest();

    System.assertNotEquals(null, res);
    System.assertEquals(true, res.contains('USD'));
  }
}