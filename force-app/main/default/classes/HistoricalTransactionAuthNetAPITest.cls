@isTest
private class HistoricalTransactionAuthNetAPITest {
  // public static HT_Auth_Net_Setting__mdt createSettings() {
  //   HT_Auth_Net_Setting__mdt authNetSettings = new HT_Auth_Net_Setting__mdt();
  //   authNetSettings.Name = 'Sandbox';
  //   authNetSettings.Login_ID__c = 'test';
  //   authNetSettings.Transaction_Key__c = 'test';
  //   insert authNetSettings;
  //   return authNetSettings;
  // }

  @isTest
  static void testGetTransactionList() {
    // HT_Auth_Net_Setting__mdt authNetSettings = createSettings();

    String response = '<?xml version="1.0" encoding="utf-8"?><getTransactionListResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactions><transaction><transId>12345</transId><submitTimeUTC>2009-05-30T09:00:00</submitTimeUTC><submitTimeLocal>2009-05-30T04:00:00</submitTimeLocal><transactionStatus>settledSuccessfully</transactionStatus><invoice>INV00001</invoice><firstName>John</firstName><lastName>Doe</lastName><amount>2.00</amount><accountType>Visa</accountType><accountNumber>XXXX1111</accountNumber><settleAmount>2.00</settleAmount><subscription><id>145521</id><payNum>1</payNum></subscription></transaction><transaction><transId>12345</transId><submitTimeUTC>2009-05-30T09:00:00</submitTimeUTC><submitTimeLocal>2009-05-30T04:00:00</submitTimeLocal><transactionStatus>settledSuccessfully</transactionStatus><invoice>INV00001</invoice><firstName>John</firstName><lastName>Doe</lastName><settleAmount>2.00</settleAmount><accountType>Visa</accountType><accountNumber>XXXX1111</accountNumber><marketType>eCommerce</marketType><product>Card Not Present</product><mobileDeviceId>2354578983274523978</mobileDeviceId></transaction></transactions></getTransactionListResponse>';
    Map<String, String> headers = new Map<String, String>{
      'Content-Type' => 'text/xml'
    };
    HistoricalTransactionRequestMock mockResponse = new HistoricalTransactionRequestMock(
      200,
      'Complete',
      response,
      headers
    );
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();

    HistoricalTransactionAuthNetAPI api = new HistoricalTransactionAuthNetAPI();
    api.setMode('Sandbox');
    api.authenticate();
    api.getTransactions(Datetime.now(), Datetime.now(), null, 100);
    List<Historical_Transaction__c> transactions = api.getTransactionList(
      '43214321'
    );
    System.assertNotEquals(null, transactions);
    System.assertEquals(2, transactions.size());

    Test.stopTest();
  }

  @isTest
  static void testGetTransactionsError() {
    // HT_Auth_Net_Setting__mdt authNetSettings = createSettings();

    String response = '<?xml version="1.0" encoding="utf-8"?><getTransactionListResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Error</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactions><transaction><transId>12345</transId><submitTimeUTC>2009-05-30T09:00:00</submitTimeUTC><submitTimeLocal>2009-05-30T04:00:00</submitTimeLocal><transactionStatus>settledSuccessfully</transactionStatus><invoice>INV00001</invoice><firstName>John</firstName><lastName>Doe</lastName><amount>2.00</amount><accountType>Visa</accountType><accountNumber>XXXX1111</accountNumber><settleAmount>2.00</settleAmount><subscription><id>145521</id><payNum>1</payNum></subscription></transaction><transaction><transId>12345</transId><submitTimeUTC>2009-05-30T09:00:00</submitTimeUTC><submitTimeLocal>2009-05-30T04:00:00</submitTimeLocal><transactionStatus>settledSuccessfully</transactionStatus><invoice>INV00001</invoice><firstName>John</firstName><lastName>Doe</lastName><settleAmount>2.00</settleAmount><accountType>Visa</accountType><accountNumber>XXXX1111</accountNumber><marketType>eCommerce</marketType><product>Card Not Present</product><mobileDeviceId>2354578983274523978</mobileDeviceId></transaction></transactions></getTransactionListResponse>';
    Map<String, String> headers = new Map<String, String>{
      'Content-Type' => 'text/xml'
    };
    HistoricalTransactionRequestMock mockResponse = new HistoricalTransactionRequestMock(
      200,
      'Complete',
      response,
      headers
    );
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();

    HistoricalTransactionAuthNetAPI api = new HistoricalTransactionAuthNetAPI();
    api.setMode('Sandbox');
    api.authenticate();
    api.getTransactions(Datetime.now(), Datetime.now(), null, 100);

    Test.stopTest();
  }

  @isTest
  static void testCompleteTransactionDetails() {
    // HT_Auth_Net_Setting__mdt authNetSettings = createSettings();

    String response = '<?xml version="1.0" encoding="utf-8"?><getTransactionDetailsResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transaction><transId>7849230028</transId><submitTimeUTC>2016-01-01T09:19:50.047Z</submitTimeUTC><submitTimeLocal>2016-01-01T02:19:50.047</submitTimeLocal><transactionType>authCaptureTransaction</transactionType><transactionStatus>settledSuccessfully</transactionStatus><responseCode>1</responseCode><responseReasonCode>1</responseReasonCode><subscription><id>16806161</id><payNum>32</payNum></subscription><responseReasonDescription>Approval</responseReasonDescription><authCode>095040</authCode><AVSResponse>G</AVSResponse><batch><batchId>351737111</batchId><settlementTimeUTC>2016-01-01T23:25:05.473Z</settlementTimeUTC><settlementTimeLocal>2016-01-01T16:25:05.473</settlementTimeLocal><settlementState>settledSuccessfully</settlementState></batch><authAmount>50.00</authAmount><settleAmount>50.00</settleAmount><taxExempt>false</taxExempt><payment><creditCard><cardNumber>XXXX</cardNumber><expirationDate>XXXX</expirationDate><cardType>Visa</cardType></creditCard></payment><billTo><firstName>Test</firstName><lastName>Test</lastName><address>123 Main St.</address><city>Harrisburg</city><state>PA</state><zip>17101</zip><country>USA</country><email>test@test.com</email><phoneNumber>1234567890</phoneNumber></billTo><recurringBilling>true</recurringBilling><product>Card Not Present</product><marketType>MOTO</marketType></transaction></getTransactionDetailsResponse>';
    Map<String, String> headers = new Map<String, String>{
      'Content-Type' => 'text/xml'
    };
    HistoricalTransactionRequestMock mockResponse = new HistoricalTransactionRequestMock(
      200,
      'Complete',
      response,
      headers
    );
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Historical_Transaction__c ht = new Historical_Transaction__c();
    ht.Transaction_Id__c = '8V079861VC3005741';
    insert ht;

    Test.startTest();

    HistoricalTransactionAuthNetAPI api = new HistoricalTransactionAuthNetAPI();
    api.authenticate();
    ht = api.completeTransactionDetails(ht);
    System.assertEquals('123 Main St.', ht.Billing_Street__c);

    Test.stopTest();
  }
}