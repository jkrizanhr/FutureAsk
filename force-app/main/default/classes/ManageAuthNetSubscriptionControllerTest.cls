@isTest
private class ManageAuthNetSubscriptionControllerTest {
  @testSetup
  static void makeData() {
    ManageAuthNetServiceTest.setupCurrencyExchange();
    ManageAuthNetServiceTest.setupRecurringDonation();
    ManageAuthNetServiceTest.setupAuthService();
  }

  @isTest
  static void testFetchData() {
    npe03__Recurring_Donation__c rd = [
      SELECT Id
      FROM npe03__Recurring_Donation__c Id
      WHERE Name = 'Test Recurring Donation'
    ];

    List<HttpCalloutMock> responses = new List<HttpCalloutMock>();
    String getSubscriptionRes = '<?xml version="1.0" encoding="UTF-8"?><ARBGetSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><subscription><name>Sample subscription</name><paymentSchedule><interval><length>7</length><unit>days</unit></interval><startDate>2017-09-09</startDate><totalOccurrences>9999</totalOccurrences><trialOccurrences>1</trialOccurrences></paymentSchedule><amount>10.29</amount><trialAmount>1.00</trialAmount><status>active</status><profile><merchantCustomerId>973</merchantCustomerId><description>Profile description here</description><email>TestEmail5555@domain.com</email><customerProfileId>1812912918</customerProfileId><paymentProfile><customerType>individual</customerType><billTo><firstName>Arte</firstName><lastName>Johnson</lastName><company>test Co.</company><address>123 Test St.</address><city>Testville</city><state>AZ</state><zip>85282</zip><country>US</country></billTo><customerPaymentProfileId>1807515631</customerPaymentProfileId><payment><creditCard><cardNumber>XXXX1111</cardNumber><expirationDate>XXXX</expirationDate></creditCard></payment></paymentProfile><shippingProfile><firstName>Aaron</firstName><lastName>Wright</lastName><company>Testing, Inc.</company><address>123 Testing St.</address><city>Lehi</city><state>UT</state><zip>84043</zip><country>US</country><phoneNumber>520-254-5038</phoneNumber><customerAddressId>1811684122</customerAddressId></shippingProfile></profile><arbTransactions><arbTransaction><response>The credit card has expired.</response><submitTimeUTC>2017-09-14T18:40:31.247</submitTimeUTC><payNum>2</payNum><attemptNum>1</attemptNum></arbTransaction></arbTransactions></subscription></ARBGetSubscriptionResponse>';
    Map<String, String> headers = new Map<String, String>();
    AuthorizeNetServiceMock getSubscriptionResponse = new AuthorizeNetServiceMock(
      200,
      'Complete',
      getSubscriptionRes,
      headers
    );
    responses.add(getSubscriptionResponse);

    MultiRequestMock multiMock = new MultiRequestMock(responses);

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, multiMock);
    ManageAuthNetSubscriptionController.SubscriptionInfo subscriptionInfo = ManageAuthNetSubscriptionController.fetchData(
      rd.Id
    );
    Test.stopTest();
    System.assertEquals(10.29, subscriptionInfo.amount);
  }

  @isTest
  static void testUpdateAuthNetSubscription() {
    npe03__Recurring_Donation__c rd = [
      SELECT Id
      FROM npe03__Recurring_Donation__c Id
      WHERE Name = 'Test Recurring Donation'
    ];

    String subscriptionInfo = '{"id":"4818507","cardNumber":"XX0001","expirationMonth":"XX","expirationYear":"XX","amount":20,"selectedCurrency":"GBP","startDate":"2020-01-01","endDate":"2020-12-31","installmentPeriod":"Weekly","installmentFrequency":3}';

    //Three mocks: get subscription, cancel subscription, create subscription
    List<HttpCalloutMock> responses = new List<HttpCalloutMock>();
    Map<String, String> headers = new Map<String, String>();
    AuthorizeNetServiceMock getSubscriptionResponse = new AuthorizeNetServiceMock(
      200,
      'Complete',
      '<?xml version="1.0" encoding="UTF-8"?><ARBGetSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><subscription><name>Sample subscription</name><paymentSchedule><interval><length>7</length><unit>days</unit></interval><startDate>2017-09-09</startDate><totalOccurrences>9999</totalOccurrences><trialOccurrences>1</trialOccurrences></paymentSchedule><amount>10.29</amount><trialAmount>1.00</trialAmount><status>active</status><profile><merchantCustomerId>973</merchantCustomerId><description>Profile description here</description><email>TestEmail5555@domain.com</email><customerProfileId>1812912918</customerProfileId><paymentProfile><customerType>individual</customerType><billTo><firstName>Arte</firstName><lastName>Johnson</lastName><company>test Co.</company><address>123 Test St.</address><city>Testville</city><state>AZ</state><zip>85282</zip><country>US</country></billTo><customerPaymentProfileId>1807515631</customerPaymentProfileId><payment><creditCard><cardNumber>XXXX1111</cardNumber><expirationDate>XXXX</expirationDate></creditCard></payment></paymentProfile><shippingProfile><firstName>Aaron</firstName><lastName>Wright</lastName><company>Testing, Inc.</company><address>123 Testing St.</address><city>Lehi</city><state>UT</state><zip>84043</zip><country>US</country><phoneNumber>520-254-5038</phoneNumber><customerAddressId>1811684122</customerAddressId></shippingProfile></profile><arbTransactions><arbTransaction><response>The credit card has expired.</response><submitTimeUTC>2017-09-14T18:40:31.247</submitTimeUTC><payNum>2</payNum><attemptNum>1</attemptNum></arbTransaction></arbTransactions></subscription></ARBGetSubscriptionResponse>',
      headers
    );
    AuthorizeNetServiceMock cancelSubscriptionResponse = new AuthorizeNetServiceMock(
      200,
      'Complete',
      '<?xml version="1.0" encoding="utf-8"?><ARBCancelSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages></ARBCancelSubscriptionResponse>',
      headers
    );
    AuthorizeNetServiceMock createSubscriptionResponse = new AuthorizeNetServiceMock(
      200,
      'Complete',
      '<?xml version="1.0" encoding="utf-8"?><ARBCreateSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><subscriptionId>100748</subscriptionId><profile><customerProfileId>247150</customerProfileId><customerPaymentProfileId>215472</customerPaymentProfileId><customerAddressId>189691</customerAddressId></profile></ARBCreateSubscriptionResponse>',
      headers
    );
    responses.add(getSubscriptionResponse);
    responses.add(cancelSubscriptionResponse);
    responses.add(createSubscriptionResponse);

    MultiRequestMock multiMock = new MultiRequestMock(responses);
    Test.setMock(HttpCalloutMock.class, multiMock);

    Test.startTest();
    ManageAuthNetSubscriptionController.updateAuthNetSubscription(rd.Id, subscriptionInfo);
    Test.stopTest();

    npe03__Recurring_Donation__c updatedRd = [
      SELECT Id, Subscription_Id__c, npe03__Amount__c, Original_Amount__c, Original_Currency__c
      FROM npe03__Recurring_Donation__c Id
      WHERE Id = :rd.Id
    ];

    System.assertEquals('100748', updatedRd.Subscription_Id__c);
    System.assertEquals(25.81, updatedRd.npe03__Amount__c);
    System.assertEquals(20, updatedRd.Original_Amount__c);
    System.assertEquals('GBP', updatedRd.Original_Currency__c);
  }

  @isTest
  static void testUpdateAuthNetPaymentMethod() {
    npe03__Recurring_Donation__c rd = [
      SELECT Id
      FROM npe03__Recurring_Donation__c Id
      WHERE Name = 'Test Recurring Donation'
    ];

    String subscriptionInfo = '{"id":"4818507","cardNumber":"XX0001","expirationMonth":"XX","expirationYear":"XX","amount":100,"startDate":"2020-01-01","endDate":"2020-12-31","installmentPeriod":"Weekly","installmentFrequency":3}';

    //two mocks: get subscription, cancel subscription, create subscription
    List<HttpCalloutMock> responses = new List<HttpCalloutMock>();
    Map<String, String> headers = new Map<String, String>();
    AuthorizeNetServiceMock getSubscriptionResponse = new AuthorizeNetServiceMock(
      200,
      'Complete',
      '<?xml version="1.0" encoding="UTF-8"?><ARBGetSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><subscription><name>Sample subscription</name><paymentSchedule><interval><length>7</length><unit>days</unit></interval><startDate>2017-09-09</startDate><totalOccurrences>9999</totalOccurrences><trialOccurrences>1</trialOccurrences></paymentSchedule><amount>10.29</amount><trialAmount>1.00</trialAmount><status>active</status><profile><merchantCustomerId>973</merchantCustomerId><description>Profile description here</description><email>TestEmail5555@domain.com</email><customerProfileId>1812912918</customerProfileId><paymentProfile><customerType>individual</customerType><billTo><firstName>Arte</firstName><lastName>Johnson</lastName><company>test Co.</company><address>123 Test St.</address><city>Testville</city><state>AZ</state><zip>85282</zip><country>US</country></billTo><customerPaymentProfileId>1807515631</customerPaymentProfileId><payment><creditCard><cardNumber>XXXX1111</cardNumber><expirationDate>XXXX</expirationDate></creditCard></payment></paymentProfile><shippingProfile><firstName>Aaron</firstName><lastName>Wright</lastName><company>Testing, Inc.</company><address>123 Testing St.</address><city>Lehi</city><state>UT</state><zip>84043</zip><country>US</country><phoneNumber>520-254-5038</phoneNumber><customerAddressId>1811684122</customerAddressId></shippingProfile></profile><arbTransactions><arbTransaction><response>The credit card has expired.</response><submitTimeUTC>2017-09-14T18:40:31.247</submitTimeUTC><payNum>2</payNum><attemptNum>1</attemptNum></arbTransaction></arbTransactions></subscription></ARBGetSubscriptionResponse>',
      headers
    );
    AuthorizeNetServiceMock updateCustomerPaymentProfileResponse = new AuthorizeNetServiceMock(
      200,
      'Complete',
      '<?xml version="1.0" encoding="utf-8"?><updateCustomerPaymentProfileResponse xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><validationDirectResponse>1,1,1,This transaction has been approved.,000000,Y,2000000000,none,Test transaction for ValidateCustomerPaymentProfile.,0.00,CC,auth_only,none,John,Doe,,123 Main St.,Bellevue,WA,98004,USA,000-000-0000,,email@example.com,,,,,,,,,0.00,0.00,0.00,FALSE,none,E42C2F81807AA1B581DEA12EB6727604,P,2,,,,,,,,,,,XXXX1111,Visa,,,,,,,,,,,,,,,,,</validationDirectResponse></updateCustomerPaymentProfileResponse>',
      headers
    );
    responses.add(getSubscriptionResponse);
    responses.add(updateCustomerPaymentProfileResponse);

    MultiRequestMock multiMock = new MultiRequestMock(responses);
    Test.setMock(HttpCalloutMock.class, multiMock);

    //Set up paymentInfo
    Map<String, String> paymentInfo = new Map<String, String>();
    paymentInfo.put('cardNumber', '4242424242424242');
    paymentInfo.put('cvv', '123');
    paymentInfo.put('selectedMonth', '1');
    paymentInfo.put('selectedYear', '2022');
    Test.startTest();
    ManageAuthNetSubscriptionController.updateAuthNetPaymentMethod(
      rd.Id,
      subscriptionInfo,
      paymentInfo
    );
    Test.stopTest();
    npe03__Recurring_Donation__c updatedRd = [
      SELECT
        Id,
        Credit_Card_Expiration_Month__c,
        Credit_Card_Expiration_Year__c,
        Credit_Card_Last_4__c
      FROM npe03__Recurring_Donation__c Id
      WHERE Name = 'Test Recurring Donation'
    ];
    System.assertEquals('1', updatedRd.Credit_Card_Expiration_Month__c);
    System.assertEquals('22', updatedRd.Credit_Card_Expiration_Year__c);
    System.assertEquals('4242', updatedRd.Credit_Card_Last_4__c);
  }

  @isTest
  static void testCancelAuthNetSubscription() {
    npe03__Recurring_Donation__c rd = [
      SELECT Id
      FROM npe03__Recurring_Donation__c Id
      WHERE Name = 'Test Recurring Donation'
    ];

    String subscriptionInfo = '{"id":"4818507","cardNumber":"XX0001","expirationMonth":"XX","expirationYear":"XX","amount":100,"startDate":"2020-01-01","endDate":"2020-12-31","installmentPeriod":"Weekly","installmentFrequency":3}';

    //Create callout mock for refund
    List<HttpCalloutMock> responses = new List<HttpCalloutMock>();
    String cancelRes = '<?xml version="1.0" encoding="utf-8"?><ARBCancelSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages></ARBCancelSubscriptionResponse>';
    Map<String, String> headers = new Map<String, String>();
    AuthorizeNetServiceMock cancelSubscriptionResponse = new AuthorizeNetServiceMock(
      200,
      'Complete',
      cancelRes,
      headers
    );
    responses.add(cancelSubscriptionResponse);

    MultiRequestMock multiMock = new MultiRequestMock(responses);
    Test.setMock(HttpCalloutMock.class, multiMock);

    //Cancel
    Test.startTest();
    ManageAuthNetSubscriptionController.cancelAuthNetSubscription(rd.Id, subscriptionInfo);
    Test.stopTest();
  }
}