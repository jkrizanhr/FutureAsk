@isTest
public without sharing class DonationPageAuthNetSubscriptionJobTest {
  @testSetup
  static void createData() {
    Donation_Page_Auth_net_Settings__c authNetSandboxSettings = new Donation_Page_Auth_net_Settings__c();
    authNetSandboxSettings.Name = 'Sandbox';
    authNetSandboxSettings.Client_Key__c = 'client_key';
    authNetSandboxSettings.API_Login_Id__c = 'login_id';
    authNetSandboxSettings.Transaction_Key__c = 'transaction_key';
    insert authNetSandboxSettings;
    Donation_Page_Auth_net_Settings__c authNetProductionSettings = new Donation_Page_Auth_net_Settings__c();
    authNetProductionSettings.Name = 'Production';
    authNetProductionSettings.Client_Key__c = 'client_key';
    authNetProductionSettings.API_Login_Id__c = 'login_id';
    authNetProductionSettings.Transaction_Key__c = 'transaction_key';
    insert authNetProductionSettings;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test GAU';
    gau.Purpose_Code__c = '123';
    insert gau;

    npsp__General_Accounting_Unit__c gau2 = new npsp__General_Accounting_Unit__c();
    gau2.Name = 'Test GAU 2';
    gau2.Purpose_Code__c = 'gau2';
    insert gau2;

    Donation_Form_Settings__c dfSettings = new Donation_Form_Settings__c();
    dfSettings.Coverage_Fees_Fund_Id__c = gau.Id;
    insert dfSettings;

    Campaign camp = new Campaign();
    camp.Name = 'Test Campaign';
    camp.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName()
      .get('Donation Page')
      .getRecordTypeId();
    insert camp;

    Donation_Page_Settings__c dpSettings = new Donation_Page_Settings__c();
    dpSettings.Name = 'Test';
    dpSettings.Campaign__c = camp.Id;
    dpSettings.Donation_Page_Title__c = 'Test';
    insert dpSettings;

    Donation_Option__c donOpt = new Donation_Option__c();
    donOpt.Active__c = true;
    donOpt.Amount__c = 1;
    donOpt.Donation_Page_Settings__c = dpSettings.Id;
    donOpt.Name = 'Option 1';
    donOpt.Fund__c = gau.Id;
    insert donOpt;

    Currency_Exchange_Rate__c exchangeRate = new Currency_Exchange_Rate__c();
    exchangeRate.API_Response__c = '{"success":true,"timestamp":1590165366,"base":"EUR","date":"2020-05-22","rates":{"AED":3.999233,"AFN":83.486655,"ALL":123.604881,"AMD":524.786046,"ANG":1.953584,"AOA":630.872386,"ARS":74.229271,"AUD":1.668348,"AWG":1.959823,"AZN":1.85389,"BAM":1.952254,"BBD":2.197474,"BDT":92.576488,"BGN":1.955432,"BHD":0.41114,"BIF":2080.678568,"BMD":1.08879,"BND":1.549062,"BOB":7.515175,"BRL":6.066631,"BSD":1.088306,"BTC":0.000118,"BTN":82.609722,"BWP":12.979939,"BYN":2.612614,"BYR":21340.29301,"BZD":2.193781,"CAD":1.526571,"CDF":1976.154999,"CHF":1.058903,"CLF":0.031784,"CLP":877.01985,"CNY":7.763509,"COP":4097.58668,"CRC":619.834527,"CUC":1.08879,"CUP":28.852947,"CVE":110.239939,"CZK":27.317862,"DJF":193.500354,"DKK":7.458248,"DOP":60.493618,"DZD":140.296085,"EGP":17.272465,"ERN":16.331699,"ETB":36.964123,"EUR":1,"FJD":2.444307,"FKP":0.894286,"GBP":0.894329,"GEL":3.46782,"GGP":0.894286,"GHS":6.276854,"GIP":0.894286,"GMD":56.018475,"GNF":10299.957469,"GTQ":8.369537,"GYD":227.370784,"HKD":8.444495,"HNL":27.198641,"HRK":7.588105,"HTG":115.455209,"HUF":350.521931,"IDR":16231.089338,"ILS":3.8449,"IMP":0.894286,"INR":82.715637,"IQD":1295.116252,"IRR":45843.522405,"ISK":155.675401,"JEP":0.894286,"JMD":158.150375,"JOD":0.771945,"JPY":117.081943,"KES":116.490067,"KGS":80.18593,"KHR":4485.816661,"KMF":492.078531,"KPW":979.932009,"KRW":1353.072262,"KWD":0.336382,"KYD":0.906968,"KZT":452.650795,"LAK":9804.558157,"LBP":1647.339516,"LKR":202.103169,"LRD":216.019108,"LSL":19.260837,"LTL":3.214915,"LVL":0.658599,"LYD":1.546021,"MAD":10.763234,"MDL":19.263511,"MGA":4151.013362,"MKD":61.502335,"MMK":1529.105483,"MNT":3048.210398,"MOP":8.693475,"MRO":388.69821,"MUR":43.383083,"MVR":16.821586,"MWK":800.260883,"MXN":24.772376,"MYR":4.750939,"MZN":74.963384,"NAD":19.255251,"NGN":424.639004,"NIO":37.106631,"NOK":10.911095,"NPR":132.170876,"NZD":1.788485,"OMR":0.419177,"PAB":1.088306,"PEN":3.725293,"PGK":3.821447,"PHP":55.321991,"PKR":174.914303,"PLN":4.517228,"PYG":7200.640555,"QAR":3.964311,"RON":4.842914,"RSD":117.535101,"RUB":78.087185,"RWF":1018.01908,"SAR":4.091778,"SBD":9.092361,"SCR":19.151532,"SDG":60.21131,"SEK":10.545807,"SGD":1.552103,"SHP":0.894286,"SLL":10621.151093,"SOS":633.67585,"SRD":8.120221,"STD":24008.584242,"SVC":9.522556,"SYP":558.552831,"SZL":19.255275,"THB":34.754753,"TJS":11.152669,"TMT":3.821655,"TND":3.147027,"TOP":2.507052,"TRY":7.421522,"TTD":7.353765,"TWD":32.761391,"TZS":2518.372491,"UAH":29.141715,"UGX":4122.647808,"USD":1.08879,"UYU":46.968468,"UZS":11001.138654,"VEF":10.874295,"VND":25407.469772,"VUV":130.725437,"WST":2.986348,"XAF":654.757557,"XAG":0.063542,"XAU":0.000628,"XCD":2.942511,"XDR":0.79674,"XOF":681.582642,"XPF":119.690619,"YER":272.551527,"ZAR":19.262443,"ZMK":9800.421699,"ZMW":19.704204,"ZWL":350.590529}}';
    exchangeRate.Exchange_Rate_Collected_Date__c = System.today();
    exchangeRate.Base__c = 'EUR';
    insert exchangeRate;

    Donation_Form_Submission__c dfs = new Donation_Form_Submission__c();
    dfs.Campaign__c = camp.Id;
    dfs.City__c = 'Test City';
    dfs.Country__c = 'United States';
    dfs.Credit_Card_Type__c = 'Visa';
    dfs.Credit_Card_Exp_Date__c = '01/20';
    dfs.Credit_Card_Last_Four__c = '1111';
    dfs.Donation_Amount__c = 1;
    dfs.Email__c = 'johnny@test.com';
    dfs.First_Name__c = 'Johnny';
    dfs.Frequency__c = 'Monthly';
    dfs.Frequency_Interval__c = 1;
    dfs.Recurring_Start_Date__c = Date.today();
    dfs.Last_Name__c = 'Test';
    dfs.Organization_Donation__c = false;
    dfs.Original_Currency__c = 'USD';
    dfs.Original_Amount__c = 1;
    dfs.Original_Amount_with_Fees__c = 1.33;
    dfs.Payment_Method__c = 'Credit Card';
    dfs.Phone__c = '1234567890';
    dfs.Postal_Code__c = '12345';
    dfs.State__c = 'TN';
    dfs.Street_Address__c = '123 Test Street';
    dfs.Submission_Date__c = Date.today();
    dfs.Test_Mode_Submission__c = true;
    dfs.Total_Amount__c = 1.33;
    dfs.Will_Cover_Processing_Fees__c = true;
    dfs.Payment_Processor_Customer_Id__c = '1234567890';
    dfs.Payment_Profile_Id__c = '0987654321';
    dfs.CreatedDate = Datetime.now().addMinutes(-45);
    insert dfs;

    Donation_Option_Selection__c dos = new Donation_Option_Selection__c();
    dos.Amount__c = 1;
    dos.Original_Amount__c = 1;
    dos.Original_Currency__c = 'USD';
    dos.Donation_Form_Submission__c = dfs.Id;
    dos.Donation_Option__c = donOpt.Id;
    dos.Frequency__c = 'Monthly';
    insert dos;
  }

  @isTest
  static void testSchedule() {
    Test.startTest();
    System.schedule(
      'Auth.net Subscription Job',
      '0 0 0/1 1/1 * ? *',
      new DonationPageAuthNetSubscriptionJob(null)
    );
    Test.stopTest();
  }

  @isTest
  static void testDFSWithErrors() {
    Donation_Form_Submission__c dfs = [
      SELECT Id
      FROM Donation_Form_Submission__c
      WHERE Email__c = 'johnny@test.com'
    ];
    dfs.Errors__c = 'Has an error';
    update dfs;
    dfs = [
      SELECT Id, LastModifiedDate
      FROM Donation_Form_Submission__c
      WHERE Email__c = 'johnny@test.com'
    ];
    Datetime prevModDate = dfs.LastModifiedDate;

    Test.startTest();
    Database.executeBatch(new DonationPageAuthNetSubscriptionJob(null), 1);
    Test.stopTest();

    dfs = [
      SELECT Id, LastModifiedDate, CreatedDate
      FROM Donation_Form_Submission__c
      WHERE Email__c = 'johnny@test.com'
    ];
    System.assertEquals(prevModDate, dfs.LastModifiedDate);
  }

  @isTest
  static void testDFSWithErrorsAndIds() {
    Donation_Form_Submission__c dfs = [
      SELECT Id
      FROM Donation_Form_Submission__c
      WHERE Email__c = 'johnny@test.com'
    ];
    dfs.Errors__c = 'Has an error';
    update dfs;
    dfs = [
      SELECT Id, LastModifiedDate
      FROM Donation_Form_Submission__c
      WHERE Email__c = 'johnny@test.com'
    ];
    Datetime prevModDate = dfs.LastModifiedDate;

    Test.startTest();
    Database.executeBatch(
      new DonationPageAuthNetSubscriptionJob(new List<Id>{dfs.Id}),
      1
    );
    Test.stopTest();

    dfs = [
      SELECT Id, LastModifiedDate, CreatedDate
      FROM Donation_Form_Submission__c
      WHERE Email__c = 'johnny@test.com'
    ];
    System.assertEquals(prevModDate, dfs.LastModifiedDate);
  }

  @isTest
  static void testContactSubscription() {
    List<HttpCalloutMock> responses = new List<HttpCalloutMock>();
    Map<String, String> headers = new Map<String, String>();
    //Create Subscription Mock
    String createSubRes = '<ARBCreateSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><subscriptionId>100748</subscriptionId><profile><customerProfileId>39931060</customerProfileId><customerPaymentProfileId>36223863</customerPaymentProfileId><customerAddressId>37726371</customerAddressId></profile></ARBCreateSubscriptionResponse>';
    AuthorizeNetServiceMock createSubMock = new AuthorizeNetServiceMock(
      200,
      'Complete',
      createSubRes,
      headers
    );
    responses.add(createSubMock);
    //Create Transaction Mock
    String transactionRes = '<createTransactionResponse xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>1</responseCode><authCode>UGELQC</authCode><avsResultCode>E</avsResultCode><cavvResultCode /><transId>2148061808</transId><refTransID /><transHash>0B428D8A928AAC61121AF2F6EAC5FF3F</transHash><accountNumber>XXXX0015</accountNumber><accountType>Mastercard</accountType><message><code>1</code><description>This transaction has been approved.</description></message><userFields><userField><name>MerchantDefinedFieldName1</name><value>MerchantDefinedFieldValue1</value></userField><userField><name>favorite_color</name><value>lavender</value></userField></userFields></transactionResponse></createTransactionResponse>';
    AuthorizeNetServiceMock transactionMock = new AuthorizeNetServiceMock(
      200,
      'Complete',
      transactionRes,
      headers
    );
    responses.add(transactionMock);

    MultiRequestMock multiMock = new MultiRequestMock(responses);
    Test.setMock(HttpCalloutMock.class, multiMock);

    Contact c = new Contact();
    c.FirstName = 'Johnny';
    c.LastName = 'Test';
    c.Email = 'johnny@test.com';
    insert c;

    Customer_Profile__c cp = new Customer_Profile__c();
    cp.Customer_Profile_Id__c = '1234567890';
    cp.Payment_Profile_Id__c = '0987654321';
    cp.Contact__c = c.Id;
    insert cp;

    Donation_Form_Submission__c dfs = [
      SELECT Id
      FROM Donation_Form_Submission__c
      WHERE Email__c = 'johnny@test.com'
    ];
    Test.startTest();
    Database.executeBatch(
      new DonationPageAuthNetSubscriptionJob(new List<Id>{dfs.Id})
    );
    Test.stopTest();

    dfs = [
      SELECT
        Id,
        Payment_Processor_Subscription_Id__c,
        Payment_Processor_Transaction_Id__c
      FROM Donation_Form_Submission__c
      WHERE Id = :dfs.Id
    ][0];
    System.assert(dfs.Payment_Processor_Subscription_Id__c != null);
    System.assert(dfs.Payment_Processor_Transaction_Id__c != null);

    List<npe03__Recurring_Donation__c> recDons = [
      SELECT Id, Customer_Profile__c
      FROM npe03__Recurring_Donation__c
      WHERE Donation_Form_Submission__c = :dfs.Id
    ];
    System.assert(recDons.size() > 0);
    System.assertEquals(cp.Id, recDons[0].Customer_Profile__c);
  }

  @isTest
  static void testContactSubscriptionPurposeCode() {
    List<HttpCalloutMock> responses = new List<HttpCalloutMock>();
    Map<String, String> headers = new Map<String, String>();
    //Create Subscription Mock
    String createSubRes = '<ARBCreateSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><subscriptionId>100748</subscriptionId><profile><customerProfileId>39931060</customerProfileId><customerPaymentProfileId>36223863</customerPaymentProfileId><customerAddressId>37726371</customerAddressId></profile></ARBCreateSubscriptionResponse>';
    AuthorizeNetServiceMock createSubMock = new AuthorizeNetServiceMock(
      200,
      'Complete',
      createSubRes,
      headers
    );
    responses.add(createSubMock);
    //Create Transaction Mock
    String transactionRes = '<createTransactionResponse xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>1</responseCode><authCode>UGELQC</authCode><avsResultCode>E</avsResultCode><cavvResultCode /><transId>2148061808</transId><refTransID /><transHash>0B428D8A928AAC61121AF2F6EAC5FF3F</transHash><accountNumber>XXXX0015</accountNumber><accountType>Mastercard</accountType><message><code>1</code><description>This transaction has been approved.</description></message><userFields><userField><name>MerchantDefinedFieldName1</name><value>MerchantDefinedFieldValue1</value></userField><userField><name>favorite_color</name><value>lavender</value></userField></userFields></transactionResponse></createTransactionResponse>';
    AuthorizeNetServiceMock transactionMock = new AuthorizeNetServiceMock(
      200,
      'Complete',
      transactionRes,
      headers
    );
    responses.add(transactionMock);

    MultiRequestMock multiMock = new MultiRequestMock(responses);
    Test.setMock(HttpCalloutMock.class, multiMock);

    Contact c = new Contact();
    c.FirstName = 'Johnny';
    c.LastName = 'Test';
    c.Email = 'johnny@test.com';
    insert c;

    Customer_Profile__c cp = new Customer_Profile__c();
    cp.Customer_Profile_Id__c = '1234567890';
    cp.Payment_Profile_Id__c = '0987654321';
    cp.Contact__c = c.Id;
    insert cp;

    Donation_Form_Submission__c dfs = [
      SELECT Id, GAU_Purpose_Code__c
      FROM Donation_Form_Submission__c
      WHERE Email__c = 'johnny@test.com'
    ];
    dfs.GAU_Purpose_Code__c = 'gau2';
    update dfs;

    Test.startTest();
    Database.executeBatch(
      new DonationPageAuthNetSubscriptionJob(new List<Id>{dfs.Id})
    );
    Test.stopTest();

    dfs = [
      SELECT
        Id,
        Payment_Processor_Subscription_Id__c,
        Payment_Processor_Transaction_Id__c
      FROM Donation_Form_Submission__c
      WHERE Id = :dfs.Id
    ][0];
    System.assert(dfs.Payment_Processor_Subscription_Id__c != null);
    System.assert(dfs.Payment_Processor_Transaction_Id__c != null);
  }

  @isTest
  static void testOrganizationSubscription() {
    List<HttpCalloutMock> responses = new List<HttpCalloutMock>();
    Map<String, String> headers = new Map<String, String>();
    //Create Subscription Mock
    String createSubRes = '<ARBCreateSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><subscriptionId>100748</subscriptionId><profile><customerProfileId>39931060</customerProfileId><customerPaymentProfileId>36223863</customerPaymentProfileId><customerAddressId>37726371</customerAddressId></profile></ARBCreateSubscriptionResponse>';
    AuthorizeNetServiceMock createSubMock = new AuthorizeNetServiceMock(
      200,
      'Complete',
      createSubRes,
      headers
    );
    responses.add(createSubMock);
    //Create Transaction Mock
    String transactionRes = '<createTransactionResponse xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>1</responseCode><authCode>UGELQC</authCode><avsResultCode>E</avsResultCode><cavvResultCode /><transId>2148061808</transId><refTransID /><transHash>0B428D8A928AAC61121AF2F6EAC5FF3F</transHash><accountNumber>XXXX0015</accountNumber><accountType>Mastercard</accountType><message><code>1</code><description>This transaction has been approved.</description></message><userFields><userField><name>MerchantDefinedFieldName1</name><value>MerchantDefinedFieldValue1</value></userField><userField><name>favorite_color</name><value>lavender</value></userField></userFields></transactionResponse></createTransactionResponse>';
    AuthorizeNetServiceMock transactionMock = new AuthorizeNetServiceMock(
      200,
      'Complete',
      transactionRes,
      headers
    );
    responses.add(transactionMock);

    MultiRequestMock multiMock = new MultiRequestMock(responses);
    Test.setMock(HttpCalloutMock.class, multiMock);

    Contact c = new Contact();
    c.FirstName = 'Johnny';
    c.LastName = 'Test';
    c.Email = 'johnny@test.com';
    insert c;

    Customer_Profile__c cp = new Customer_Profile__c();
    cp.Customer_Profile_Id__c = '1234567890';
    cp.Payment_Profile_Id__c = '0987654321';
    cp.Contact__c = c.Id;
    insert cp;

    Account a = new Account();
    a.Name = 'Candoris';
    insert a;

    Donation_Form_Submission__c dfs = [
      SELECT Id
      FROM Donation_Form_Submission__c
      WHERE Email__c = 'johnny@test.com'
    ];
    dfs.Organization_Donation__c = true;
    dfs.Organization_Name__c = 'Candoris';
    update dfs;

    Test.startTest();
    Database.executeBatch(
      new DonationPageAuthNetSubscriptionJob(new List<Id>{dfs.Id})
    );
    Test.stopTest();

    dfs = [
      SELECT
        Id,
        Payment_Processor_Subscription_Id__c,
        Payment_Processor_Transaction_Id__c
      FROM Donation_Form_Submission__c
      WHERE Id = :dfs.Id
    ][0];
    System.assert(dfs.Payment_Processor_Subscription_Id__c != null);
    System.assert(dfs.Payment_Processor_Transaction_Id__c != null);
  }

  @isTest
  static void testNoContact() {
    List<HttpCalloutMock> responses = new List<HttpCalloutMock>();
    Map<String, String> headers = new Map<String, String>();
    //Create Subscription Mock
    String createSubRes = '<ARBCreateSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><subscriptionId>100748</subscriptionId><profile><customerProfileId>39931060</customerProfileId><customerPaymentProfileId>36223863</customerPaymentProfileId><customerAddressId>37726371</customerAddressId></profile></ARBCreateSubscriptionResponse>';
    AuthorizeNetServiceMock createSubMock = new AuthorizeNetServiceMock(
      200,
      'Complete',
      createSubRes,
      headers
    );
    responses.add(createSubMock);
    //Create Transaction Mock
    String transactionRes = '<createTransactionResponse xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>1</responseCode><authCode>UGELQC</authCode><avsResultCode>E</avsResultCode><cavvResultCode /><transId>2148061808</transId><refTransID /><transHash>0B428D8A928AAC61121AF2F6EAC5FF3F</transHash><accountNumber>XXXX0015</accountNumber><accountType>Mastercard</accountType><message><code>1</code><description>This transaction has been approved.</description></message><userFields><userField><name>MerchantDefinedFieldName1</name><value>MerchantDefinedFieldValue1</value></userField><userField><name>favorite_color</name><value>lavender</value></userField></userFields></transactionResponse></createTransactionResponse>';
    AuthorizeNetServiceMock transactionMock = new AuthorizeNetServiceMock(
      200,
      'Complete',
      transactionRes,
      headers
    );
    responses.add(transactionMock);

    MultiRequestMock multiMock = new MultiRequestMock(responses);
    Test.setMock(HttpCalloutMock.class, multiMock);

    Donation_Form_Submission__c dfs = [
      SELECT Id
      FROM Donation_Form_Submission__c
      WHERE Email__c = 'johnny@test.com'
    ];
    Test.startTest();
    Database.executeBatch(
      new DonationPageAuthNetSubscriptionJob(new List<Id>{dfs.Id})
    );
    Test.stopTest();

    dfs = [
      SELECT
        Id,
        Payment_Processor_Subscription_Id__c,
        Payment_Processor_Transaction_Id__c
      FROM Donation_Form_Submission__c
      WHERE Id = :dfs.Id
    ][0];
    System.assert(dfs.Payment_Processor_Subscription_Id__c != null);
    System.assert(dfs.Payment_Processor_Transaction_Id__c != null);

    List<npe03__Recurring_Donation__c> recDons = [
      SELECT Id, Customer_Profile__c
      FROM npe03__Recurring_Donation__c
      WHERE Donation_Form_Submission__c = :dfs.Id
    ];
    System.assert(recDons.size() > 0);
  }

  @isTest
  static void testNoAccount() {
    List<HttpCalloutMock> responses = new List<HttpCalloutMock>();
    Map<String, String> headers = new Map<String, String>();
    //Create Subscription Mock
    String createSubRes = '<ARBCreateSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><subscriptionId>100748</subscriptionId><profile><customerProfileId>39931060</customerProfileId><customerPaymentProfileId>36223863</customerPaymentProfileId><customerAddressId>37726371</customerAddressId></profile></ARBCreateSubscriptionResponse>';
    AuthorizeNetServiceMock createSubMock = new AuthorizeNetServiceMock(
      200,
      'Complete',
      createSubRes,
      headers
    );
    responses.add(createSubMock);
    //Create Transaction Mock
    String transactionRes = '<createTransactionResponse xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>1</responseCode><authCode>UGELQC</authCode><avsResultCode>E</avsResultCode><cavvResultCode /><transId>2148061808</transId><refTransID /><transHash>0B428D8A928AAC61121AF2F6EAC5FF3F</transHash><accountNumber>XXXX0015</accountNumber><accountType>Mastercard</accountType><message><code>1</code><description>This transaction has been approved.</description></message><userFields><userField><name>MerchantDefinedFieldName1</name><value>MerchantDefinedFieldValue1</value></userField><userField><name>favorite_color</name><value>lavender</value></userField></userFields></transactionResponse></createTransactionResponse>';
    AuthorizeNetServiceMock transactionMock = new AuthorizeNetServiceMock(
      200,
      'Complete',
      transactionRes,
      headers
    );
    responses.add(transactionMock);

    MultiRequestMock multiMock = new MultiRequestMock(responses);
    Test.setMock(HttpCalloutMock.class, multiMock);

    Donation_Form_Submission__c dfs = [
      SELECT Id, Organization_Donation__c, Organization_Name__c
      FROM Donation_Form_Submission__c
      WHERE Email__c = 'johnny@test.com'
    ];
    dfs.Organization_Donation__c = true;
    dfs.Organization_Name__c = 'Candoris';
    update dfs;

    Contact c = new Contact();
    c.FirstName = 'Johnny';
    c.LastName = 'Test';
    c.Email = 'johnny@test.com';
    insert c;

    Test.startTest();
    Database.executeBatch(
      new DonationPageAuthNetSubscriptionJob(new List<Id>{dfs.Id})
    );
    Test.stopTest();

    dfs = [
      SELECT Id, Errors__c
      FROM Donation_Form_Submission__c
      WHERE Id = :dfs.Id
    ][0];
    System.assert(dfs.Errors__c != null);
    System.assertEquals(
      dfs.Errors__c,
      'DonationPageAuthNetSubscriptionHandler: No matching account found'
    );
  }
}