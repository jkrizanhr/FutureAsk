@isTest
private class ManageAuthNetRefundsControllerTest {
  @TestSetup
  static void makeData() {
    ManageAuthNetServiceTest.setupCurrencyExchange();
    ManageAuthNetServiceTest.setupOpportunity();
    ManageAuthNetServiceTest.setupRecurringDonation();
    ManageAuthNetServiceTest.setupAuthService();
  }

  @isTest
  static void testFetchData() {
    Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test CC Opp'];

    List<HttpCalloutMock> responses = new List<HttpCalloutMock>();
    Map<String, String> headers = new Map<String, String>();
    AuthorizeNetServiceMock getTransactionDetailsResponse = new AuthorizeNetServiceMock(
      200,
      'Complete',
      '<?xml version="1.0" encoding="UTF-8"?><getTransactionDetailsResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transaction><transId>40022826172</transId><submitTimeUTC>2018-12-14T08:54:33.177Z</submitTimeUTC><submitTimeLocal>2018-12-14T00:54:33.177</submitTimeLocal><transactionType>authCaptureTransaction</transactionType><transactionStatus>pendingFinalSettlement</transactionStatus><responseCode>1</responseCode><responseReasonCode>1</responseReasonCode><subscription><id>5486668</id><payNum>1</payNum></subscription><responseReasonDescription>Approval</responseReasonDescription><authCode>12CD56</authCode><AVSResponse>Y</AVSResponse><cardCodeResponse>M</cardCodeResponse><batch><batchId>8863437</batchId><settlementTimeUTC>2018-12-14T15:12:19.473Z</settlementTimeUTC><settlementTimeLocal>2018-12-14T07:12:19.473</settlementTimeLocal><settlementState>settlementError</settlementState></batch><authAmount>10.29</authAmount><settleAmount>10.29</settleAmount><taxExempt>false</taxExempt><payment><creditCard><cardNumber>XXXX1111</cardNumber><expirationDate>XXXX</expirationDate><cardType>Visa</cardType></creditCard></payment><billTo><firstName>Iam</firstName><lastName>Testing</lastName><address>123</address><zip>98004</zip></billTo><recurringBilling>false</recurringBilling><product>Card Not Present</product><marketType>eCommerce</marketType><networkTransId>123456789NNNH</networkTransId><originalNetworkTransId>129456789 DFG H</originalNetworkTransId><originalAuthAmount>12.00</originalAuthAmount><authorizationIndicator>pre</authorizationIndicator></transaction></getTransactionDetailsResponse>',
      headers
    );
    responses.add(getTransactionDetailsResponse);

    MultiRequestMock multiMock = new MultiRequestMock(responses);
    Test.setMock(HttpCalloutMock.class, multiMock);

    ManageAuthNetRefundsController.TransactionInfo ti = ManageAuthNetRefundsController.fetchData(
      opp.Id
    );
    System.assertEquals('40022826172', ti.id);
  }

  @isTest
  static void testIssueFullRefundCC() {
    Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test CC Opp'];

    String transInfo = '{ "id": 128, "status": "settledSuccessfully", "amount": 2.00 }';

    //Create callout mock for refund
    List<HttpCalloutMock> responses = new List<HttpCalloutMock>();
    String profileRes = '<?xml version="1.0" encoding="utf-8"?><createTransactionResponse xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transaction><responseCode>1</responseCode><authCode /><avsResultCode>P</avsResultCode><cvvResultCode /><cavvResultCode /><transId>1234569999</transId><refTransID>1234567890</refTransID><transHash>362802181B7D3947E862E42FD0FD8219</transHash><accountNumber>XXXX0015</accountNumber><accountType>Mastercard</accountType><messages><message><code>1</code><description>This transaction has been approved.</description></message></messages></transaction></createTransactionResponse>';
    Map<String, String> headers = new Map<String, String>();
    AuthorizeNetServiceMock createTransactionResponse = new AuthorizeNetServiceMock(
      200,
      'Complete',
      profileRes,
      headers
    );
    responses.add(createTransactionResponse);

    MultiRequestMock multiMock = new MultiRequestMock(responses);
    Test.setMock(HttpCalloutMock.class, multiMock);

    //Execute refund
    String newOppId = ManageAuthNetRefundsController.issueFullRefund(opp.Id, transInfo);
  }

  @isTest
  static void testIssueFullRefundBank() {
    Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Bank Opp'];

    String transInfo = '{ "id": "40022826172", "status": "settledSuccessfully", "amount": 2.00 }';

    //Create callout mock for refund
    List<HttpCalloutMock> responses = new List<HttpCalloutMock>();
    Map<String, String> headers = new Map<String, String>();
    AuthorizeNetServiceMock getTransactionDetailsResponse = new AuthorizeNetServiceMock(
      200,
      'Complete',
      '<?xml version="1.0" encoding="UTF-8"?><getTransactionDetailsResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transaction><transId>40022826172</transId><submitTimeUTC>2018-12-14T08:54:33.177Z</submitTimeUTC><submitTimeLocal>2018-12-14T00:54:33.177</submitTimeLocal><transactionType>authCaptureTransaction</transactionType><transactionStatus>pendingFinalSettlement</transactionStatus><responseCode>1</responseCode><responseReasonCode>1</responseReasonCode><subscription><id>5486668</id><payNum>1</payNum></subscription><responseReasonDescription>Approval</responseReasonDescription><authCode>12CD56</authCode><AVSResponse>Y</AVSResponse><cardCodeResponse>M</cardCodeResponse><batch><batchId>8863437</batchId><settlementTimeUTC>2018-12-14T15:12:19.473Z</settlementTimeUTC><settlementTimeLocal>2018-12-14T07:12:19.473</settlementTimeLocal><settlementState>settlementError</settlementState></batch><authAmount>10.29</authAmount><settleAmount>10.29</settleAmount><taxExempt>false</taxExempt><payment><bankAccount><accountType>checking</accountType><routingNumber>121042882</routingNumber><accountNumber>123456789</accountNumber><nameOnAccount>John Doe</nameOnAccount></bankAccount></payment><billTo><firstName>Iam</firstName><lastName>Testing</lastName><address>123</address><zip>98004</zip></billTo><recurringBilling>false</recurringBilling><product>Card Not Present</product><marketType>eCommerce</marketType><networkTransId>123456789NNNH</networkTransId><originalNetworkTransId>129456789 DFG H</originalNetworkTransId><originalAuthAmount>12.00</originalAuthAmount><authorizationIndicator>pre</authorizationIndicator></transaction></getTransactionDetailsResponse>',
      headers
    );
    AuthorizeNetServiceMock createTransactionResponse = new AuthorizeNetServiceMock(
      200,
      'Complete',
      '<?xml version="1.0" encoding="utf-8"?><createTransactionResponse xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transaction><responseCode>1</responseCode><authCode /><avsResultCode>P</avsResultCode><cvvResultCode /><cavvResultCode /><transId>1234569999</transId><refTransID>1234567890</refTransID><transHash>362802181B7D3947E862E42FD0FD8219</transHash><accountNumber>XXXX0015</accountNumber><accountType>Mastercard</accountType><messages><message><code>1</code><description>This transaction has been approved.</description></message></messages></transaction></createTransactionResponse>',
      headers
    );
    responses.add(getTransactionDetailsResponse);
    responses.add(createTransactionResponse);

    MultiRequestMock multiMock = new MultiRequestMock(responses);
    Test.setMock(HttpCalloutMock.class, multiMock);

    //Execute refund
    String newOppId = ManageAuthNetRefundsController.issueFullRefund(opp.Id, transInfo);
  }

  @isTest
  static void testCreateAdjustmentOpportunity() {
    Opportunity opp = [
      SELECT Id, Name, RecordTypeId, Transaction_Id__c, Amount, StageName, CloseDate
      FROM Opportunity
      WHERE Name = 'Test CC Opp'
    ];

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c(
      Name = 'Test GAU',
      Purpose_Code__c = '123'
    );
    insert gau;

    npsp__Allocation__c allocation = new npsp__Allocation__c();
    allocation.npsp__General_Accounting_Unit__c = gau.Id;
    allocation.npsp__Opportunity__c = opp.Id;
    allocation.npsp__Amount__c = 1.00;
    insert allocation;

    //Get mocked response
    HttpResponse response = new HttpResponse();
    response.setBody(
      '<?xml version="1.0" encoding="utf-8"?><createTransactionResponse xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transaction><responseCode>1</responseCode><rawResponseCode>0</rawResponseCode><transId>128</transId><refTransID>128</refTransID><transHash>A7C677FBB549F6362BB4017AA844C7AE</transHash><accountType>PayPal</accountType><messages><message><code>2003</code><description>Request completed successfully</description></message></messages><shipTo><firstName>First</firstName><lastName>Last</lastName><address>1, ABC St Suite #100</address><city>Bellevue</city><state>WA</state><zip>98005</zip><country>US</country></shipTo><secureAcceptance><payerID>S6D5ETGSVYX94</payerID></secureAcceptance></transaction></createTransactionResponse>'
    );

    //Get transaction details
    AuthorizeNetModels.getTransactionDetailsResponse transactionDetailsResponse = new AuthorizeNetModels.getTransactionDetailsResponse(
      response
    );

    //Create the TransactionInfo object, which the UI uses to track variables
    ManageAuthNetRefundsController.TransactionInfo ti = new ManageAuthNetRefundsController.TransactionInfo(
      opp.Id,
      transactionDetailsResponse
    );

    Id newOppId = ManageAuthNetRefundsController.createAdjustmentOpportunity(
      opp.Id,
      ti,
      '1234569999'
    );

    Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :opp.Id];

    Opportunity newOpp = [
      SELECT
        Id,
        Amount,
        StageName,
        Original_Amount__c,
        Adjusted_Opportunity__c,
        (SELECT npsp__Amount__c, Original_Amount__c FROM npsp__Allocations__r)
      FROM Opportunity
      WHERE Id = :newOppId
    ];

    //Check amounts
    System.assertEquals(opp.Amount, -1 * newOpp.Amount);
    System.assertEquals(opp.Amount, -1 * newOpp.Original_Amount__c);
    System.assertEquals(
      allocation.npsp__Amount__c,
      -1 * newOpp.npsp__Allocations__r[0].npsp__Amount__c
    );
    System.assertEquals(
      allocation.npsp__Amount__c,
      -1 * newOpp.npsp__Allocations__r[0].Original_Amount__c
    );

    //Check StageNames
    System.assertEquals('Adjustment', updatedOpp.StageName);
    System.assertEquals('Adjustment', newOpp.StageName);

    //Check new Opp lookup to old opp
    System.assertEquals(opp.Id, newOpp.Adjusted_Opportunity__c);
  }
}