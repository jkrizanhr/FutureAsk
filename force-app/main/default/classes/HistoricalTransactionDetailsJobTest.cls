@isTest
private class HistoricalTransactionDetailsJobTest {
  @isTest
  static void testJob() {
    Historical_Transaction_Settings__c htSettings = new Historical_Transaction_Settings__c();
    htSettings.Name = 'Test';
    htSettings.Time_Step_Minutes__c = 10;
    htSettings.Start_Time_Step_seconds__c = 1;
    htSettings.Record_Query_Size__c = 100;
    insert htSettings;

    Historical_Transaction__c ht = new Historical_Transaction__c();
    ht.Transaction_Id__c = '12345';
    ht.Type__c = 'Test';
    ht.Amount__c = 50;
    ht.Email__c = 'test@test.test';
    ht.First_Name__c = 'test';
    ht.Last_Name__c = 'test';
    ht.Phone__c = '5555555555';
    ht.Billing_Street__c = '123 Test Street';
    ht.Billing_Street_2__c = 'Apt. 2';
    ht.Billing_City__c = 'Harrisburg';
    ht.Billing_State_Province__c = 'PA';
    ht.Billing_Postal_Code__c = '17101';
    ht.Billing_Country__c = 'USA';
    ht.Create_Time__c = Datetime.now();
    ht.Status__c = 'settledSuccessfully';
    ht.Retrieved_Details__c = false;
    insert ht;

    String response = '<?xml version="1.0" encoding="UTF-8"?><SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:cc="urn:ebay:apis:CoreComponentTypes" xmlns:wsu="http://schemas.xmlsoap.org/ws/2002/07/utility" xmlns:saml="urn:oasis:names:tc:SAML:1.0:assertion" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:wsse="http://schemas.xmlsoap.org/ws/2002/12/secext" xmlns:ed="urn:ebay:apis:EnhancedDataTypes" xmlns:ebl="urn:ebay:apis:eBLBaseComponents" xmlns:ns="urn:ebay:api:PayPalAPI"><SOAP-ENV:Header><Security xmlns="http://schemas.xmlsoap.org/ws/2002/12/secext" xsi:type="wsse:SecurityType"/><RequesterCredentials xmlns="urn:ebay:api:PayPalAPI" xsi:type="ebl:CustomSecurityHeaderType"><Credentials xmlns="urn:ebay:apis:eBLBaseComponents" xsi:type="ebl:UserIdPasswordType"><Username xsi:type="xs:string"/><Password xsi:type="xs:string"/><Signature xsi:type="xs:string"/><Subject xsi:type="xs:string"/></Credentials></RequesterCredentials></SOAP-ENV:Header><SOAP-ENV:Body id="_0"><GetTransactionDetailsResponse xmlns="urn:ebay:api:PayPalAPI"><Timestamp xmlns="urn:ebay:apis:eBLBaseComponents">2015-11-30T14:05:15Z</Timestamp><Ack xmlns="urn:ebay:apis:eBLBaseComponents">Success</Ack><CorrelationID xmlns="urn:ebay:apis:eBLBaseComponents">2154584e29c83</CorrelationID><Version xmlns="urn:ebay:apis:eBLBaseComponents">124.0</Version><Build xmlns="urn:ebay:apis:eBLBaseComponents">18308778</Build><PaymentTransactionDetails xmlns="urn:ebay:apis:eBLBaseComponents" xsi:type="ebl:PaymentTransactionType"><ReceiverInfo xsi:type="ebl:ReceiverInfoType"><Business xsi:type="ebl:EmailAddressType">test@test.test</Business><Receiver xsi:type="ebl:EmailAddressType">test@test.test</Receiver><ReceiverID xsi:type="ebl:UserIDType">N8T7RWGB7JAKC</ReceiverID></ReceiverInfo><PayerInfo xsi:type="ebl:PayerInfoType"><Payer xsi:type="ebl:EmailAddressType">test@test.com</Payer><PayerID xsi:type="ebl:UserIDType">AZFQU8FHCSLMC</PayerID><PayerStatus xsi:type="ebl:PayPalUserStatusCodeType">verified</PayerStatus><PayerName xsi:type="ebl:PersonNameType"><Salutation xmlns="urn:ebay:apis:eBLBaseComponents">Mr.</Salutation><FirstName xmlns="urn:ebay:apis:eBLBaseComponents">test</FirstName><MiddleName xmlns="urn:ebay:apis:eBLBaseComponents">test</MiddleName><LastName xmlns="urn:ebay:apis:eBLBaseComponents">test</LastName><Suffix xmlns="urn:ebay:apis:eBLBaseComponents">Jr.</Suffix></PayerName><PayerCountry xsi:type="ebl:CountryCodeType">US</PayerCountry><PayerBusiness xsi:type="xs:string"/><Address xsi:type="ebl:AddressType"><Name xsi:type="xs:string">test test</Name><Street1 xsi:type="xs:string">123 Main Street</Street1><Street2 xsi:type="xs:string">#2</Street2><CityName xsi:type="xs:string">test</CityName><StateOrProvince xsi:type="xs:string">GA</StateOrProvince><Country xsi:type="ebl:CountryCodeType">US</Country><CountryName>United States</CountryName><PostalCode xsi:type="xs:string">30305</PostalCode><AddressOwner xsi:type="ebl:AddressOwnerCodeType">PayPal</AddressOwner><AddressStatus xsi:type="ebl:AddressStatusCodeType">Confirmed</AddressStatus></Address><ContactPhone xsi:type="xs:string">5555555555</ContactPhone></PayerInfo><TPLReferenceID xsi:type="xs:string"/><PaymentInfo xsi:type="ebl:PaymentInfoType"><TransactionID>8V079861VC3005741</TransactionID><ParentTransactionID xsi:type="ebl:TransactionId"/><ReceiptID/><TransactionType xsi:type="ebl:PaymentTransactionCodeType">subscr-payment</TransactionType><PaymentType xsi:type="ebl:PaymentCodeType">instant</PaymentType><PaymentDate xsi:type="xs:dateTime">2015-01-01T20:18:05Z</PaymentDate><GrossAmount xsi:type="cc:BasicAmountType" currencyID="USD">50.00</GrossAmount><FeeAmount xsi:type="cc:BasicAmountType" currencyID="USD">1.25</FeeAmount><ExchangeRate xsi:type="xs:string"/><PaymentStatus xsi:type="ebl:PaymentStatusCodeType">Completed</PaymentStatus><PendingReason xsi:type="ebl:PendingStatusCodeType">none</PendingReason><ReasonCode xsi:type="ebl:ReversalReasonCodeType">none</ReasonCode><ProtectionEligibility xsi:type="xs:string">Eligible</ProtectionEligibility><ProtectionEligibilityType xsi:type="xs:string">ItemNotReceivedEligible,UnauthorizedPaymentEligible</ProtectionEligibilityType><ShipAmount xsi:type="xs:string"/><ShipHandleAmount xsi:type="xs:string"/><ShipDiscount xsi:type="xs:string"/><InsuranceAmount xsi:type="xs:string"/><Subject xsi:type="xs:string">Sign up for monthly donations</Subject><ReceiptReferenceNumber xsi:type="xs:string"/><POSTransactionType xsi:type="xs:string"/><StoreID xsi:type="xs:string"/><TerminalID xsi:type="xs:string"/><BinEligibility xsi:type="xs:string"/></PaymentInfo><PaymentItemInfo xsi:type="ebl:PaymentItemInfoType"><InvoiceID xsi:type="xs:string"/><Custom xsi:type="xs:string"/><Memo xsi:type="xs:string"/><SalesTax xsi:type="xs:string"/><PaymentItem xmlns="urn:ebay:apis:eBLBaseComponents" xsi:type="ebl:PaymentItemType"><EbayItemTxnId xsi:type="xs:string"/><Name xsi:type="xs:string">Sign up for monthly donations</Name><Number xsi:type="xs:string">Monthly</Number><Quantity xsi:type="xs:string"/><SalesTax xsi:type="xs:string"/><ShippingAmount xsi:type="xs:string"/><HandlingAmount xsi:type="xs:string"/><CouponID xsi:type="xs:string"/><CouponAmount xsi:type="xs:string"/><CouponAmountCurrency xsi:type="xs:string"/><LoyaltyCardDiscountAmount xsi:type="xs:string"/><LoyaltyCardDiscountCurrency xsi:type="xs:string"/><InvoiceItem xsi:type="ebl:InvoiceItemType"><ItemCountUnit xsi:type="ebl:UnitOfMeasure"/><Taxable xsi:type="xs:string">true</Taxable><TaxRate xsi:type="xs:string"/><MPN xsi:type="xs:string"/><ISBN xsi:type="xs:string"/><PLU xsi:type="xs:string"/><ModelNumber xsi:type="xs:string"/><StyleNumber xsi:type="xs:string"/></InvoiceItem></PaymentItem><Subscription xsi:type="ebl:SubscriptionInfoType" recurring="" reattempt=""><SubscriptionID>I-3KWWXHK6S9U6</SubscriptionID><Username xsi:type="xs:string"/><Password xsi:type="xs:string"/><Recurrences xsi:type="xs:string"/><Terms xmlns="urn:ebay:apis:eBLBaseComponents" xsi:type="ebl:SubscriptionTermsType" period=""/><Terms xmlns="urn:ebay:apis:eBLBaseComponents" xsi:type="ebl:SubscriptionTermsType" period=""/><Terms xmlns="urn:ebay:apis:eBLBaseComponents" xsi:type="ebl:SubscriptionTermsType" period=""/></Subscription><Auction xsi:type="ebl:AuctionInfoType" multiItem=""><BuyerID xsi:type="xs:string"/></Auction></PaymentItemInfo><OfferCouponInfo xsi:type="ebl:OfferCouponInfoType"><Type xsi:type="xs:string"/><ID xsi:type="xs:string"/><Amount xsi:type="xs:string"/><AmountCurrency xsi:type="xs:string"/></OfferCouponInfo></PaymentTransactionDetails></GetTransactionDetailsResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>';
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
    HistoricalTransactionDetailsJob.schedule('Test', 'Test Details Job', null);
    HistoricalTransactionDetailsJob.run('Test');
    Test.stopTest();

    List<Historical_Transaction__c> transactions = [
      SELECT Retrieved_Details__c
      FROM Historical_Transaction__c
      WHERE Id = :ht.Id
    ];
    System.assertNotEquals(null, transactions);
    System.assertEquals(1, transactions.size());
    System.assertEquals(true, transactions[0].Retrieved_Details__c);
  }
}