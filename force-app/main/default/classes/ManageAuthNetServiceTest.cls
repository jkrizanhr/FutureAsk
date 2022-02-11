@isTest
public class ManageAuthNetServiceTest {
  public static void setupCurrencyExchange() {
    /*
     * Create the currency exchange rate data so that the opportunity trigger does not
     * throw an error
     */
    Fixer_Settings__c fixerSettings = new Fixer_Settings__c();
    fixerSettings.API_Key__c = '123';
    insert fixerSettings;

    Decimal usdRate = 1.10385;
    Decimal gbpRate = 0.855313;

    Currency_Exchange_Rate__c rate = new Currency_Exchange_Rate__c();
    rate.API_Response__c = CurrencyExchangeRateTestHelper.getResponseString(
      'EUR',
      usdRate,
      gbpRate
    );
    rate.Base__c = 'EUR';
    rate.Exchange_Rate_Collected_Date__c = Date.today();
    insert rate;
  }

  public static void setupRecurringDonation() {
    Account account = new Account(Name = 'Test Account');
    insert account;
    npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
      Name = 'Test Recurring Donation',
      npe03__Installment_Period__c = 'Monthly',
      npsp__InstallmentFrequency__c = 1,
      npe03__Organization__c = account.Id,
      npsp__PaymentMethod__c = 'Credit Card',
      npe03__Amount__c = 100,
      npsp__Status__c = 'Active',
      Subscription_Id__c = '4818507'
    );
    insert rd;
  }

  public static void setupOpportunity() {
    Opportunity opp = new Opportunity();
    opp.Name = 'Test CC Opp';
    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
      .get('Donation')
      .getRecordTypeId();
    opp.Transaction_Id__c = 'old123';
    opp.Amount = 2.00;
    opp.StageName = 'Closed Won';
    opp.CloseDate = Date.today();
    opp.Credit_Card_Last_Four__c = 15;
    opp.Credit_Card_Exp_Date__c = 'XXXX';
    opp.Payment_Method__c = 'Credit Card';
    insert opp;

    opp = new Opportunity();
    opp.Name = 'Test Bank Opp';
    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
      .get('Donation')
      .getRecordTypeId();
    opp.Transaction_Id__c = 'old123';
    opp.Amount = 2.00;
    opp.StageName = 'Closed Won';
    opp.CloseDate = Date.today();
    opp.Payment_Method__c = 'Bank Account';
    opp.Bank_Account_Type__c = 'checking';
    insert opp;
  }

  public static void setupAuthService() {
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
  }

  @isTest
  static void testResolveInterval() {
    ManageAuthNetService.Installment installment = new ManageAuthNetService.Installment();
    AuthorizeNetModels.paymentScheduleTypeInterval interval;

    installment.period = 'Weekly';
    installment.frequency = 3;
    interval = ManageAuthNetService.resolveInterval(installment);
    System.assertEquals('days', interval.unit);
    System.assertEquals(21, interval.length);

    installment.period = 'Monthly';
    installment.frequency = 2;
    interval = ManageAuthNetService.resolveInterval(installment);
    System.assertEquals('months', interval.unit);
    System.assertEquals(2, interval.length);

    installment.period = 'Yearly';
    installment.frequency = 3;
    interval = ManageAuthNetService.resolveInterval(installment);
    System.assertEquals('months', interval.unit);
    System.assertEquals(36, interval.length);

    ManageAuthNetService.AuthNetServiceException testE;
    installment.period = 'Wrong';
    try {
      interval = ManageAuthNetService.resolveInterval(installment);
    } catch (ManageAuthNetService.AuthNetServiceException e) {
      testE = e;
    }
    System.assertNotEquals(null, testE);
  }

  @isTest
  static void testResolveInstallment() {
    AuthorizeNetModels.paymentScheduleTypeInterval interval = new AuthorizeNetModels.paymentScheduleTypeInterval();
    ManageAuthNetService.Installment installment;

    interval.unit = 'days';
    interval.length = 7;
    installment = ManageAuthNetService.resolveInstallment(interval);
    System.assertEquals('Weekly', installment.period);
    System.assertEquals(1, installment.frequency);

    interval.unit = 'months';
    interval.length = 3;
    installment = ManageAuthNetService.resolveInstallment(interval);
    System.assertEquals('Monthly', installment.period);
    System.assertEquals(3, installment.frequency);

    interval.unit = 'months';
    interval.length = 36;
    installment = ManageAuthNetService.resolveInstallment(interval);
    System.assertEquals('Yearly', installment.period);
    System.assertEquals(3, installment.frequency);

    ManageAuthNetService.AuthNetServiceException testE;
    interval.unit = 'wrong';
    try {
      installment = ManageAuthNetService.resolveInstallment(interval);
    } catch (ManageAuthNetService.AuthNetServiceException e) {
      testE = e;
    }
    System.assertNotEquals(null, testE);
  }

  @isTest
  static void testResolveSubscriptionDates() {
    AuthorizeNetModels.paymentScheduleType schedule = new AuthorizeNetModels.paymentScheduleType();
    schedule.interval = new AuthorizeNetModels.paymentScheduleTypeInterval();

    schedule.startDate = '2020-01-01';
    schedule.totalOccurrences = 3;
    schedule.interval.unit = 'days';
    schedule.interval.length = 7;
    System.assertEquals(
      Date.newInstance(2020, 1, 22),
      ManageAuthNetService.resolveSubscriptionDates(schedule).endDate
    );

    schedule.startDate = '2020-01-01';
    schedule.totalOccurrences = 9999;
    schedule.interval.unit = 'days';
    schedule.interval.length = 7;
    System.assertEquals(null, ManageAuthNetService.resolveSubscriptionDates(schedule).endDate);
  }

  @isTest
  static void testResolveTotalOccurrences() {
    AuthorizeNetModels.paymentScheduleTypeInterval interval = new AuthorizeNetModels.paymentScheduleTypeInterval();
    ManageAuthNetService.SubscriptionDates dates = new ManageAuthNetService.SubscriptionDates();

    //Test 1
    interval.unit = 'months';
    interval.length = 3;
    dates.startDate = Date.newInstance(2020, 1, 1);
    dates.endDate = Date.newInstance(2020, 12, 31);
    System.assertEquals(4, ManageAuthNetService.resolveTotalOccurrences(dates, interval));

    //Test 2
    interval.unit = 'days';
    interval.length = 14;
    dates.startDate = Date.newInstance(2020, 1, 1);
    dates.endDate = Date.newInstance(2020, 6, 31);
    System.assertEquals(13, ManageAuthNetService.resolveTotalOccurrences(dates, interval));
  }

  @isTest
  static void testGetAuthorizeNetService() {
    setupCurrencyExchange();
    setupRecurringDonation();
    setupOpportunity();
    setupAuthService();

    Donation_Form_Submission__c dfs = new Donation_Form_Submission__c();
    dfs.Test_Mode_Submission__c = false;
    insert dfs;

    npe03__Recurring_Donation__c rd = [
      SELECT Id
      FROM npe03__Recurring_Donation__c
      WHERE Name = 'Test Recurring Donation'
    ];

    Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test CC Opp'];

    AuthorizeNetService authNetService;

    // 1. No DFS. Should not be test mode.
    authNetService = ManageAuthNetService.getAuthorizeNetService(rd.Id, 'npe03__Recurring_Donation__c');
    System.assertEquals(false, authNetService.URL.contains('test'));

    // 2. 'Production' DFS. Should not be test mode.
    rd.Donation_Form_Submission__c = dfs.Id;
    update rd;
    authNetService = ManageAuthNetService.getAuthorizeNetService(rd.Id, 'npe03__Recurring_Donation__c');
    System.assertEquals(false, authNetService.URL.contains('test'));

    // 3. 'Sandbox' DFS. Test mode.
    dfs.Test_Mode_Submission__c = true;
    update dfs;
    authNetService = ManageAuthNetService.getAuthorizeNetService(rd.Id, 'npe03__Recurring_Donation__c');
    System.assertEquals(true, authNetService.URL.contains('test'));

    // 4. Test opp
    authNetService = ManageAuthNetService.getAuthorizeNetService(opp.Id, 'Opportunity');
  }
}