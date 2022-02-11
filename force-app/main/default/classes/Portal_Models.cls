public inherited sharing class Portal_Models {
  @AuraEnabled
  public static Id newProfileUpdate(Id contactId){
    Requested_Profile_Update__c rpu = new Requested_Profile_Update__c(
      Contact__c = contactId,
      Update_Status__c = 'Pending'
    );
    insert rpu;
    return rpu.Id;
  }

  public class PicklistInfo {
    @AuraEnabled public List<MySelectOption> picklistValues;

    public PicklistInfo(){
      this.picklistValues = new List<MySelectOption>();
    }
  }
  public class MySelectOption {
    @AuraEnabled public String label;
    @AuraEnabled public String value;

    public MySelectOption(String l, String v){
      this.label = l;
      this.value = v;
    }
  }
  public class ReceiptInfo {
    @AuraEnabled public Id acctId;
    @AuraEnabled public Id templateId;
    @AuraEnabled public Id questOneId;
    @AuraEnabled public Id questTwoId;

    public ReceiptInfo(){
      this.acctId = null;
      this.templateId = null;
      this.questOneId = null;
      this.questTwoId = null;
    }
  }
  public class Gift {
    @AuraEnabled public String id;
    @AuraEnabled public String oppId;
    @AuraEnabled public Date closeDate;
    @AuraEnabled public String paymentMethod;
    @AuraEnabled public String fund;
    @AuraEnabled public Decimal amount;
    @AuraEnabled public String currencyType;
    @AuraEnabled public List<ExtraGiftAllocation> additionalAllocations;

    public Gift(npsp__Allocation__c alloc, Opportunity opp) {
      this.id = alloc.Id;
      this.oppId = opp.Id;
      this.closeDate = alloc.Close_Date__c;
      this.amount = alloc.Original_Amount__c;
      this.currencyType = alloc.Original_Currency__c;
      this.fund = alloc.npsp__General_Accounting_Unit__r.Name;
      this.paymentMethod = opp.Payment_Method__c;
      this.additionalAllocations = new List<ExtraGiftAllocation>();
    }
  }
  public class ExtraGiftAllocation {
    @AuraEnabled public String fund;
    @AuraEnabled public Decimal amount;
    @AuraEnabled public String currencyType;

    public ExtraGiftAllocation(npsp__Allocation__c alloc){
      this.fund = alloc.npsp__General_Accounting_Unit__r.Name;
      this.amount = alloc.Original_Amount__c;
      this.currencyType = alloc.Original_Currency__c;
    }
  }
  public class ProfileInfo {
    @AuraEnabled public String Id;
    @AuraEnabled public String AccountId;
    @AuraEnabled public String rpuId;
    @AuraEnabled public String Salutation;
    @AuraEnabled public String FirstName;
    @AuraEnabled public String LastName;
    @AuraEnabled public String Suffix;
    @AuraEnabled public String PreferredPhone;
    @AuraEnabled public String HomePhone;
    @AuraEnabled public String WorkPhone;
    @AuraEnabled public String MobilePhone;
    @AuraEnabled public String PreferredEmail;
    @AuraEnabled public String PersonalEmail;
    @AuraEnabled public String WorkEmail;
    @AuraEnabled public String AlternateEmail;
    @AuraEnabled public String MailingCountry;
    @AuraEnabled public String MailingStreet;
    @AuraEnabled public String MailingCity;
    @AuraEnabled public String MailingState;
    @AuraEnabled public String MailingPostalCode;
    @AuraEnabled public String Receipt;
    @AuraEnabled public String Language;
    
    public ProfileInfo(Contact con){
      Requested_Profile_Update__c rpu = !con.Requested_Profile_Updates__r.isEmpty() ? con.Requested_Profile_Updates__r[0] : null;
      this.id = con.Id;
      this.AccountId = con.AccountId;
      this.rpuId = rpu != null ? rpu.Id : newProfileUpdate(con.Id);
      this.Salutation = rpu != null && String.isNotBlank(rpu.Prefix__c)
        ? String.valueOf(rpu.Prefix__c)
        : con.Salutation;
      this.FirstName = rpu != null && String.isNotBlank(rpu.First_Name__c)
        ? String.valueOf(rpu.First_Name__c)
        : con.FirstName;
      this.LastName = rpu != null && String.isNotBlank(rpu.Last_Name__c)
        ? String.valueOf(rpu.Last_Name__c)
        : con.LastName;
      this.Suffix = rpu != null && String.isNotBlank(rpu.Suffix__c)
        ? String.valueOf(rpu.Suffix__c)
        : con.Suffix;
      this.PreferredPhone = rpu != null && String.isNotBlank(rpu.Preferred_Phone__c)
        ? String.valueOf(rpu.Preferred_Phone__c)
        : con.npe01__PreferredPhone__c;
      this.HomePhone = rpu != null && String.isNotBlank(rpu.Home_Phone__c)
        ? String.valueOf(rpu.Home_Phone__c)
        : con.HomePhone;
      this.WorkPhone = rpu != null && String.isNotBlank(rpu.Work_Phone__c)
        ? String.valueOf(rpu.Work_Phone__c)
        : con.npe01__WorkPhone__c;
      this.MobilePhone = rpu != null && String.isNotBlank(rpu.Mobile_Phone__c)
        ? String.valueOf(rpu.Mobile_Phone__c)
        : con.MobilePhone;
      this.PreferredEmail = rpu != null && String.isNotBlank(rpu.Preferred_Email__c)
        ? String.valueOf(rpu.Preferred_Email__c)
        : con.npe01__Preferred_Email__c;
      this.PersonalEmail = rpu != null && String.isNotBlank(rpu.Personal_Email__c)
        ? String.valueOf(rpu.Personal_Email__c)
        : con.npe01__HomeEmail__c;
      this.WorkEmail = rpu != null && String.isNotBlank(rpu.Work_Email__c)
        ? String.valueOf(rpu.Work_Email__c)
        : con.npe01__WorkEmail__c;
      this.AlternateEmail = rpu != null && String.isNotBlank(rpu.Alternate_Email__c)
        ? String.valueOf(rpu.Alternate_Email__c)
        : con.npe01__AlternateEmail__c;
      this.MailingCountry = rpu != null && String.isNotBlank(rpu.Country__c)
        ? String.valueOf(rpu.Country__c)
        : con.MailingCountry;
      this.MailingStreet = rpu != null && String.isNotBlank(rpu.Street__c)
        ? String.valueOf(rpu.Street__c)
        : con.MailingStreet;
      this.MailingCity = rpu != null && String.isNotBlank(rpu.City__c)
        ? String.valueOf(rpu.City__c)
        : con.MailingCity;
      this.MailingState = rpu != null && String.isNotBlank(rpu.State__c)
        ? String.valueOf(rpu.State__c)
        : con.MailingState;
      this.MailingPostalCode = rpu != null && String.isNotBlank(rpu.Postal_Code__c)
        ? String.valueOf(rpu.Postal_Code__c)
        : con.MailingPostalCode;
      this.Receipt = con.Account.Receipt_Type__c;
      this.Language = con.Account.Language_Preference__c;
    }
  }
  public class DonationPageInfo {
    @AuraEnabled public Contact contact;
    @AuraEnabled public PicklistInfo currencyTypes;
    @AuraEnabled public List<SelectedFundInfo> selectedFunds;
    @AuraEnabled public List<PaymentMethodInfo> paymentMethods;
    @AuraEnabled public ExchangeRateInfo exchangeRates;
    @AuraEnabled public Opportunity previousOpp;
    @AuraEnabled public Boolean processingFees;

    public DonationPageInfo(){
      this.contact = null;
      this.currencyTypes = null;
      this.selectedFunds = new List<SelectedFundInfo>();
      this.paymentMethods = new List<PaymentMethodInfo>();
      this.exchangeRates = new ExchangeRateInfo();
      this.previousOpp = null;
      this.processingFees = false;
    }
  }
  public class ExchangeRateInfo {
    @AuraEnabled public Decimal USD;
    @AuraEnabled public Decimal CAD;
    @AuraEnabled public Decimal EUR;
    @AuraEnabled public Decimal GBP;
    @AuraEnabled public Decimal INR;
    @AuraEnabled public Decimal KES;
    @AuraEnabled public String errors;

    public ExchangeRateInfo(){
      List<Currency_Exchange_Rate__c> currencyExchangeRates = [
        SELECT Api_Response__c, Id
        FROM Currency_Exchange_Rate__c
        WHERE Base__c = 'EUR'
        ORDER BY Exchange_Rate_Collected_Date__c DESC, CreatedDate DESC
        LIMIT 1
      ];
      
      if (!currencyExchangeRates.isEmpty()){
        Currency_Exchange_Rate__c currencyExchangeRate = currencyExchangeRates[0];
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(
          currencyExchangeRate.Api_Response__c
        );
        
        Map<String, Object> rates = (Map<String, Object>) resultMap.get('rates');

        this.USD = !rates.isEmpty() && rates.containsKey('USD') ? (Decimal) rates.get('USD') : null;
        this.CAD = !rates.isEmpty() && rates.containsKey('CAD') ? (Decimal) rates.get('CAD') : null;
        this.EUR = !rates.isEmpty() && rates.containsKey('EUR') ? (Decimal) rates.get('EUR') : null;
        this.GBP = !rates.isEmpty() && rates.containsKey('GBP') ? (Decimal) rates.get('GBP') : null;
        this.INR = !rates.isEmpty() && rates.containsKey('INR') ? (Decimal) rates.get('INR') : null;
        this.KES = !rates.isEmpty() && rates.containsKey('KES') ? (Decimal) rates.get('KES') : null;
      } 
      
      else {
        this.errors = 'No Currency Exchange Rate records found.';
      }
    }
  }
  public class SelectedFundInfo {
    @AuraEnabled public Id id;
    @AuraEnabled public String name;
    @AuraEnabled public Decimal percent;
    @AuraEnabled public Double amount;
  }
  public class PaymentMethodInfo {
    @AuraEnabled public String id;
    @AuraEnabled public String customerId;
    @AuraEnabled public String label;
    @AuraEnabled public String paymentMethod;
    @AuraEnabled public String cardType;
    @AuraEnabled public String cardLastFour;
    @AuraEnabled public String expirationDate;
    @AuraEnabled public String bankName;
    @AuraEnabled public String accountNumber;
    @AuraEnabled public String routingNumber;
    @AuraEnabled public List<String> subscriptionIds;
    @AuraEnabled public Boolean hasActiveSubscription;

    public PaymentMethodInfo(){
      this.id = null;
      this.customerId = null;
      this.label = null;
      this.paymentMethod = null;
      this.cardType = null;
      this.cardLastFour = null;
      this.expirationDate = null;
      this.bankName = null;
      this.accountNumber = null;
      this.routingNumber = null;
      this.subscriptionIds = new List<String>();
      this.hasActiveSubscription = false;
    }
  }
  public class SubmissionInfo {
    @AuraEnabled public Contact contact;
    @AuraEnabled public Boolean coverFees;
    @AuraEnabled public Double subtotal;
    @AuraEnabled public Double total;
    @AuraEnabled public String frequency;
    @AuraEnabled public String currencyType;
    @AuraEnabled public String startDate;
    @AuraEnabled public String selectedFund;
    @AuraEnabled public List<SelectedFundInfo> selectedFunds;
    @AuraEnabled public PaymentMethodInfo paymentMethod;
  }
  public class SubscriptionInfo {
    @AuraEnabled public String id;
    @AuraEnabled public String status;
    @AuraEnabled public String paymentMethod;
    @AuraEnabled public String cardNumber;
    @AuraEnabled public String expirationMonth;
    @AuraEnabled public String expirationYear;
    @AuraEnabled public String accountNumber;
    @AuraEnabled public String routingNumber;
    @AuraEnabled public Double amount;
    @AuraEnabled public String selectedCurrency;
    @AuraEnabled public Date startDate;
    @AuraEnabled public Date endDate;
    @AuraEnabled public String installmentPeriod; //i.e. Weekly, Monthly, Yearly
    @AuraEnabled public Integer installmentFrequency; //i.e. 1, 2, 3 (ex Every 1 Month)
  }


  // Used for test classes
  public static AuthorizeNetModels.getCustomerPaymentProfileResponse returnGetCustomerPaymentProfileResponse(){
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
      x += '        <expirationDate>03-2023</expirationDate>';
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

    AuthorizeNetModels.getCustomerPaymentProfileResponse res =
      new AuthorizeNetModels.getCustomerPaymentProfileResponse(httpResponse);

    return res;
  }
  public static AuthorizeNetModels.createCustomerPaymentProfileResponse returnCreateCustomerPaymentProfileResponse(){
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

    return response;
  }
  public static AuthorizeNetModels.getCustomerProfileResponse returnGetCustomerProfileResponse() {
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

    AuthorizeNetModels.getCustomerProfileResponse resp =
        new AuthorizeNetModels.getCustomerProfileResponse(httpResponse);

    return resp;
  }
  public static AuthorizeNetModels.createCustomerProfileResponse returnCreateCustomerProfileResponse(){
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

    return ccpr;
  }
  public static AuthorizeNetModels.ARBGetSubscriptionResponse returnGetSubscriptionResponse(){
    String xr = '<ARBGetSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><refId>Sample</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><subscription><name>Sample subscription</name><paymentSchedule><interval><length>1</length><unit>months</unit></interval><startDate>2020-12-30</startDate><totalOccurrences>12</totalOccurrences><trialOccurrences>1</trialOccurrences></paymentSchedule><amount>10.29</amount><trialAmount>0.00</trialAmount><status>active</status><profile><description>Profile created by Subscription: 2930242</description><customerProfileId>37978171</customerProfileId><paymentProfile><customerType>individual</customerType><billTo><firstName>John</firstName><lastName>Smith</lastName></billTo><customerPaymentProfileId>34531293</customerPaymentProfileId><payment><creditCard><cardNumber>XXXX1111</cardNumber><expirationDate>XXXX</expirationDate></creditCard></payment></paymentProfile></profile></subscription></ARBGetSubscriptionResponse>';
    
    HttpResponse httpResponse = new HttpResponse();
    httpResponse.setBody(xr);

    AuthorizeNetModels.ARBGetSubscriptionResponse res = 
        new AuthorizeNetModels.ARBGetSubscriptionResponse(httpResponse);
    
    return res;
  }
  public static AuthorizeNetModels.ARBUpdateSubscriptionResponse returnUpdateSubscriptionResponse(){
    String xr = '<ARBUpdateSubscriptionResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>Sample</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><profile><customerProfileId>247150</customerProfileId><customerPaymentProfileId>215472</customerPaymentProfileId><customerAddressId>189691</customerAddressId></profile></ARBUpdateSubscriptionResponse>';

    HttpResponse httpResponse = new HttpResponse();
    httpResponse.setBody(xr);

    AuthorizeNetModels.ARBUpdateSubscriptionResponse res = 
        new AuthorizeNetModels.ARBUpdateSubscriptionResponse(httpResponse);
    
    return res;
  }
}