@isTest
private class DonationPageAuthNetPaymentServiceTest {
  private static DonationPageModels.FormSubmission fs;

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

    Donation_Form_Submission__c dfs = new Donation_Form_Submission__c();
    dfs.Total_Amount__c = 1;
    dfs.Billing_First_Name__c = 'Johnny';
    dfs.Billing_Last_Name__c = 'Test';
    dfs.Billing_Email__c = 'johnny@test.com';
    dfs.Billing_Phone__c = '1234567890';
    dfs.Billing_Street_Address__c = '123 Test Street';
    dfs.Billing_City__c = 'Test City';
    dfs.Billing_State__c = 'TN';
    dfs.Billing_Postal_Code__c = '12345';
    dfs.Billing_Country__c = 'United States';
    dfs.Frequency__c = 'Monthly';
    dfs.Frequency_Interval__c = 1;
    dfs.Original_Currency__c = 'USD';
    dfs.Recurring_Start_Date_String__c =
      Date.today().year() +
      '-' +
      Date.today().month() +
      '-' +
      Date.today().day();
    dfs.Number_of_Recurring_Payments__c = 12;
    insert dfs;
  }

  @isTest
  static void testOneTimePayment() {
    String response = '<createTransactionResponse xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>1</responseCode><authCode>UGELQC</authCode><avsResultCode>E</avsResultCode><cavvResultCode /><transId>2148061808</transId><refTransID /><transHash>0B428D8A928AAC61121AF2F6EAC5FF3F</transHash><accountNumber>XXXX0015</accountNumber><accountType>Mastercard</accountType><message><code>1</code><description>This transaction has been approved.</description></message><userFields><userField><name>MerchantDefinedFieldName1</name><value>MerchantDefinedFieldValue1</value></userField><userField><name>favorite_color</name><value>lavender</value></userField></userFields></transactionResponse></createTransactionResponse>';
    Map<String, String> headers = new Map<String, String>();
    AuthorizeNetServiceMock mock = new AuthorizeNetServiceMock(
      200,
      'Complete',
      response,
      headers
    );
    Test.setMock(HttpCalloutMock.class, mock);

    Donation_Form_Submission__c dfs = [
      SELECT
        Id,
        Total_Amount__c,
        Billing_First_Name__c,
        Billing_Last_Name__c,
        Billing_Email__c,
        Billing_Phone__c,
        Billing_Street_Address__c,
        Billing_City__c,
        Billing_State__c,
        Billing_Postal_Code__c,
        Billing_Country__c,
        Original_Currency__c
      FROM Donation_Form_Submission__c
      WHERE Billing_Email__c = 'johnny@test.com'
    ][0];
    fs = new DonationPageModels.FormSubmission();
    fs.dfs = dfs;
    fs.authNetOpaqueDataDescriptor = 'descriptor';
    fs.authNetOpaqueDataDataValue = 'value';

    DonationPageModels.PaymentResponse res = new DonationPageModels.PaymentResponse();

    Test.startTest();
    DonationPageAuthNetPaymentService service = new DonationPageAuthNetPaymentService();
    service.enableTestMode();
    service.setPaymentSettings('Sandbox');
    res = service.createOneTimePayment(fs, res);
    Test.stopTest();

    System.assertEquals(true, res.success);
    System.assertEquals('2148061808', res.transactionId);
    System.assertEquals('Approved', res.status);
  }

  @isTest
  static void testRecurringPayment() {
    List<HttpCalloutMock> responses = new List<HttpCalloutMock>();
    //Create Customer Profile Mock
    String profileRes = '<createCustomerProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><customerProfileId>10000</customerProfileId><customerPaymentProfileIdList><numericString>20000</numericString><numericString>20001</numericString></customerPaymentProfileIdList><customerShippingAddressIdList><numericString>30000</numericString><numericString>30001</numericString></customerShippingAddressIdList><validationDirectResponseList><string>1,1,1,This transaction has been approved.,000000,Y,2000000000,none,Test transaction for ValidateCustomerPaymentProfile.,0.01,CC,auth_only,custId123, John,Doe,,123 Main St.,Bellevue,WA,98004,USA,000-000-0000,,mark@example.com,,,,,,,,,0.00,0.00,0.00,,none, D18EB6B211FE0BBF556B271FDA6F92EE,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,</string></validationDirectResponseList>  </createCustomerProfileResponse>';
    Map<String, String> headers = new Map<String, String>();
    AuthorizeNetServiceMock profilemock = new AuthorizeNetServiceMock(
      300,
      'Error',
      profileRes,
      headers
    );
    responses.add(profilemock);

    MultiRequestMock multiMock = new MultiRequestMock(responses);
    Test.setMock(HttpCalloutMock.class, multiMock);

    Donation_Form_Submission__c dfs = [
      SELECT
        Id,
        Total_Amount__c,
        Frequency__c,
        Frequency_Interval__c,
        Recurring_Start_Date_String__c,
        Number_of_Recurring_Payments__c,
        Billing_First_Name__c,
        Billing_Last_Name__c,
        Billing_Email__c,
        Billing_Phone__c,
        Billing_Street_Address__c,
        Billing_City__c,
        Billing_State__c,
        Billing_Postal_Code__c,
        Billing_Country__c,
        Original_Currency__c
      FROM Donation_Form_Submission__c
      WHERE Billing_Email__c = 'johnny@test.com'
    ][0];
    fs = new DonationPageModels.FormSubmission();
    fs.dfs = dfs;
    fs.authNetOpaqueDataDescriptor = 'descriptor';
    fs.authNetOpaqueDataDataValue = 'value';

    DonationPageModels.PaymentResponse res = new DonationPageModels.PaymentResponse();

    Test.startTest();
    DonationPageAuthNetPaymentService service = new DonationPageAuthNetPaymentService();
    service.enableTestMode();
    service.setPaymentSettings('Sandbox');
    res = service.createRecurringPayment(fs, res);
    Test.stopTest();

    System.assertEquals(true, res.success);
  }
}