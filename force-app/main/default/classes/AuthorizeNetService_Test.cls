@isTest
private class AuthorizeNetService_Test {

  static AuthorizeNetService ans = new AuthorizeNetService('123', '123', true);
  static AuthorizeNetModels.merchantAuthenticationType merchantAuth =
      new AuthorizeNetModels.merchantAuthenticationType('name','transactionKey');

  @isTest static void testCreateTransaction() {
    AuthorizeNetModels.creditCardType creditCard = new AuthorizeNetModels.creditCardType();
    creditCard.cardCode = '123';
    creditCard.cardNumber = '1234123412341234';
    creditCard.expirationDate = '2020-05';

    AuthorizeNetModels.paymentType payment = new AuthorizeNetModels.paymentType();
    payment.creditCard = creditCard;

    AuthorizeNetModels.orderType order = new AuthorizeNetModels.orderType();
    order.invoiceNumber = '123';
    order.description = '123';

    List<AuthorizeNetModels.lineItemType> lineItems = new List<AuthorizeNetModels.lineItemType>();
    AuthorizeNetModels.lineItemType lineItem = new AuthorizeNetModels.lineItemType();
    lineItem.itemId = '123';
    lineItem.name = '123';
    lineItem.description = '123';
    lineItem.quantity = 123;
    lineItem.unitPrice = 10.00;
    lineItems.add(lineItem);

    AuthorizeNetModels.extendedAmountType tax = new AuthorizeNetModels.extendedAmountType();
    tax.name = '123';
    tax.description = '123';
    tax.amount = 10.00;

    AuthorizeNetModels.extendedAmountType duty = new AuthorizeNetModels.extendedAmountType();
    duty.name = '123';
    duty.description = '123';
    duty.amount = 10.00;

    AuthorizeNetModels.extendedAmountType shipping = new AuthorizeNetModels.extendedAmountType();
    shipping.name = '123';
    shipping.description = '123';
    shipping.amount = 10.00;

    AuthorizeNetModels.customerType customer = new AuthorizeNetModels.customerType();
    customer.id = '123';

    AuthorizeNetModels.addressType address = new AuthorizeNetModels.addressType();
    address.firstName = '123';
    address.lastName = '123';
    address.company = '123';
    address.address = '123';
    address.city = '123';
    address.state = '123';
    address.zip = '123';
    address.country = '123';

    AuthorizeNetModels.transactionRequestType tr = new AuthorizeNetModels.transactionRequestType();
    tr.transactionType = 'authCaptureTransaction';
    tr.amount = 10.00;
    tr.payment = payment;
    tr.order = order;
    tr.lineItems = lineItems;
    tr.tax = tax;
    tr.duty = duty;
    tr.shipping = shipping;
    tr.poNumber = '123';
    tr.customer = customer;
    tr.billTo = address;
    tr.shipTo = address;
    tr.customerIP = '123';

    AuthorizeNetModels.solutionType solution = new AuthorizeNetModels.solutionType();
    solution.id = '123';
    solution.name = 'test';
    solution.vendorName = 'test';
    tr.solution = solution;

    AuthorizeNetModels.transRetailInfoType retail = new AuthorizeNetModels.transRetailInfoType();
    retail.customerSignature = 'test';
    retail.deviceType = 'test';
    retail.marketType = 'test';
    tr.retail = retail;

    AuthorizeNetModels.ccAuthenticationType ccAuth = new AuthorizeNetModels.ccAuthenticationType();
    ccAuth.authenticationIndicator = 'test';
    ccAuth.cardholderAuthenticationValue = 'test';
    tr.cardholderAuthentication = ccAuth;

    AuthorizeNetModels.settingType setting = new AuthorizeNetModels.settingType();
    setting.settingName = 'test';
    setting.settingValue = 'test';
    tr.transactionSettings = new List<AuthorizeNetModels.settingType>();
    tr.transactionSettings.add(setting);

    AuthorizeNetModels.userField userField = new AuthorizeNetModels.userField();
    userField.name = 'test';
    userField.value = 'test';
    tr.userFields = new List<AuthorizeNetModels.userField>();
    tr.userFields.add(userField);

    String responseString = '<?xml version="1.0" encoding="UTF-8"?><createTransactionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>1</responseCode><authCode>UGELQC</authCode><avsResultCode>E</avsResultCode><cavvResultCode /><transId>2148061808</transId><refTransID /><transHash>0B428D8A928AAC61121AF2F6EAC5FF3F</transHash><accountNumber>XXXX0015</accountNumber><accountType>MasterCard</accountType><message><code>1</code><description>This transaction has been approved.</description></message><userFields><userField><name>MerchantDefinedFieldName1</name><value>MerchantDefinedFieldValue1</value></userField><userField><name>favorite_color</name><value>lavender</value></userField></userFields></transactionResponse></createTransactionResponse>';
    Map<String, String> headers = new Map<String, String> {
      'Content-Type' => 'text/xml'
    };
    AuthorizeNetServiceMock mockResponse = new AuthorizeNetServiceMock(200, 'Complete', responseString, headers);
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    AuthorizeNetModels.createTransactionResponse response = ans.createTransaction(tr, '123');
    Test.stopTest();
  }

  @isTest static void testCreateSubscription() {
    AuthorizeNetModels.paymentScheduleTypeInterval interval = new AuthorizeNetModels.paymentScheduleTypeInterval();
    interval.length = 123;
    interval.unit = '123';

    AuthorizeNetModels.paymentScheduleType paymentSchedule = new AuthorizeNetModels.paymentScheduleType();
    paymentSchedule.interval = interval;
    paymentSchedule.startDate = '123';
    paymentSchedule.totalOccurrences = 123;
    paymentSchedule.trialOccurrences = 123;

    AuthorizeNetModels.creditCardType creditCard = new AuthorizeNetModels.creditCardType();
    creditCard.cardCode = '123';
    creditCard.cardNumber = '1234123412341234';
    creditCard.expirationDate = '2020-05';
    AuthorizeNetModels.paymentType payment = new AuthorizeNetModels.paymentType();
    payment.creditCard = creditCard;

    AuthorizeNetModels.customerType customer = new AuthorizeNetModels.customerType();
    customer.id = '123';
    AuthorizeNetModels.addressType address = new AuthorizeNetModels.addressType();
    address.firstName = '123';
    address.lastName = '123';
    address.company = '123';
    address.address = '123';
    address.city = '123';
    address.state = '123';
    address.zip = '123';
    address.country = '123';

    AuthorizeNetModels.ARBSubscriptionType sub = new AuthorizeNetModels.ARBSubscriptionType();
    sub.name = '123';
    sub.paymentSchedule = paymentSchedule;
    sub.amount = 10.00;
    sub.trialAmount = 10.00;
    sub.payment = payment;
    sub.customer = customer;
    sub.billTo = address;
    sub.shipTo = address;

    String responseString = '<?xml version="1.0" encoding="utf-8"?><ARBCreateSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>Sample</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><subscriptionId>100748</subscriptionId><profile><customerProfileId>247150</customerProfileId><customerPaymentProfileId>215472</customerPaymentProfileId><customerAddressId>189691</customerAddressId></profile></ARBCreateSubscriptionResponse>';
    Map<String, String> headers = new Map<String, String> {
      'Content-Type' => 'text/xml'
    };
    AuthorizeNetServiceMock mockResponse = new AuthorizeNetServiceMock(200, 'Complete', responseString, headers);
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    AuthorizeNetModels.ARBCreateSubscriptionResponse response = ans.createSubscription(sub, '123');
    Test.stopTest();
  }

  @isTest static void testUpdateSubscription() {
    AuthorizeNetModels.paymentScheduleTypeInterval interval = new AuthorizeNetModels.paymentScheduleTypeInterval();
    interval.length = 123;
    interval.unit = '123';

    AuthorizeNetModels.paymentScheduleType paymentSchedule = new AuthorizeNetModels.paymentScheduleType();
    paymentSchedule.interval = interval;
    paymentSchedule.startDate = '123';
    paymentSchedule.totalOccurrences = 123;
    paymentSchedule.trialOccurrences = 123;

    AuthorizeNetModels.creditCardType creditCard = new AuthorizeNetModels.creditCardType();
    creditCard.cardCode = '123';
    creditCard.cardNumber = '1234123412341234';
    creditCard.expirationDate = '2020-05';
    AuthorizeNetModels.paymentType payment = new AuthorizeNetModels.paymentType();
    payment.creditCard = creditCard;

    AuthorizeNetModels.customerType customer = new AuthorizeNetModels.customerType();
    customer.id = '123';
    AuthorizeNetModels.addressType address = new AuthorizeNetModels.addressType();
    address.firstName = '123';
    address.lastName = '123';
    address.company = '123';
    address.address = '123';
    address.city = '123';
    address.state = '123';
    address.zip = '123';
    address.country = '123';

    AuthorizeNetModels.ARBSubscriptionType sub = new AuthorizeNetModels.ARBSubscriptionType();
    sub.name = '123';
    sub.paymentSchedule = paymentSchedule;
    sub.amount = 10.00;
    sub.trialAmount = 10.00;
    sub.payment = payment;
    sub.customer = customer;
    sub.billTo = address;
    sub.shipTo = address;
    String responseString = '<?xml version="1.0" encoding="utf-8"?><ARBUpdateSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>Sample</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><profile><customerProfileId>247150</customerProfileId><customerPaymentProfileId>215472</customerPaymentProfileId><customerAddressId>189691</customerAddressId></profile></ARBUpdateSubscriptionResponse>';
    Map<String, String> headers = new Map<String, String> {
      'Content-Type' => 'text/xml'
    };
    AuthorizeNetServiceMock mockResponse = new AuthorizeNetServiceMock(200, 'Complete', responseString, headers);
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    AuthorizeNetModels.ARBUpdateSubscriptionResponse response = ans.updateSubscription(sub, '123', '123');
    Test.stopTest();
  }

  @isTest static void testCancelSubscription() {
    String responseString = '<?xml version="1.0" encoding="utf-8"?><ARBCancelSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>Sample</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages></ARBCancelSubscriptionResponse>';
    Map<String, String> headers = new Map<String, String> {
      'Content-Type' => 'text/xml'
    };
    AuthorizeNetServiceMock mockResponse = new AuthorizeNetServiceMock(200, 'Complete', responseString, headers);
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    AuthorizeNetModels.ARBCancelSubscriptionResponse response = ans.cancelSubscription('123', '123');
    Test.stopTest();
  }

  @isTest static void testGetSubscription() {
    String responseString = '<?xml version="1.0" encoding="UTF-8"?><ARBGetSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><refId>Sample</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><subscription><name>Sample subscription</name><paymentSchedule><interval><length>1</length><unit>months</unit></interval><startDate>2020-12-30</startDate><totalOccurrences>12</totalOccurrences><trialOccurrences>1</trialOccurrences></paymentSchedule><amount>10.29</amount><trialAmount>0.00</trialAmount><status>active</status><profile><description>Profile created by Subscription: 2930242</description><customerProfileId>37978171</customerProfileId><paymentProfile><customerType>individual</customerType><billTo><firstName>John</firstName><lastName>Smith</lastName></billTo><customerPaymentProfileId>34531293</customerPaymentProfileId><payment><creditCard><cardNumber>XXXX1111</cardNumber><expirationDate>XXXX</expirationDate></creditCard></payment></paymentProfile></profile></subscription></ARBGetSubscriptionResponse>';
    Map<String, String> headers = new Map<String, String> {
      'Content-Type' => 'text/xml'
    };
    AuthorizeNetServiceMock mockResponse = new AuthorizeNetServiceMock(200, 'Complete', responseString, headers);
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    AuthorizeNetModels.ARBGetSubscriptionResponse response = ans.getSubscription('123', '123');
    Test.stopTest();
  }

  @isTest static void testGetSubscriptionStatus() {
    String responseString = '<?xml version="1.0" encoding="UTF-8"?><ARBGetSubscriptionStatusResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/ XMLSchema-instance"><refId>Sample</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful</text></message></messages><Status>active</Status></ARBGetSubscriptionStatusResponse>';
    Map<String, String> headers = new Map<String, String> {
      'Content-Type' => 'text/xml'
    };
    AuthorizeNetServiceMock mockResponse = new AuthorizeNetServiceMock(200, 'Complete', responseString, headers);
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    AuthorizeNetModels.ARBGetSubscriptionStatusResponse response = ans.getSubscriptionStatus('123', '123');
    Test.stopTest();
  }

  @isTest static void testGetSettledBatchList() {
    String responseString = '<?xml version="1.0" encoding="UTF-8"?><getSettledBatchListResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><batchList><batch><batchId>12345678</batchId><settlementTimeUTC>2010-05-30T09:00:00</settlementTimeUTC><settlementTimeLocal>2010-05-30T03:00:00</settlementTimeLocal><settlementState>settledSuccessfully</settlementState><marketType>eCommerce</marketType><product>Card Not Present</product><statistics><statistic><accountType>Visa</accountType><!-- accountTypeEnum --><chargeAmount>200.00</chargeAmount><chargeCount>13</chargeCount><refundAmount>10.00</refundAmount><refundCount>1</refundCount><voidCount>2</voidCount><declineCount>4</declineCount><errorCount>6</errorCount><returnedItemAmount>0.00</returnedItemAmount><returnedItemCount>0</returnedItemCount><chargebackAmount>0.00</chargebackAmount><chargebackCount>0</chargebackCount><correctionNoticeCount>0</correctionNoticeCount><chargeChargeBackAmount>0.00</chargeChargeBackAmount><chargeChargeBackCount>0</chargeChargeBackCount><getBatchStatisticsResponseAmount>0.00</getBatchStatisticsResponseAmount><getBatchStatisticsResponseCount>0</getBatchStatisticsResponseCount><chargeReturnedItemsAmount>0.00</chargeReturnedItemsAmount><chargeReturnedItemsCount>0</chargeReturnedItemsCount><refundReturnedItemsAmount>0.00</refundReturnedItemsAmount><refundReturnedItemsCount>0</refundReturnedItemsCount></statistic><statistic><accountType>MasterCard</accountType><chargeAmount>200.00</chargeAmount><chargeCount>13</chargeCount><refundAmount>10.00</refundAmount><refundCount>1</refundCount><voidCount>2</voidCount><declineCount>4</declineCount><errorCount>6</errorCount><chargebackAmount>0.00</chargebackAmount><chargebackCount>0</chargebackCount><correctionNoticeCount>0</correctionNoticeCount><chargeChargeBackAmount>0.00</chargeChargeBackAmount><chargeChargeBackCount>0</chargeChargeBackCount><getBatchStatisticsResponseAmount>0.00</getBatchStatisticsResponseAmount><getBatchStatisticsResponseCount>0</getBatchStatisticsResponseCount></statistic></statistics></batch><batch><batchId>23456789</batchId><settlementTimeUTC>2010-05-30T09:00:00</settlementTimeUTC><settlementTimeLocal>2010-05-30T03:00:00</settlementTimeLocal><settlementState>settledSuccessfully</settlementState><statistics><statistic><accountType>eCheck</accountType><chargeAmount>200.00</chargeAmount><chargeCount>13</chargeCount><refundAmount>10.00</refundAmount><refundCount>1</refundCount><voidCount>2</voidCount><declineCount>4</declineCount><errorCount>6</errorCount><returnedItemAmount>0.00</returnedItemAmount><returnedItemCount>0</returnedItemCount><correctionNoticeCount>0</correctionNoticeCount><chargeReturnedItemsAmount>0.00</chargeReturnedItemsAmount><chargeReturnedItemsCount>0</chargeReturnedItemsCount><refundReturnedItemsAmount>0.00</refundReturnedItemsAmount><refundReturnedItemsCount>0</refundReturnedItemsCount></statistic></statistics></batch></batchList></getSettledBatchListResponse>';
    Map<String, String> headers = new Map<String, String> {
      'Content-Type' => 'text/xml'
    };
    AuthorizeNetServiceMock mockResponse = new AuthorizeNetServiceMock(200, 'Complete', responseString, headers);
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    AuthorizeNetModels.getSettledBatchListResponse response = ans.getSettledBatchList(Datetime.now(), Datetime.now(), true, '123');
    Test.stopTest();
  }

  @isTest static void testGetTransactionList() {
    String responseString = '<?xml version="1.0" encoding="UTF-8"?><getTransactionListResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactions><transaction><transId>12345</transId><submitTimeUTC>2009-05-30T09:00:00</submitTimeUTC><submitTimeLocal>2009-05-30T04:00:00</submitTimeLocal><transactionStatus>settledSuccessfully</transactionStatus><invoice>INV00001</invoice><firstName>John</firstName><lastName>Doe</lastName><amount>2.00</amount><accountType>Visa</accountType><accountNumber>XXXX1111</accountNumber><settleAmount>2.00</settleAmount><subscription><id>145521</id><payNum>1</payNum></subscription></transaction><transaction><transId>12345</transId><submitTimeUTC>2009-05-30T09:00:00</submitTimeUTC><submitTimeLocal>2009-05-30T04:00:00</submitTimeLocal><transactionStatus>settledSuccessfully</transactionStatus><invoice>INV00001</invoice><firstName>John</firstName><lastName>Doe</lastName><amount>2.00</amount><accountType>Visa</accountType><accountNumber>XXXX1111</accountNumber><marketType>eCommerce</marketType><product>Card Not Present</product><mobileDeviceId>2354578983274523978</mobileDeviceId></transaction></transactions></getTransactionListResponse>';
    Map<String, String> headers = new Map<String, String> {
      'Content-Type' => 'text/xml'
    };
    AuthorizeNetServiceMock mockResponse = new AuthorizeNetServiceMock(200, 'Complete', responseString, headers);
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    AuthorizeNetModels.getTransactionListResponse response = ans.getTransactionList('123', '123');
    Test.stopTest();
  }

  @isTest static void testGetUnsettledTransactionList() {
    String responseString = '<?xml version="1.0" encoding="UTF-8"?><getUnsettledTransactionListResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactions><transaction><transId>2158982012</transId><submitTimeUTC>2011-04-05T17:30:21Z</submitTimeUTC><submitTimeLocal>2011-04-05T18:30:21</submitTimeLocal><transactionStatus>authorizedPendingCapture</transactionStatus><invoiceNumber>123124123432</invoiceNumber><firstName>Unit</firstName><lastName>Tests</lastName><accountType>Visa</accountType><accountNumber>XXXX1111</accountNumber><settleAmount>1.11</settleAmount></transaction></transactions></getUnsettledTransactionListResponse>';
    Map<String, String> headers = new Map<String, String> {
      'Content-Type' => 'text/xml'
    };
    AuthorizeNetServiceMock mockResponse = new AuthorizeNetServiceMock(200, 'Complete', responseString, headers);
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    AuthorizeNetModels.getUnsettledTransactionListResponse response = ans.getUnsettledTransactionList();
    Test.stopTest();
  }

  @isTest static void testGetTransactionDetails() {
    String responseString = '<?xml version="1.0" encoding="UTF-8"?><getTransactionDetailsResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transaction><transId>12345</transId><refTransId>12345</refTransId><splitTenderId>12345</splitTenderId><submitTimeUTC>2010-08-30T17:49:20.757Z</submitTimeUTC><submitTimeLocal>2010-08-30T13:49:20.757</submitTimeLocal><transactionType>authOnlyTransaction</transactionType><transactionStatus>settledSuccessfully</transactionStatus><responseCode>1</responseCode><responseReasonCode>1</responseReasonCode><responseReasonDescription>Approval</responseReasonDescription><authCode>000000</authCode><AVSResponse>X</AVSResponse><cardCodeResponse>M</cardCodeResponse><CAVVResponse>2</CAVVResponse><FDSFilterAction>authAndHold</FDSFilterAction><FDSFilters><FDSFilter><name>Hourly Velocity Filter</name><action>authAndHold</action></FDSFilter><FDSFilter><name>Amount Filter</name><action>report</action></FDSFilter></FDSFilters><batch><batchId>12345</batchId><settlementTimeUTC>2010-08-30T17:49:20.757Z</settlementTimeUTC><settlementTimeLocal>2010-08-30T13:49:20.757</settlementTimeLocal><settlementState>settledSuccessfully</settlementState></batch><order><invoiceNumber>INV00001</invoiceNumber><description>some description</description><purchaseOrderNumber>PO000001</purchaseOrderNumber></order><requestedAmount>5.00</requestedAmount><authAmount>2.00</authAmount><settleAmount>2.00</settleAmount><tax><amount>1.00</amount><name>WA state sales tax</name><description>Washington state sales tax</description></tax><shipping><amount>2.00</amount><name>ground based shipping</name><description>Ground based 5 to 10 day shipping</description></shipping><duty><amount>1.00</amount></duty><lineItems><lineItem><itemId>ITEM00001</itemId><name>name of item sold</name><description>Description of item sold</description><quantity>1</quantity><unitPrice>6.95</unitPrice><taxable>true</taxable></lineItem><lineItem><itemId>ITEM00001</itemId><name>name of item sold</name><description>Description of item sold</description><quantity>1</quantity><unitPrice>6.95</unitPrice><taxable>true</taxable></lineItem></lineItems><prepaidBalanceRemaining>30.00</prepaidBalanceRemaining><taxExempt>false</taxExempt><payment><creditCard><cardNumber>XXXX1111</cardNumber><expirationDate>XXXX</expirationDate><accountType>Visa</accountType></creditCard></payment><customer><type>individual</type><id>ABC00001</id><email>mark@example.com</email></customer><billTo><firstName>John</firstName><lastName>Doe</lastName><company /><address>123 Main St.</address><city>Bellevue</city><state>WA</state><zip>98004</zip><country>USA</country><phoneNumber>000-000-0000</phoneNumber><faxNumber /></billTo><shipTo><firstName>John</firstName><lastName>Doe</lastName><company /><address>123 Main St.</address><city>Bellevue</city><state>WA</state><zip>98004</zip><country>USA</country></shipTo><recurringBilling>false</recurringBilling><customerIP>0.0.0.0</customerIP><subscription><id>145521</id><payNum>1</payNum><marketType>eCommerce</marketType><product>Card Not Present</product><returnedItems><returnedItem><id>2148878904</id><dateUTC>2014-05-12T21:22:44Z</dateUTC><dateLocal>2014-05-12T14:22:44</dateLocal><code>R02</code><description>Account Closed</description></returnedItem></returnedItems><solution><id>A1000004</id><name>Shopping Cart</name></solution><mobileDeviceId>2354578983274523978</mobileDeviceId></subscription></transaction></getTransactionDetailsResponse>';
    Map<String, String> headers = new Map<String, String> {
      'Content-Type' => 'text/xml'
    };
    AuthorizeNetServiceMock mockResponse = new AuthorizeNetServiceMock(200, 'Complete', responseString, headers);
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    AuthorizeNetModels.getTransactionDetailsResponse response = ans.getTransactionDetails('123', '123');
    Test.stopTest();
  }

  @isTest static void testGetBatchStatistics() {
    String responseString = '<?xml version="1.0" encoding="UTF-8"?><getBatchStatisticsResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><batch><batchId>24</batchId><settlementTimeUTC>2011-01-13T20:58:33Z</settlementTimeUTC><settlementTimeLocal>2011-01-13T12:58:33</settlementTimeLocal><settlementState>settledSuccessfully</settlementState><paymentMethod>creditCard</paymentMethod><statistics><statistic><accountType>Visa</accountType><chargeAmount>30.15</chargeAmount><chargeCount>7</chargeCount><refundAmount>0.00</refundAmount><refundCount>0</refundCount><voidCount>0</voidCount><declineCount>0</declineCount><errorCount>0</errorCount></statistic></statistics></batch></getBatchStatisticsResponse>';
    Map<String, String> headers = new Map<String, String> {
      'Content-Type' => 'text/xml'
    };
    AuthorizeNetServiceMock mockResponse = new AuthorizeNetServiceMock(200, 'Complete', responseString, headers);
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    AuthorizeNetModels.getBatchStatisticsResponse response = ans.getBatchStatistics('123');
    Test.stopTest();
  }

  @isTest static void testModels() {
    AuthorizeNetModels.driversLicenseType dlt = new AuthorizeNetModels.driversLicenseType();
    dlt.dateOfBirth = '1990-08-10';
    dlt.state = 'PA';
    dlt.num = '123455679';
    Dom.Document dltDoc = new Dom.Document();
    dltDoc.load(dlt.toXML());
    dlt = new AuthorizeNetModels.driversLicenseType(dltDoc.getRootElement());

    AuthorizeNetModels.paymentProfile pp = new AuthorizeNetModels.paymentProfile();
    pp.cardCode = '123';
    pp.paymentProfileId = '123';
    Dom.Document ppDoc = new Dom.Document();
    ppDoc.load(pp.toXML());
    pp = new AuthorizeNetModels.paymentProfile(ppDoc.getRootElement());

    AuthorizeNetModels.customerPaymentProfileType cppt = new AuthorizeNetModels.customerPaymentProfileType();
    cppt.billTo = new AuthorizeNetModels.addressType();
    cppt.customerPaymentProfileId = '123';
    cppt.customerProfileId = '123';
    cppt.customerType = 'test';
    cppt.driversLicense = dlt;
    cppt.payment = new AuthorizeNetModels.paymentType();
    cppt.subscriptionIds = new List<String>{'123','234'};
    cppt.taxId = '123';
    Dom.Document cpptDoc = new Dom.Document();
    cpptDoc.load(cppt.toXML('paymentProfile'));
    cppt = new AuthorizeNetModels.customerPaymentProfileType(cpptDoc.getRootElement());

    AuthorizeNetModels.customerProfileIdType cpit = new AuthorizeNetModels.customerProfileIdType();
    cpit.customerProfileId = '123';
    cpit.customerPaymentProfileId = '123';
    cpit.customerAddressId = '123';
    Dom.Document cpitDoc = new Dom.Document();
    cpitDoc.load(cpit.toXML());
    cpit = new AuthorizeNetModels.customerProfileIdType(cpitDoc.getRootElement());

    AuthorizeNetModels.returnedItemType rit = new AuthorizeNetModels.returnedItemType();
    rit.code = '123';
    rit.dateLocal = '2016-08-27';
    rit.dateUTC = '2016-08-27';
    rit.description = 'test';
    rit.id = '123';
    Dom.Document ritDoc = new Dom.Document();
    ritDoc.load(rit.toXML());
    rit = new AuthorizeNetModels.returnedItemType(ritDoc.getRootElement());

    AuthorizeNetModels.customerProfilePaymentType cProfPaymentType = new AuthorizeNetModels.customerProfilePaymentType();
    cProfPaymentType.createProfile = true;
    cProfPaymentType.customerProfileId = '123';
    cProfPaymentType.paymentProfile = pp;
    cProfPaymentType.shippingProfileId = '123';
    Dom.Document cProfPaymentTypeDoc = new Dom.Document();
    cProfPaymentTypeDoc.load(cProfPaymentType.toXML());
    cProfPaymentType = new AuthorizeNetModels.customerProfilePaymentType(cProfPaymentTypeDoc.getRootElement());
  }

  @IsTest
  static void testGetCustomerProfile() {
    // This test is purely for code coverage of the service class.
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new AuthorizeNetServiceMock());
    AuthorizeNetService s = new AuthorizeNetService('x', 'x', true);
    s.getCustomerProfile('refid', 'someid', true);
    Test.stopTest();
  }


  @IsTest
  static void testGetCustomerProfileResponseConstructor() {
    String xr = '<getCustomerProfileResponse ';
    xr += '  xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" ';
    xr += '  xmlns:xsd="http://www.w3.org/2001/XMLSchema" ';
    xr += '  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
    xr += '  <messages>';
    xr += '    <resultCode>Ok</resultCode>';
    xr += '    <message>';
    xr += '      <code>I00001</code>';
    xr += '      <text>Successful.</text>';
    xr += '    </message>';
    xr += '  </messages>';
    xr += '  <profile>';
    xr += '    <merchantCustomerId>custId123</merchantCustomerId>';
    xr += '    <description>some description</description>';
    xr += '    <email>newaddress@example.com</email>';
    xr += '    <customerProfileId>38010035</customerProfileId>';
    xr += '    <paymentProfile>';
    xr += '      <billTo>';
    xr += '        <firstName>John</firstName>';
    xr += '        <lastName>Smith</lastName>';
    xr += '      </billTo>';
    xr += '      <customerPaymentProfileId>34561675</customerPaymentProfileId>';
    xr += '      <payment>';
    xr += '        <creditCard>';
    xr += '          <cardNumber>XXXX1111</cardNumber>';
    xr += '          <expirationDate>XXXX</expirationDate>';
    xr += '          <issuerNumber>411111</issuerNumber>';
    xr += '        </creditCard>';
    xr += '      </payment>';
    xr += '    </paymentProfile>';
    xr += '    <profileType>regular</profileType>';
    xr += '  </profile>';
    xr += '  <subscriptionIds>';
    xr += '    <subscriptionId>2931598</subscriptionId>';
    xr += '  </subscriptionIds>';
    xr += '</getCustomerProfileResponse>';

    HttpResponse httpResponse = new HttpResponse();
    httpResponse.setBody(xr);

    Test.startTest();
    AuthorizeNetModels.getCustomerProfileResponse resp =
        new AuthorizeNetModels.getCustomerProfileResponse(httpResponse);
    Test.stopTest();

    System.assertEquals('Ok', resp.messages.resultCode);
    System.assertEquals('I00001', resp.messages.message.code);
    System.assertEquals('Successful.', resp.messages.message.text);
    System.assertEquals('custId123', resp.profile.merchantCustomerId);
    System.assertEquals('some description', resp.profile.description);
    System.assertEquals('newaddress@example.com', resp.profile.email);
    System.assertEquals('38010035', resp.profile.customerProfileId);
    System.assertEquals('John', resp.profile.paymentProfiles[0].billTo.firstName);
    System.assertEquals('Smith', resp.profile.paymentProfiles[0].billTo.lastName);
    System.assertEquals('34561675', resp.profile.paymentProfiles[0].customerPaymentProfileId);
    System.assertEquals('XXXX1111', resp.profile.paymentProfiles[0].payment.creditCard.cardNumber);
    System.assertEquals('XXXX', resp.profile.paymentProfiles[0].payment.creditCard.expirationDate);
    System.assertEquals('411111', resp.profile.paymentProfiles[0].payment.creditCard.issuerNumber);
    System.assertEquals('regular', resp.profile.profileType);
    System.assertEquals('2931598', resp.subscriptionIds[0]);
  }

  @IsTest
  static void testGetCustomerProfileRequestToXml() {
    AuthorizeNetModels.getCustomerProfileRequest req =
        new AuthorizeNetModels.getCustomerProfileRequest(
            merchantAuth,
            'boo');
    req.customerProfileId = 'id123';
    req.includeIssuerInfo = true;

    String xml = req.toXML().replaceAll('(\\s)', '');

    String expectedXml = '<getCustomerProfileRequest xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">';
    expectedXml += '  <merchantAuthentication>';
    expectedXml += '    <name>name</name>';
    expectedXml += '    <transactionKey>transactionKey</transactionKey>';
    expectedXml += '  </merchantAuthentication>';
    expectedXml += '  <refId>boo</refId>';
    expectedXml += '  <customerProfileId>id123</customerProfileId>';
    expectedXml += '  <includeIssuerInfo>true</includeIssuerInfo>';
    expectedXml += '</getCustomerProfileRequest>';
    expectedXml = expectedXml.replaceAll('(\\s)', '');

    System.assertEquals(expectedXml, xml);
  }

  @IsTest
  static void testCreateCustomerProfile() {
    // This test is purely for code coverage of the service class.
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new AuthorizeNetServiceMock());
    AuthorizeNetService s = new AuthorizeNetService('x','x', true);
    s.createCustomerProfile('refid',
        new AuthorizeNetModels.customerProfileType(),
        'test');
    Test.stopTest();
  }

  @IsTest
  static void testCreateCustomerProfileResponseConstructor() {

    String xr = '<createCustomerProfileResponse ';
    xr += '  xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" ';
    xr += '  xmlns:xsd="http://www.w3.org/2001/XMLSchema" ';
    xr += '  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
    xr += '  <refId>some ref id';
    xr += '  </refId>';
    xr += '  <messages>';
    xr += '    <resultCode>Ok';
    xr += '    </resultCode>';
    xr += '    <message>';
    xr += '      <code>I00001';
    xr += '      </code>';
    xr += '      <text>Successful.';
    xr += '      </text>';
    xr += '    </message>';
    xr += '  </messages>';
    xr += '  <customerProfileId>1504607010';
    xr += '  </customerProfileId>';
    xr += '  <customerPaymentProfileIdList>';
    xr += '    <numericString>1503913976';
    xr += '    </numericString>';
    xr += '    <numericString>1503913977';
    xr += '    </numericString>';
    xr += '  </customerPaymentProfileIdList>';
    xr += '  <customerShippingAddressIdList/>';
    xr += '  <validationDirectResponseList/>';
    xr += '</createCustomerProfileResponse>';

    HttpResponse httpResponse = new HttpResponse();
    httpResponse.setBody(xr);

    AuthorizeNetModels.createCustomerProfileResponse ccpr =
        new AuthorizeNetModels.createCustomerProfileResponse(httpResponse);

    // System.debug(ccpr);

    System.assertEquals('some ref id', ccpr.refId);
    System.assertEquals('Ok', ccpr.messages.resultCode);
    System.assertEquals('I00001', ccpr.messages.message.code);
    System.assertEquals('Successful.', ccpr.messages.message.text);
    System.assertEquals('1504607010', ccpr.customerProfileId);
    System.assertEquals(2, ccpr.customerPaymentProfileIdList.size());
    System.assertEquals('1503913976', ccpr.customerPaymentProfileIdList[0]);
    System.assertEquals('1503913977', ccpr.customerPaymentProfileIdList[1]);
  }

  @IsTest
  static void testCreateCustomerProfileRequestToXml() {

    AuthorizeNetModels.customerProfileType cp =
        new AuthorizeNetModels.customerProfileType();
    cp.merchantCustomerId = 'Merchant_Customer_ID';
    cp.description = 'Profile description here';
    cp.email = 'customer-profile-email@here.com';

    AuthorizeNetModels.customerPaymentProfileType cpp =
        new AuthorizeNetModels.customerPaymentProfileType();
    cp.paymentProfiles = new AuthorizeNetModels.customerPaymentProfileType[]{};
    // Adding two of the same just to show how the multiple elements work.
    cp.paymentProfiles.add(cpp);
    cp.paymentProfiles.add(cpp);
    cpp.customerType = 'individual';

    AuthorizeNetModels.paymentType payment = new AuthorizeNetModels.paymentType();
    cpp.payment = payment;
    payment.creditCard = new AuthorizeNetModels.creditCardType();
    payment.creditCard.cardNumber = '4111111111111111';
    payment.creditCard.expirationDate = '2020-12';

    AuthorizeNetModels.createCustomerProfileRequest req =
        new AuthorizeNetModels.createCustomerProfileRequest(
            merchantAuth, 'refId123');
    req.profile = cp;

    String xml = req.toXML().replaceAll('(\\s)', '');

    String expectedXml = '';
    expectedXml += '<createCustomerProfileRequest xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">';
    expectedXml += '  <merchantAuthentication>';
    expectedXml += '    <name>name</name>';
    expectedXml += '    <transactionKey>transactionKey</transactionKey>';
    expectedXml += '  </merchantAuthentication>';
    expectedXml += '  <refId>refId123</refId>';
    expectedXml += '  <profile>';
    expectedXml += '    <merchantCustomerId>Merchant_Customer_ID</merchantCustomerId>';
    expectedXml += '    <description>Profile description here</description>';
    expectedXml += '    <email>customer-profile-email@here.com</email>';
    expectedXml += '    <paymentProfiles>';
    expectedXml += '      <customerType>individual</customerType>';
    expectedXml += '      <payment>';
    expectedXml += '        <creditCard>';
    expectedXml += '          <cardNumber>4111111111111111</cardNumber>';
    expectedXml += '          <expirationDate>2020-12</expirationDate>';
    expectedXml += '        </creditCard>';
    expectedXml += '      </payment>';
    expectedXml += '    </paymentProfiles>';
    expectedXml += '    <paymentProfiles>';
    expectedXml += '      <customerType>individual</customerType>';
    expectedXml += '      <payment>';
    expectedXml += '        <creditCard>';
    expectedXml += '          <cardNumber>4111111111111111</cardNumber>';
    expectedXml += '          <expirationDate>2020-12</expirationDate>';
    expectedXml += '        </creditCard>';
    expectedXml += '      </payment>';
    expectedXml += '    </paymentProfiles>';
    expectedXml += '  </profile>';
    expectedXml += '</createCustomerProfileRequest>';
    expectedXml = expectedXml.replaceAll('(\\s)', '');

    System.assertEquals(expectedXml, xml);
  }

  @IsTest
  static void testGetCustomerProfileIds() {
    // This test is purely for code coverage of the service class.
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new AuthorizeNetServiceMock());
    AuthorizeNetService s = new AuthorizeNetService('x','x', true);
    s.getCustomerProfileIds('refid');
    Test.stopTest();
  }

  @IsTest
  static void testGetCustomerProfileIdsResponseConstructor() {

    String xr = '<getCustomerProfileIdsResponse ';
    xr += '  xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" ';
    xr += '  xmlns:xsd="http://www.w3.org/2001/XMLSchema" ';
    xr += '  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
    xr += '<messages>';
    xr += '  <resultCode>Ok</resultCode>';
    xr += '  <message>';
    xr += '    <code>I00001</code>';
    xr += '    <text>Successful.</text>';
    xr += '  </message>';
    xr += '</messages>';
    xr += '<ids>';
    xr += '  <numericString>38010035</numericString>';
    xr += '  <numericString>1813818874</numericString>';
    xr += '  <numericString>1814006033</numericString>';
    xr += '</ids>';
    xr += '</getCustomerProfileIdsResponse>';

    HttpResponse httpResponse = new HttpResponse();
    httpResponse.setBody(xr);

    AuthorizeNetModels.getCustomerProfileIdsResponse resp =
        new AuthorizeNetModels.getCustomerProfileIdsResponse(httpResponse);

    System.assertEquals('Ok', resp.messages.resultCode);
    System.assertEquals('I00001', resp.messages.message.code);
    System.assertEquals('Successful.', resp.messages.message.text);
    System.assertEquals('38010035', resp.ids[0]);
    System.assertEquals('1813818874', resp.ids[1]);
    System.assertEquals('1814006033', resp.ids[2]);
  }

  @IsTest
  static void testGetCustomerProfileIdsRequestToXml() {

    AuthorizeNetModels.getCustomerProfileIdsRequest req =
        new AuthorizeNetModels.getCustomerProfileIdsRequest(merchantAuth, '1199');

    String xml = req.toXML().replaceAll('(\\s)', '');

    String expectedXml = '<getCustomerProfileIdsRequest ' +
        'xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">';
    expectedXml += '  <merchantAuthentication>';
    expectedXml += '    <name>name</name>';
    expectedXml += '    <transactionKey>transactionKey</transactionKey>';
    expectedXml += '  </merchantAuthentication>' +
        '<refId>1199</refId>';
    expectedXml += '</getCustomerProfileIdsRequest>';
    expectedXml = expectedXml.replaceAll('(\\s)', '');

    System.assertEquals(expectedXml, xml);
  }

  @IsTest
  static void testDeleteCustomerProfileRequestToXml() {

    String expectedXml = '<deleteCustomerProfileRequest ' +
        'xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">';
    expectedXml += '  <merchantAuthentication>';
    expectedXml += '    <name>name</name>';
    expectedXml += '    <transactionKey>transactionKey</transactionKey>';
    expectedXml += '  </merchantAuthentication><refId>1199</refId>' +
        '<customerProfileId>cpid999</customerProfileId>';
    expectedXml += '</deleteCustomerProfileRequest>';
    expectedXml = expectedXml.replaceAll('(\\s)', '');

    AuthorizeNetModels.deleteCustomerProfileRequest req =
        new AuthorizeNetModels.deleteCustomerProfileRequest(
            merchantAuth,
            '1199',
            'cpid999');

    String xml = req.toXML().replaceAll('(\\s)', '');

    System.assertEquals(expectedXml, xml);
  }

  @IsTest
  static void testDeleteCustomerProfile() {
    // This test is purely for code coverage of the service class.
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new AuthorizeNetServiceMock());
    AuthorizeNetService s = new AuthorizeNetService('x','x', true);
    s.deleteCustomerProfile('refid', 'someid');
    Test.stopTest();
  }

  @IsTest
  static void testUpdateCustomerProfileRequestToXml() {

    AuthorizeNetModels.customerProfileType profile =
        new AuthorizeNetModels.customerProfileType();
    profile.merchantCustomerId = 'custId123';
    profile.description = 'some description';
    profile.email = 'newaddress@example.com';
    profile.customerProfileId = '10000';

    AuthorizeNetModels.updateCustomerProfileRequest req =
        new AuthorizeNetModels.updateCustomerProfileRequest(merchantAuth, '1199');
    req.profile = profile;

    String xml = req.toXML().replaceAll('(\\s)', '');

    String expectedXml = '<updateCustomerProfileRequest ' +
        'xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">';
    expectedXml += '  <merchantAuthentication>';
    expectedXml += '    <name>name</name>';
    expectedXml += '    <transactionKey>transactionKey</transactionKey>';
    expectedXml += '  </merchantAuthentication>' +
        '<refId>1199</refId>';
    expectedXml += '<profile>';
    expectedXml += '  <customerProfileId>10000</customerProfileId>';
    expectedXml += '  <merchantCustomerId>custId123</merchantCustomerId>';
    expectedXml += '  <description>some description</description>';
    expectedXml += '  <email>newaddress@example.com</email>';
    expectedXml += '</profile>';
    expectedXml += '</updateCustomerProfileRequest>';
    expectedXml = expectedXml.replaceAll('(\\s)', '');

    System.assertEquals(expectedXml, xml);
  }

  @IsTest
  static void testUpdateCustomerProfile() {
    // This test is purely for code coverage of the service class.
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new AuthorizeNetServiceMock());
    AuthorizeNetService s = new AuthorizeNetService('x','x', true);
    s.updateCustomerProfile('refid', null);
    Test.stopTest();
  }

  @IsTest
  static void testCreateCustomerPaymentProfileRequestToXml() {

    AuthorizeNetModels.customerPaymentProfileType pp =
        new AuthorizeNetModels.customerPaymentProfileType();
    pp.billTo = new AuthorizeNetModels.addressType();
    pp.billTo.firstName = 'John';
    pp.billTo.lastName = 'Doe';
    pp.billTo.address = '123 Main St.';
    pp.billTo.city = 'Bellevue';
    pp.billTo.state = 'WA';
    pp.billTo.zip = '98004';
    pp.billTo.country = 'USA';
    pp.billTo.phoneNumber = '000-000-0000';
    pp.payment = new AuthorizeNetModels.paymentType();
    pp.payment.creditCard = new AuthorizeNetModels.creditCardType();
    pp.payment.creditCard.cardNumber = '4111111111111111';
    pp.payment.creditCard.expirationDate = '2023-12';
    pp.defaultPaymentProfile = false;

    AuthorizeNetModels.createCustomerPaymentProfileRequest request =
        new AuthorizeNetModels.createCustomerPaymentProfileRequest(
            merchantAuth,
            'refid');
    request.customerProfileId = '10000';
    request.paymentProfile = pp;
    request.validationMode = 'liveMode';

    String xml = request.toXML().replaceAll('(\\s)', '');

    String expectedXml = '';
    expectedXml += '<createCustomerPaymentProfileRequest xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">';
    expectedXml += '  <merchantAuthentication>';
    expectedXml += '    <name>name</name>';
    expectedXml += '    <transactionKey>transactionKey</transactionKey>';
    expectedXml += '  </merchantAuthentication><refId>refid</refId>';
    expectedXml += '  <customerProfileId>10000</customerProfileId>';
    expectedXml += '  <paymentProfile>';
    expectedXml += '    <billTo>';
    expectedXml += '      <firstName>John</firstName>';
    expectedXml += '      <lastName>Doe</lastName>';
    expectedXml += '      <address>123 Main St.</address>';
    expectedXml += '      <city>Bellevue</city>';
    expectedXml += '      <state>WA</state>';
    expectedXml += '      <zip>98004</zip>';
    expectedXml += '      <country>USA</country>';
    expectedXml += '      <phoneNumber>000-000-0000</phoneNumber>';
    expectedXml += '    </billTo>';
    expectedXml += '    <payment>';
    expectedXml += '      <creditCard>';
    expectedXml += '        <cardNumber>4111111111111111</cardNumber>';
    expectedXml += '        <expirationDate>2023-12</expirationDate>';
    expectedXml += '      </creditCard>';
    expectedXml += '    </payment>';
    expectedXml += '    <defaultPaymentProfile>false</defaultPaymentProfile>';
    expectedXml += '  </paymentProfile>';
    expectedXml += '  <validationMode>liveMode</validationMode>';
    expectedXml += '</createCustomerPaymentProfileRequest>';
    expectedXml = expectedXml.replaceAll('(\\s)', '');

    System.assertEquals(expectedXml, xml);
  }

  @IsTest
  static void testCreateCustomerPaymentProfileResponseConstructor() {

    String xr = '<createCustomerPaymentProfileResponse ';
    xr += '  xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" ';
    xr += '  xmlns:xsd="http://www.w3.org/2001/XMLSchema" ';
    xr += '  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
    xr += '<messages>';
    xr += '  <resultCode>Ok</resultCode>';
    xr += '  <message>';
    xr += '    <code>I00001</code>';
    xr += '    <text>Successful.</text>';
    xr += '  </message>';
    xr += '</messages>';
    xr += '<customerProfileId>10000</customerProfileId>';
    xr += '<customerPaymentProfileId>20000</customerPaymentProfileId>';
    xr += '<validationDirectResponse>1,1,1,This transaction has been approved...</validationDirectResponse>';
    xr += '</createCustomerPaymentProfileResponse>';

    HttpResponse httpResponse = new HttpResponse();
    httpResponse.setBody(xr);

    AuthorizeNetModels.createCustomerPaymentProfileResponse response =
        new AuthorizeNetModels.createCustomerPaymentProfileResponse(httpResponse);

    System.assertEquals('Ok', response.messages.resultCode);
    System.assertEquals('I00001', response.messages.message.code);
    System.assertEquals('Successful.', response.messages.message.text);
    System.assertEquals('10000', response.customerProfileId);
    System.assertEquals('20000', response.customerPaymentProfileId);
    System.assertEquals('1,1,1,This transaction has been approved...',
        response.validationDirectResponse);
  }

  @IsTest
  static void testCreateCustomerPaymentProfile() {
    // This test is purely for code coverage of the service class.
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new AuthorizeNetServiceMock());
    AuthorizeNetService s = new AuthorizeNetService('x', 'x', true);
    s.createCustomerPaymentProfile('refid', 'custproid', null, 'foo');
    Test.stopTest();
  }

  @IsTest
  static void testGetCustomerPaymentProfileRequestToXml() {

    String x = '';
    x += '<getCustomerPaymentProfileRequest xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">';
    x += '  <merchantAuthentication>';
    x += '    <name>name</name>';
    x += '    <transactionKey>transactionKey</transactionKey>';
    x += '  </merchantAuthentication><refId>zzz</refId>';
    x += '  <customerProfileId>10000</customerProfileId>';
    x += '  <customerPaymentProfileId>20000</customerPaymentProfileId>';
    x += '  <includeIssuerInfo>true</includeIssuerInfo>';
    x += '</getCustomerPaymentProfileRequest>';
    x = x.replaceAll('(\\s)', '');

    AuthorizeNetModels.getCustomerPaymentProfileRequest req =
        new AuthorizeNetModels.getCustomerPaymentProfileRequest
            (merchantAuth, 'zzz');
    req.customerProfileId  = '10000';
    req.customerPaymentProfileId  = '20000';
    req.includeIssuerInfo  = true;

    String rx = req.toXML().replaceAll('(\\s)', '');

    System.assertEquals(x, rx);
  }

  @IsTest
  static void testGetCustomerPaymentProfileResponseConstructor() {

    String x = '';
    x += '<getCustomerPaymentProfileResponse ';
    x += '  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ';
    x += '  xmlns:xsd="http://www.w3.org/2001/XMLSchema" ';
    x += '  xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">';
    x += '  <messages>';
    x += '    <resultCode>Ok</resultCode>';
    x += '    <message>';
    x += '      <code>I00001</code>';
    x += '      <text>Successful.</text>';
    x += '    </message>';
    x += '  </messages>';
    x += '  <paymentProfile>';
    x += '    <billTo>';
    x += '      <firstName>John</firstName>';
    x += '      <lastName>Smith</lastName>';
    x += '    </billTo>';
    x += '    <customerProfileId>38010035</customerProfileId>';
    x += '    <customerPaymentProfileId>34561675</customerPaymentProfileId>';
    x += '    <payment>';
    x += '      <creditCard>';
    x += '        <cardNumber>XXXX1111</cardNumber>';
    x += '        <expirationDate>XXXX</expirationDate>';
    x += '        <issuerNumber>411111</issuerNumber>';
    x += '      </creditCard>';
    x += '    </payment>';
    x += '    <subscriptionIds>';
    x += '      <subscriptionId>2931598</subscriptionId>';
    x += '    </subscriptionIds>';
    x += '  </paymentProfile>';
    x += '</getCustomerPaymentProfileResponse>';

    HttpResponse httpResponse = new HttpResponse();
    httpResponse.setBody(x);

    AuthorizeNetModels.getCustomerPaymentProfileResponse response =
        new AuthorizeNetModels.getCustomerPaymentProfileResponse(httpResponse);

    System.assertEquals('Ok', response.messages.resultCode);
    System.assertEquals('I00001', response.messages.message.code);
    System.assertEquals('Successful.', response.messages.message.text);
    System.assertEquals('John', response.paymentProfile.billTo.firstName);
    System.assertEquals('Smith', response.paymentProfile.billTo.lastName);
    System.assertEquals('38010035', response.paymentProfile.customerProfileId);
    System.assertEquals('34561675', response.paymentProfile.customerPaymentProfileId);
    System.assertEquals('XXXX1111', response.paymentProfile.payment.creditCard.cardNumber);
    System.assertEquals('XXXX', response.paymentProfile.payment.creditCard.expirationDate);
    System.assertEquals('411111', response.paymentProfile.payment.creditCard.issuerNumber);
    System.assertEquals('2931598', response.paymentProfile.subscriptionIds[0]);
  }

  @IsTest
  static void testGetCustomerPaymentProfile() {
    // This test is purely for code coverage of the service class.
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new AuthorizeNetServiceMock());
    AuthorizeNetService s = new AuthorizeNetService('x', 'x', true);
    s.getCustomerPaymentProfile(
        'refId', 'customerProfileId', 'customerPaymentProfileId', false, false);
    Test.stopTest();
  }

  @IsTest
  static void testValidateCustomerPaymentProfileRequestToXml() {

    String x = '';
    x += '<validateCustomerPaymentProfileRequest xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">';
    x += '  <merchantAuthentication>';
    x += '    <name>name</name>';
    x += '    <transactionKey>transactionKey</transactionKey>';
    x += '  </merchantAuthentication>' +
        '<refId>098</refId>';
    x += '  <customerProfileId>10000</customerProfileId>';
    x += '  <customerPaymentProfileId>20000</customerPaymentProfileId>';
    x += '  <validationMode>liveMode</validationMode>';
    x += '</validateCustomerPaymentProfileRequest>';
    x = x.replaceAll('(\\s)', '');

    AuthorizeNetModels.validateCustomerPaymentProfileRequest req =
        new AuthorizeNetModels.validateCustomerPaymentProfileRequest(
            merchantAuth, '098');
    req.customerProfileId = '10000';
    req.customerPaymentProfileId = '20000';
    req.validationMode = 'liveMode';

    String a = req.toXML().replaceAll('(\\s)', '');

    System.assertEquals(x, a);
  }

  @IsTest
  static void testValidateCustomerPaymentProfileResponseConstructor () {
    String x = '';
    x += '<validateCustomerPaymentProfileResponse ';
    x += '  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ';
    x += '  xmlns:xsd="http://www.w3.org/2001/XMLSchema" ';
    x += '  xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">';
    x += '  <messages>';
    x += '    <resultCode>Ok</resultCode>';
    x += '    <message>';
    x += '      <code>I00001</code>';
    x += '      <text>Successful.</text>';
    x += '    </message>';
    x += '  </messages>';
    x += '  <directResponse>whatever</directResponse>';
    x += '</validateCustomerPaymentProfileResponse>';

    HttpResponse httpResponse = new HttpResponse();
    httpResponse.setBody(x);

    AuthorizeNetModels.validateCustomerPaymentProfileResponse response =
        new AuthorizeNetModels.validateCustomerPaymentProfileResponse(httpResponse);

    System.assertEquals('Ok', response.messages.resultCode);
    System.assertEquals('I00001', response.messages.message.code);
    System.assertEquals('Successful.', response.messages.message.text);
    System.assertEquals('whatever', response.directResponse);
  }

  @IsTest
  static void testValidateCustomerPaymentProfile() {
    // This test is purely for code coverage of the service class.
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new AuthorizeNetServiceMock());
    AuthorizeNetService s = new AuthorizeNetService('x', 'x', true);
    s.validateCustomerPaymentProfile(
        'asdf', 'asdf', 'asdf', 'asdf','asdf','asdf');
    Test.stopTest();
  }

  @IsTest
  static void testDeleteCustomerPaymentProfileRequestToXml() {

    AuthorizeNetModels.deleteCustomerPaymentProfileRequest req =
        new AuthorizeNetModels.deleteCustomerPaymentProfileRequest(
            merchantAuth,
            'eieiei');
    req.customerProfileId = '10000';
    req.customerPaymentProfileId = '20000';
    String a = req.toXML().replaceAll('(\\s)', '');

    String x = '';
    x += '<deleteCustomerPaymentProfileRequest xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">';
    x += '  <merchantAuthentication>';
    x += '    <name>name</name>';
    x += '    <transactionKey>transactionKey</transactionKey>';
    x += '  </merchantAuthentication>' +
        '<refId>eieiei</refId>';
    x += '  <customerProfileId>10000</customerProfileId>';
    x += '  <customerPaymentProfileId>20000</customerPaymentProfileId>';
    x += '</deleteCustomerPaymentProfileRequest>';
    x = x.replaceAll('(\\s)', '');

    System.assertEquals(x, a);
  }

  @IsTest
  static void testDeleteCustomerPaymentProfile() {
    // This test is purely for code coverage of the service class.
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new AuthorizeNetServiceMock());
    AuthorizeNetService s = new AuthorizeNetService('x', 'x', true);
    s.deleteCustomerPaymentProfile(
        'asdf', 'asdf', 'asdf');
    Test.stopTest();
  }

  @IsTest
  static void testUpdateCustomerPaymentProfileRequestToXml() {
    AuthorizeNetModels.customerPaymentProfileType pp =
        new AuthorizeNetModels.customerPaymentProfileType();
    pp.billTo = new AuthorizeNetModels.addressType();
    pp.billTo.firstName = 'John';
    pp.billTo.lastName = 'Doe';
    pp.billTo.company = '';
    pp.billTo.address = '123 Main St.';
    pp.billTo.city = 'Bellevue';
    pp.billTo.state = 'WA';
    pp.billTo.zip = '98004';
    pp.billTo.country = 'USA';
    pp.billTo.phoneNumber = '000-000-0000';
    pp.billTo.faxNumber = '';
    pp.payment = new AuthorizeNetModels.paymentType();
    pp.payment.creditCard = new AuthorizeNetModels.creditCardType();
    pp.payment.creditCard.cardNumber = '4111111111111111';
    pp.payment.creditCard.expirationDate = '2026-01';
    pp.defaultPaymentProfile = false;
    pp.customerPaymentProfileId = '20000';

    AuthorizeNetModels.updateCustomerPaymentProfileRequest req =
        new AuthorizeNetModels.updateCustomerPaymentProfileRequest(
            merchantAuth,
            '83838');
    req.customerProfileId = '99';
    req.paymentProfile = pp;
    req.validationMode = 'liveMode';

    String a = req.toXML().replaceAll('(\\s)', '');

    String x = '';
    x += '<updateCustomerPaymentProfileRequest xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">';
    x += '  <merchantAuthentication>';
    x += '    <name>name</name>';
    x += '    <transactionKey>transactionKey</transactionKey>';
    x += '  </merchantAuthentication><refId>83838</refId>';
    x += '  <customerProfileId>99</customerProfileId>';
    x += '  <paymentProfile>';
    x += '    <billTo>';
    x += '      <firstName>John</firstName>';
    x += '      <lastName>Doe</lastName>';
    x += '      <company></company>';
    x += '      <address>123 Main St.</address>';
    x += '      <city>Bellevue</city>';
    x += '      <state>WA</state>';
    x += '      <zip>98004</zip>';
    x += '      <country>USA</country>';
    x += '      <phoneNumber>000-000-0000</phoneNumber>';
    x += '      <faxNumber></faxNumber>';
    x += '    </billTo>';
    x += '    <payment>';
    x += '      <creditCard>';
    x += '        <cardNumber>4111111111111111</cardNumber>';
    x += '        <expirationDate>2026-01</expirationDate>';
    x += '      </creditCard>';
    x += '    </payment>';
    x += '    <defaultPaymentProfile>false</defaultPaymentProfile>';
    x += '    <customerPaymentProfileId>20000</customerPaymentProfileId>';
    x += '  </paymentProfile>';
    x += '  <validationMode>liveMode</validationMode>';
    x += '</updateCustomerPaymentProfileRequest>';
    x = x.replaceAll('(\\s)', '');

    System.assertEquals(x, a);
  }

  @IsTest
  static void testUpdateCustomerPaymentProfile() {
    // This test is purely for code coverage of the service class.
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new AuthorizeNetServiceMock());
    AuthorizeNetService s = new AuthorizeNetService('x', 'x', true);
    s.updateCustomerPaymentProfile(
        'asdf', 'asdf', null, 'asdf');
    Test.stopTest();
  }
}