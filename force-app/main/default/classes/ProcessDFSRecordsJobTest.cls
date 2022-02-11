@isTest
public without sharing class ProcessDFSRecordsJobTest {
  @testSetup
  static void createData() {
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test GAU';
    gau.Purpose_Code__c = '123';
    insert gau;

    Donation_Form_Settings__c dfSettings = new Donation_Form_Settings__c();
    dfSettings.Coverage_Fees_Fund_Id__c = gau.Id;
    insert dfSettings;

    Campaign camp = new Campaign();
    camp.Name = '12345 - Test Campaign';
    camp.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName()
      .get('Donation Page')
      .getRecordTypeId();
    insert camp;

    Donation_Page_Settings__c dps = [
      SELECT
        Id,
        Payment_Processor__c,
        Test_Mode__c,
        Allow_Multiple_Designations__c,
        Donation_Page_Title__c
      FROM Donation_Page_Settings__c
      WHERE Campaign__c = :camp.Id
    ][0];
    dps.Payment_Processor__c = 'Test';
    dps.Test_Mode__c = true;
    dps.Allow_Multiple_Designations__c = false;
    dps.Donation_Page_Title__c = 'Page Title';
    update dps;

    Donation_Option__c donOpt = new Donation_Option__c();
    donOpt.Active__c = true;
    donOpt.Amount__c = 1;
    donOpt.Donation_Page_Settings__c = dps.Id;
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
    dfs.Campaign_Input__c = '12345';
    dfs.City__c = 'Test City';
    dfs.Selected_Country__c = 'United States';
    dfs.Credit_Card_Type__c = 'Visa';
    dfs.Credit_Card_Exp_Date__c = '01/20';
    dfs.Credit_Card_Last_Four__c = '1111';
    dfs.Donation_Amount__c = 1;
    dfs.Email__c = 'johnny@test.com';
    dfs.First_Name__c = 'Johnny';
    dfs.Frequency__c = 'One-time';
    dfs.Frequency_Interval__c = 1;
    dfs.Last_Name__c = 'Test';
    dfs.Organization_Donation__c = false;
    dfs.Original_Currency__c = 'USD';
    dfs.Original_Amount__c = 1;
    dfs.Original_Amount_with_Fees__c = 1.33;
    dfs.Payment_Method__c = 'Credit Card';
    dfs.Payment_Processor_Transaction_Id__c = 'ch_1234567890';
    dfs.Phone__c = '1234567890';
    dfs.Postal_Code__c = '12345';
    dfs.Send_Email_Receipt__c = true;
    dfs.State__c = 'TN';
    dfs.Street_Address__c = '123 Test Street';
    dfs.Submission_Date__c = Date.today();
    dfs.Test_Mode_Submission__c = true;
    dfs.Total_Amount__c = 1.33;
    dfs.Will_Cover_Processing_Fees__c = true;
    insert dfs;

    Donation_Option_Selection__c dos = new Donation_Option_Selection__c();
    dos.Amount__c = 1;
    dos.Original_Amount__c = 1;
    dos.Original_Currency__c = 'USD';
    dos.Donation_Form_Submission__c = dfs.Id;
    dos.Donation_Option__c = donOpt.Id;
    insert dos;
  }

  public static String getQueryFields() {
    Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Donation_Form_Submission__c.fields.getMap();
    List<String> fields = new List<String>();
    for (Schema.SObjectField sObjField : fieldMap.values()) {
      Schema.DescribeFieldResult dfr = sObjField.getDescribe();
      fields.add(dfr.getName());
    }
    return String.join(fields, ',');
  }

  @isTest
  static void testJob() {
    Donation_Form_Submission__c dfs = [
      SELECT Id, First_Name__c, Last_Name__c, Email__c
      FROM Donation_Form_Submission__c
      WHERE Email__c = 'johnny@test.com'
    ][0];
    Test.startTest();
    Database.executeBatch(new ProcessDFSRecordsJob());
    Test.stopTest();
    List<Contact> con = [
      SELECT Id, FirstName, LastName, npe01__HomeEmail__c, AccountId
      FROM Contact
      WHERE npe01__HomeEmail__c = :dfs.Email__c
    ];
    System.assertEquals(1, con.size());
    System.assertEquals(dfs.First_Name__c, con[0].FirstName);
    System.assertEquals(dfs.Last_Name__c, con[0].LastName);
    System.assertEquals(dfs.Email__c, con[0].npe01__HomeEmail__c);
    List<npe03__Recurring_Donation__c> rd = [
      SELECT Id, npe03__Contact__c
      FROM npe03__Recurring_Donation__c
      WHERE Donation_Form_Submission__c = :dfs.Id
    ];
    System.assertEquals(0, rd.size());
    List<Opportunity> opp = [
      SELECT Id, AccountId, StageName
      FROM Opportunity
      WHERE Donation_Form_Submission__c = :dfs.Id
    ];
    System.assertEquals(1, opp.size());
    System.assertEquals('Test Mode', opp[0].StageName);
    System.assertEquals(con[0].AccountId, opp[0].AccountId);
    List<npsp__Allocation__c> allocs = [
      SELECT Id
      FROM npsp__Allocation__c
      WHERE npsp__Opportunity__c = :opp[0].Id
    ];
    System.assertEquals(1, allocs.size());
    List<npe01__OppPayment__c> payments = [
      SELECT Id
      FROM npe01__OppPayment__c
      WHERE npe01__Opportunity__c = :opp[0].Id
    ];
    System.assertEquals(1, payments.size());
  }

  @isTest
  static void testJobInvalidDFS() {
    Donation_Form_Submission__c dfs = [
      SELECT Id, First_Name__c, Last_Name__c, Email__c, Errors__c
      FROM Donation_Form_Submission__c
      WHERE Email__c = 'johnny@test.com'
    ][0];
    dfs.Errors__c = 'Has an error';
    update dfs;

    Test.startTest();
    ProcessDFSRecordsJob.schedule();
    ProcessDFSRecordsJob.unschedule();
    Database.executeBatch(new ProcessDFSRecordsJob());
    Test.stopTest();
    List<Contact> con = [
      SELECT Id, FirstName, LastName, npe01__HomeEmail__c, AccountId
      FROM Contact
      WHERE npe01__HomeEmail__c = :dfs.Email__c
    ];
    System.assertEquals(0, con.size());

    List<npe03__Recurring_Donation__c> rd = [
      SELECT Id, npe03__Contact__c
      FROM npe03__Recurring_Donation__c
      WHERE Donation_Form_Submission__c = :dfs.Id
    ];
    System.assertEquals(0, rd.size());

    List<Opportunity> opp = [
      SELECT Id, AccountId, StageName
      FROM Opportunity
      WHERE Donation_Form_Submission__c = :dfs.Id
    ];
    System.assertEquals(0, opp.size());

    dfs = [
      SELECT Id, Has_Errors__c, Opportunity__c
      FROM Donation_Form_Submission__c
      WHERE Email__c = 'johnny@test.com'
    ][0];
    System.assertEquals(null, dfs.Opportunity__c);
    System.assertEquals(true, dfs.Has_Errors__c);
  }
}