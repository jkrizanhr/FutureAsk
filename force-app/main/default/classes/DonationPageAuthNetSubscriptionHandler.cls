public without sharing class DonationPageAuthNetSubscriptionHandler {
  private Donation_Form_Submission__c dfs;
  private Donation_Page_Auth_net_Settings__c authNetSettings;

  public DonationPageAuthNetSubscriptionHandler(
    Donation_Form_Submission__c dfs
  ) {
    this.dfs = dfs;
    if (dfs.Test_Mode_Submission__c) {
      this.authNetSettings = Donation_Page_Auth_net_Settings__c.getInstance(
        'Sandbox'
      );
    } else {
      this.authNetSettings = Donation_Page_Auth_net_Settings__c.getInstance(
        'Production'
      );
    }
    if (this.authNetSettings == null) {
      throw new DonationPagePaymentServiceException(
        'Failed in DonationPageAuthNetSubscriptionHandler constructor: No Auth.net Settings found'
      );
    }
  }

  public Donation_Form_Submission__c run() {
    AuthorizeNetService authNetService = new AuthorizeNetService(
      this.authNetSettings.API_Login_Id__c,
      this.authNetSettings.Transaction_Key__c,
      dfs.Test_Mode_Submission__c
    );
    // create subscription and transaction
    dfs = createSubscription(authNetService, dfs);
    if (
      String.isBlank(dfs.Errors__c) &&
      String.isNotBlank(dfs.Payment_Processor_Subscription_Id__c) &&
      dfs.Recurring_Start_Date__c == Date.today()
    ) {
      dfs = createFirstTransaction(authNetService, dfs);
    }
    if (
      String.isBlank(dfs.Errors__c) &&
      String.isNotBlank(dfs.Payment_Processor_Subscription_Id__c)
    ) {
      Contact con = getContact(dfs);
      if (con == null) {
        throw new DonationPagePaymentServiceException(
          'DonationPageAuthNetSubscriptionHandler: No matching contact found'
        );
      }
      Account acc = getAccount(dfs, con);
      if (acc == null) {
        throw new DonationPagePaymentServiceException(
          'DonationPageAuthNetSubscriptionHandler: No matching account found'
        );
      }
      Campaign inputCampaign;
      if (String.isNotBlank(dfs.Campaign_Input__c)) {
        List<Campaign> inputCampaignQuery = [
          SELECT Id
          FROM Campaign
          WHERE Code__c = :dfs.Campaign_Input__c
          LIMIT 1
        ];
        inputCampaign = inputCampaignQuery.isEmpty()
          ? null
          : inputCampaignQuery[0];
      }
      List<npe03__Recurring_Donation__c> recDons = createRecurringDonation(
        dfs,
        acc,
        con,
        inputCampaign
      );
      npe03__Recurring_Donation__c recDon = recDons.isEmpty()
        ? null
        : recDons[0];
      Opportunity opp;
      if (String.isNotBlank(dfs.Payment_Processor_Transaction_Id__c)) {
        opp = createOpportunity(dfs, acc, con, recDon, inputCampaign);
        dfs.Opportunity__c = opp.Id;
      }
      createGAUAllocations(dfs, opp, recDon);
      if (opp != null) {
        sendReceiptEmail(dfs, opp, con);
      }
    }
    // update dfs with ids or error messages
    return dfs;
  }

  private Donation_Form_Submission__c createSubscription(
    AuthorizeNetService authNetService,
    Donation_Form_Submission__c submission
  ) {
    String authNetFrequency;
    Integer authNetFrequencyInterval;
    switch on submission.Frequency__c {
      when 'Weekly' {
        authNetFrequency = 'days';
        authNetFrequencyInterval = 7;
      }
      when 'Monthly' {
        authNetFrequency = 'months';
        authNetFrequencyInterval = 1;
      }
      when 'Quarterly' {
        authNetFrequency = 'months';
        authNetFrequencyInterval = 3;
      }
      when 'Yearly' {
        authNetFrequency = 'months';
        authNetFrequencyInterval = 12;
      }
    }

    // determine when subscription starts
    if (submission.Recurring_Start_Date__c == submission.Submission_Date__c) {
      submission.Recurring_Start_Date_String__c = buildNextDateString(
        submission.Recurring_Start_Date__c,
        submission.Frequency__c
      );
    }

    AuthorizeNetModels.ARBCreateSubscriptionResponse subscriptionResponse;
    AuthorizeNetModels.ARBSubscriptionType sub = new AuthorizeNetModels.ARBSubscriptionType();
    sub.name =
      submission.Id +
      '_' +
      submission.Total_Amount__c +
      '_' +
      authNetFrequency +
      '_' +
      authNetFrequencyInterval;
    // if (
    //   submission.Original_Currency__c == 'INR' ||
    //   submission.Original_Currency__c == 'KES'
    // ) {
    //   CurrencyExchangeRateCalculator exchangeCalculator = new CurrencyExchangeRateCalculator();
    //   sub.amount = exchangeCalculator.convert(
    //     submission.Original_Currency__c,
    //     'USD',
    //     submission.Total_Amount__c
    //   );
    // } else {
    sub.amount = submission.Total_Amount__c;
    // }

    sub.paymentSchedule = new AuthorizeNetModels.paymentScheduleType();
    sub.paymentSchedule.interval = new AuthorizeNetModels.paymentScheduleTypeInterval();
    sub.paymentSchedule.interval.unit = authNetFrequency;
    sub.paymentSchedule.interval.length = authNetFrequencyInterval;
    sub.paymentSchedule.startDate = submission.Recurring_Start_Date_String__c;
    sub.paymentSchedule.totalOccurrences = submission.Number_of_Recurring_Payments__c !=
      null
      ? submission.Number_of_Recurring_Payments__c.intValue()
      : 9999; //9999 indicates open-ended recurring donation in Auth.net

    sub.profile = new AuthorizeNetModels.customerProfileIdType();
    sub.profile.customerProfileId = submission.Payment_Processor_Customer_Id__c;
    sub.profile.customerPaymentProfileId = submission.Payment_Profile_Id__c;

    subscriptionResponse = authNetService.createSubscription(sub, null);
    System.debug(subscriptionResponse);

    if (
      subscriptionResponse != null &&
      subscriptionResponse.messages != null &&
      subscriptionResponse.messages.message != null &&
      subscriptionResponse.messages.message.code == 'I00001'
    ) {
      //success
      submission.Payment_Processor_Subscription_Id__c = subscriptionResponse.subscriptionId;
    } else {
      String errMsg = 'Failed to create subscription';
      errMsg += ' ' + subscriptionResponse.messages.message.text;
      System.debug(errMsg);
      submission.Errors__c = errMsg;
    }
    return submission;
  }

  private Donation_Form_Submission__c createFirstTransaction(
    AuthorizeNetService authNetService,
    Donation_Form_Submission__c submission
  ) {
    AuthorizeNetModels.createTransactionResponse authNetCharge;
    AuthorizeNetModels.transactionRequestType tr = new AuthorizeNetModels.transactionRequestType();
    tr.transactionType = 'authCaptureTransaction';
    // if (
    //   submission.Original_Currency__c == 'INR' ||
    //   submission.Original_Currency__c == 'KES'
    // ) {
    //   CurrencyExchangeRateCalculator exchangeCalculator = new CurrencyExchangeRateCalculator();
    //   tr.amount = exchangeCalculator.convert(
    //     submission.Original_Currency__c,
    //     'USD',
    //     submission.Total_Amount__c
    //   );
    //   tr.currencyCode = 'USD';
    // } else {
    tr.amount = submission.Total_Amount__c;
    // tr.currencyCode = submission.Original_Currency__c;
    // }

    tr.profile = new AuthorizeNetModels.customerProfilePaymentType();
    tr.profile.customerProfileId = submission.Payment_Processor_Customer_Id__c;
    tr.profile.paymentProfile = new AuthorizeNetModels.paymentProfile();
    tr.profile.paymentProfile.paymentProfileId = submission.Payment_Profile_Id__c;

    authNetCharge = authNetService.createTransaction(tr, null);
    if (
      authNetCharge != null &&
      authNetCharge.transactionResponse != null &&
      authNetCharge.transactionResponse.errors != null
    ) {
      submission.Errors__c = authNetCharge.transactionResponse.errors[0]
        .errorText;
    } else if (
      authNetCharge != null &&
      authNetCharge.transactionResponse != null &&
      authNetCharge.transactionResponse.responseCode == '1'
    ) {
      System.debug(authNetCharge);
      submission.Payment_Processor_Transaction_Id__c = authNetCharge.transactionResponse.transId;
    } else {
      submission.Errors__c = 'Error processing credit card';
    }

    return submission;
  }

  private String buildNextDateString(Date currentStartDate, String frequency) {
    Date newStartDate = currentStartDate;
    switch on frequency {
      when 'Weekly' {
        newStartDate = newStartDate.addDays(7);
      }
      when 'Monthly' {
        newStartDate = newStartDate.addMonths(1);
      }
      when 'Quarterly' {
        newStartDate = newStartDate.addMonths(3);
      }
      when 'Yearly' {
        newStartDate = newStartDate.addMonths(12);
      }
    }
    String dateString = Datetime.newInstance(
        newStartDate,
        Datetime.now().time()
      )
      .format('yyyy-MM-dd');
    return dateString;
  }

  private static Id findExistingContact(Contact con) {
    Id existingContactId = null;
    List<Datacloud.FindDuplicatesResult> results = Datacloud.FindDuplicates.findDuplicates(
      new List<Contact>{con}
    );
    for (Datacloud.FindDuplicatesResult findDupeResult : results) {
      for (
        Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()
      ) {
        for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
          for (
            Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()
          ) {
            existingContactId = matchRecord.getRecord().Id;
          }
        }
      }
    }
    return existingContactId;
  }

  public static Contact getContact(Donation_Form_Submission__c submission) {
    Contact c = new Contact();
    c.FirstName = submission.First_Name__c;
    c.LastName = submission.Last_Name__c;
    c.Suffix = submission.Suffix__c;
    c.npe01__HomeEmail__c = submission.Email__c;
    c.npe01__Preferred_Email__c = 'Personal';
    c.HomePhone = submission.Phone__c;
    c.npe01__PreferredPhone__c = 'Home';
    c.MailingStreet = submission.Street_Address__c;
    c.MailingCity = submission.City__c;
    c.MailingState = submission.State_Province__c;
    c.MailingPostalCode = submission.Postal_Code__c;
    c.MailingCountry = submission.Selected_Country__c;
    c.LeadSource = 'Donation Page';
    Id existingContactId = findExistingContact(c);
    if (existingContactId == null) {
      insert c;
    } else {
      c.Id = existingContactId;
    }
    List<Contact> cons = [
      SELECT Id, FirstName, LastName, AccountId
      FROM Contact
      WHERE Id = :c.Id
    ];
    return cons[0];
  }

  public static Account getAccount(
    Donation_Form_Submission__c submission,
    Contact con
  ) {
    List<Account> accs;
    if (submission.Organization_Donation__c) {
      accs = [
        SELECT Id, Name, Language_Preference__c, Receipt_Type__c
        FROM Account
        WHERE Name = :submission.Organization_Name__c
      ];
    } else {
      accs = [
        SELECT Id, Name, Language_Preference__c, Receipt_Type__c
        FROM Account
        WHERE Id = :con.AccountId
      ];
    }
    return accs.isEmpty() ? null : accs[0];
  }

  public static List<npe03__Recurring_Donation__c> createRecurringDonation(
    Donation_Form_Submission__c submission,
    Account acc,
    Contact con,
    Campaign inputCampaign
  ) {
    List<npe03__Recurring_Donation__c> recDonsToInsert = new List<npe03__Recurring_Donation__c>();
    List<npe03__Recurring_Donation__c> donOptRecurringDonations = new List<npe03__Recurring_Donation__c>();
    System.debug(submission.Frequency__c);
    if (
      String.isNotBlank(submission.Frequency__c) &&
      submission.Frequency__c != 'One-time' &&
      submission.Frequency__c != 'Multi-Frequency' &&
      String.isNotBlank(submission.Payment_Processor_Subscription_Id__c)
    ) {
      String campaignId = inputCampaign != null
        ? inputCampaign.Id
        : submission.Campaign__c;
      String regionQuery =
        'SELECT Region_Category__c FROM Campaign WHERE Id = \'' +
        campaignId +
        '\'';
      List<Campaign> campaignList = Database.query(regionQuery);

      npe03__Recurring_Donation__c recDon = new npe03__Recurring_Donation__c();
      recDon.npe03__Date_Established__c = submission.Submission_Date__c;
      recDon.npsp__Day_of_Month__c = submission.Recurring_Start_Date__c.day() >=
        28
        ? 'Last_Day'
        : String.valueOf(submission.Recurring_Start_Date__c.day());
      // CurrencyExchangeRateCalculator exchangeCalculator = new CurrencyExchangeRateCalculator();
      // recDon.npe03__Amount__c = exchangeCalculator.convert(
      //   submission.Original_Currency__c,
      //   'USD',
      //   submission.Total_Amount__c
      // );
      recDon.npe03__Amount__c = submission.Total_Amount__c;
      recDon.Original_Amount__c = submission.Original_Amount_with_Fees__c;
      recDon.Original_Currency__c = submission.Original_Currency__c;
      recDon.npe03__Installment_Period__c = submission.Frequency__c;
      recDon.npe03__Open_Ended_Status__c = 'None';
      recDon.npe03__Recurring_Donation_Campaign__c = inputCampaign != null
        ? inputCampaign.Id
        : submission.Campaign__c;
      recDon.npe03__Installments__c = 0;
      recDon.npe03__Schedule_Type__c = 'Multiply By';
      if (submission.Organization_Donation__c) {
        recDon.npe03__Organization__c = acc.Id;
        recDon.Name =
          submission.Organization_Name__c +
          ' - ' +
          submission.Original_Currency__c +
          submission.Total_Amount__c +
          ' Recurring Donation';
      } else {
        recDon.npe03__Contact__c = con.Id;
        recDon.Name =
          submission.First_Name__c +
          ' ' +
          submission.Last_Name__c +
          ' - ' +
          submission.Original_Currency__c +
          submission.Total_Amount__c +
          ' Recurring Donation';
      }
      recDon.Donation_Form_Submission__c = submission.Id;
      recDon.Subscription_Id__c = submission.Payment_Processor_Subscription_Id__c;
      if (String.isNotBlank(submission.Credit_Card_Exp_Date__c)) {
        recDon.Credit_Card_Expiration_Month__c = submission.Credit_Card_Exp_Date__c.split(
          '/'
        )[0];
        recDon.Credit_Card_Expiration_Year__c = submission.Credit_Card_Exp_Date__c.split(
          '/'
        )[1];
      }
      recDon.npsp__PaymentMethod__c = submission.Payment_Method__c;

      if (
        String.isNotBlank(submission.Payment_Processor_Customer_Id__c) &&
        String.isNotBlank(submission.Payment_Profile_Id__c)
      ) {
        List<Customer_Profile__c> cpList = [
          SELECT Id
          FROM Customer_Profile__c
          WHERE
            Customer_Profile_Id__c = :submission.Payment_Processor_Customer_Id__c
            AND Payment_Profile_Id__c = :submission.Payment_Profile_Id__c
        ];
        if (!cpList.isEmpty()) {
          recDon.Customer_Profile__c = cpList[0].Id;
        }
      }

      recDon.Region_Category__c = !campaignList.isEmpty()
        ? campaignList[0].Region_Category__c
        : null;
      recDonsToInsert.add(recDon);
    }
    if (!recDonsToInsert.isEmpty()) {
      insert recDonsToInsert;
    }
    return recDonsToInsert;
  }

  public static Opportunity createOpportunity(
    Donation_Form_Submission__c submission,
    Account acc,
    Contact con,
    npe03__Recurring_Donation__c recDon,
    Campaign inputCampaign
  ) {
    List<Campaign> relatedCampaignList = [
      SELECT
        Id,
        Donation_Page_Settings__c,
        Donation_Page_Settings__r.Email_Receipt_Message__c,
        Region_Category__c
      FROM Campaign
      WHERE Id = :submission.Campaign__c
    ];

    Opportunity opp = new Opportunity();
    System.debug(submission.Submission_Date__c.format());
    if (submission.Organization_Donation__c) {
      opp.AccountId = acc.Id;
      opp.Name =
        submission.Organization_Name__c +
        ' - ' +
        submission.Original_Currency__c +
        submission.Total_Amount__c +
        ' Donation - ' +
        submission.Submission_Date__c.format();
    } else {
      opp.AccountId = con.AccountId;
      opp.Name =
        submission.First_Name__c +
        ' ' +
        submission.Last_Name__c +
        ' - ' +
        submission.Original_Currency__c +
        submission.Total_Amount__c +
        ' Donation - ' +
        submission.Submission_Date__c.format();
    }
    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
      .get('Donation')
      .getRecordTypeId();
    opp.npsp__Primary_Contact__c = con.Id;
    opp.Amount = submission.Total_Amount__c;
    opp.CloseDate = submission.Submission_Date__c;
    opp.Transaction_Id__c = submission.Payment_Processor_Transaction_Id__c;
    opp.LeadSource = 'Donation Page';
    opp.Donation_Source__c = submission.Donation_Page_Source__c;
    opp.Payment_Method__c = submission.Payment_Method__c;
    if (opp.Payment_Method__c == 'EFT') {
      opp.Payment_Method__c = 'Bank Account';
    }
    opp.Credit_Card_Type__c = submission.Credit_Card_Type__c;
    opp.Credit_Card_Exp_Date__c = submission.Credit_Card_Exp_Date__c;
    if (submission.Credit_Card_Last_Four__c != null) {
      opp.Credit_Card_Last_Four__c = Integer.valueof(
        submission.Credit_Card_Last_Four__c
      );
    }
    opp.Credit_Card_No_Hash__c = submission.Credit_Card_Hash__c;
    opp.CampaignId = inputCampaign != null
      ? inputCampaign.Id
      : submission.Campaign__c;
    opp.Honor_Memorial_Address_1__c = submission.Notify_Street_Address__c;
    opp.Honor_Memorial_City__c = submission.Notify_City__c;
    opp.Honor_Memorial_State__c = submission.Notify_State__c;
    opp.Honor_Memorial_Zip_Code__c = submission.Notify_Postal_Code__c;
    opp.Honor_Memorial_Country__c = submission.Notify_Country__c;
    opp.Honor_Memorial_Message__c = submission.Tribute_Message__c;
    opp.npsp__Honoree_Name__c = submission.Honoree_Name__c;
    opp.Honoree_From__c = submission.Tribute_From__c;
    opp.npsp__Tribute_Type__c = submission.Donation_Tribute_Type__c;
    opp.Honor_Memorial_Type__c = submission.Donation_Tribute_Type__c;
    opp.Honor_Memorial_Notify_First_Name__c = submission.Notify_First_Name__c;
    opp.Honor_Memorial_Notify_Last_Name__c = submission.Notify_Last_Name__c;
    opp.Honor_Memorial_Notification_Email__c = submission.Notify_Email__c;
    opp.Original_Amount__c = submission.Donation_Amount__c;
    opp.Original_Currency__c = submission.Original_Currency__c;
    opp.Email_Receipt_Date__c = Date.today();
    System.debug(con);
    if (acc.Language_Preference__c != null) {
      opp.Language_Preference__c = acc.Language_Preference__c;
    } else {
      opp.Language_Preference__c = 'English';
    }
    if (acc.Receipt_Type__c != null) {
      opp.Receipt_Type__c = acc.Receipt_Type__c;
    } else {
      opp.Receipt_Type__c = 'Email';
    }
    if (submission.Payment_Method__c == 'Check') {
      opp.StageName = 'Pending';
    } else {
      opp.StageName = 'Posted';
    }
    opp.Utm_Campaign__c = submission.utm_campaign__c;
    if (recDon != null) {
      opp.npe03__Recurring_Donation__c = recDon.Id;
    }
    opp.Historical_Transaction__c = submission.Historical_Transaction__c;
    opp.Donation_Form_Submission__c = submission.Id;
    opp.Donation_Summary__c = submission.Donation_Summary__c;

    if (!relatedCampaignList.isEmpty()) {
      opp.Donation_Page_Email_Message__c = relatedCampaignList[0]
        .Donation_Page_Settings__r.Email_Receipt_Message__c;
      opp.Region_Category__c = relatedCampaignList[0].Region_Category__c;
    }
    insert opp;
    return opp;
  }

  public static void createGAUAllocations(
    Donation_Form_Submission__c submission,
    Opportunity opp,
    npe03__Recurring_Donation__c recDon
  ) {
    Donation_Form_Settings__c dfSettings = Donation_Form_Settings__c.getOrgDefaults();
    Map<Id, Decimal> gauAllocAmountMap = new Map<Id, Decimal>();
    Map<Id, Decimal> gauAllocOrigAmountMap = new Map<Id, Decimal>();
    List<npsp__Allocation__c> allocationsToInsert = new List<npsp__Allocation__c>();
    Map<String, Id> utmValToCampaignId = buildUtmCampaignMap(
      new List<Donation_Form_Submission__c>{submission}
    );

    List<Donation_Option_Selection__c> donOptSels = [
      SELECT
        Id,
        Donation_Option__c,
        Donation_Option__r.Fund__c,
        Donation_Form_Submission__c,
        Amount__c,
        Original_Amount__c,
        Original_Currency__c,
        Frequency__c,
        Subscription_Id__c
      FROM Donation_Option_Selection__c
      WHERE Donation_Form_Submission__c = :submission.Id
    ];

    if (!donOptSels.isEmpty()) {
      Id purposeCodeGauId;
      if (String.isNotBlank(submission.GAU_Purpose_Code__c)) {
        npsp__General_Accounting_Unit__c gau = DonationPageController.findMatchingGAU(
          submission.GAU_Purpose_Code__c
        );
        if (gau != null) {
          purposeCodeGauId = gau.Id;
        }
      }

      for (Donation_Option_Selection__c dos : donOptSels) {
        System.debug(dos);

        Id gauId = dos.Donation_Option__r.Fund__c;
        if (purposeCodeGauId != null) {
          gauId = purposeCodeGauId;
        }

        if (gauAllocAmountMap.get(gauId) == null) {
          gauAllocAmountMap.put(gauId, 0);
        }
        Decimal amt = gauAllocAmountMap.get(gauId);
        amt += dos.Amount__c;
        gauAllocAmountMap.put(gauId, amt);
        if (gauAllocOrigAmountMap.get(gauId) == null) {
          gauAllocOrigAmountMap.put(gauId, 0);
        }
        Decimal origAmt = gauAllocOrigAmountMap.get(gauId);
        origAmt += dos.Original_Amount__c;
        gauAllocOrigAmountMap.put(gauId, origAmt);
      }
      if (submission.Will_Cover_Processing_Fees__c) {
        if (
          gauAllocAmountMap.get(dfSettings.Coverage_Fees_Fund_Id__c) == null
        ) {
          gauAllocAmountMap.put(dfSettings.Coverage_Fees_Fund_Id__c, 0);
        }
        Decimal amt = gauAllocAmountMap.get(
          dfSettings.Coverage_Fees_Fund_Id__c
        );
        amt += (submission.Total_Amount__c - submission.Donation_Amount__c);
        gauAllocAmountMap.put(dfSettings.Coverage_Fees_Fund_Id__c, amt);
        if (
          gauAllocOrigAmountMap.get(dfSettings.Coverage_Fees_Fund_Id__c) == null
        ) {
          gauAllocOrigAmountMap.put(dfSettings.Coverage_Fees_Fund_Id__c, 0);
        }
        Decimal origAmt = gauAllocOrigAmountMap.get(
          dfSettings.Coverage_Fees_Fund_Id__c
        );
        origAmt += (submission.Original_Amount_with_Fees__c -
        submission.Original_Amount__c);
        gauAllocOrigAmountMap.put(dfSettings.Coverage_Fees_Fund_Id__c, origAmt);
      }
      for (Id gauIdKey : gauAllocAmountMap.keySet()) {
        if (opp != null) {
          npsp__Allocation__c alloc = new npsp__Allocation__c();
          alloc.npsp__General_Accounting_Unit__c = gauIdKey;
          alloc.npsp__Opportunity__c = opp.Id;
          alloc.npsp__Amount__c = gauAllocAmountMap.get(gauIdKey);
          alloc.Original_Amount__c = gauAllocOrigAmountMap.get(gauIdKey) != null
            ? gauAllocOrigAmountMap.get(gauIdKey)
            : null;
          alloc.Original_Currency__c = submission.Original_Currency__c;
          if (utmValToCampaignId.get(submission.utm_campaign__c) != null) {
            alloc.Campaign__c = utmValToCampaignId.get(
              submission.utm_campaign__c
            );
          } else {
            alloc.Campaign__c = submission.Campaign__c;
          }
          allocationsToInsert.add(alloc);
        }
        if (submission.Frequency__c != 'One-time' && recDon != null) {
          npsp__Allocation__c recurringAlloc = new npsp__Allocation__c();
          recurringAlloc.npsp__General_Accounting_Unit__c = gauIdKey;
          recurringAlloc.npsp__Recurring_Donation__c = recDon.Id;
          recurringAlloc.npsp__Amount__c = gauAllocAmountMap.get(gauIdKey);
          recurringAlloc.Original_Amount__c = gauAllocOrigAmountMap.get(
              gauIdKey
            ) != null
            ? gauAllocOrigAmountMap.get(gauIdKey)
            : null;
          if (utmValToCampaignId.get(submission.utm_campaign__c) != null) {
            recurringAlloc.Campaign__c = utmValToCampaignId.get(
              submission.utm_campaign__c
            );
          } else {
            recurringAlloc.Campaign__c = submission.Campaign__c;
          }
          recurringAlloc.Original_Currency__c = submission.Original_Currency__c;
          allocationsToInsert.add(recurringAlloc);
        }
      }
    }

    if (!allocationsToInsert.isEmpty()) {
      insert allocationsToInsert;
    }
  }

  public static Map<String, Id> buildUtmCampaignMap(
    List<Donation_Form_Submission__c> formSubmissions
  ) {
    Set<String> utmCampaignValues = new Set<String>();
    for (Donation_Form_Submission__c dfs : formSubmissions) {
      if (String.isNotBlank(dfs.utm_campaign__c)) {
        utmCampaignValues.add(dfs.utm_campaign__c);
      }
    }
    Map<String, Id> utmValToCampaignId = new Map<String, Id>();
    for (Campaign camp : [
      SELECT Id, Campaign_Code__c
      FROM Campaign
      WHERE Campaign_Code__c IN :utmCampaignValues AND Campaign_Code__c != null
    ]) {
      utmValToCampaignId.put((camp.Campaign_Code__c).toLowerCase(), camp.Id);
    }

    return utmValToCampaignId;
  }

  public void sendReceiptEmail(
    Donation_Form_Submission__c submission,
    Opportunity opp,
    Contact con
  ) {
    List<Donation_Form_Submission__c> formSubmissions = new List<Donation_Form_Submission__c>{
      submission
    };
    Map<Id, Contact> contactMap = new Map<Id, Contact>{submission.Id => con};
    Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>{
      submission.Id => opp
    };
    if (!Test.isRunningTest()) {
      System.enqueueJob(
        new DonationPageProcessor.DP_SendEmailQueueable(
          formSubmissions,
          contactMap,
          opportunityMap
        )
      );
    } else {
      new DonationPageProcessor.DP_SendEmailQueueable(
          formSubmissions,
          contactMap,
          opportunityMap
        )
        .execute(null);
    }
  }

  // public void sendReceiptEmail(
  //   Donation_Form_Submission__c submission,
  //   Opportunity opp,
  //   Contact con
  // ) {
  //   System.debug('starting emails');
  //   Donation_Form_Settings__c dfSettings = Donation_Form_Settings__c.getOrgDefaults();
  //   List<OrgWideEmailAddress> orgWideEmail = [
  //     SELECT Id
  //     FROM OrgWideEmailAddress
  //     WHERE
  //       DisplayName = :dfSettings.Receipt_From_Email_Address__c
  //       OR Address = :dfSettings.Receipt_From_Email_Address__c
  //   ];

  //   List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
  //   if (opp != null) {
  //     Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
  //     if (!orgWideEmail.isEmpty()) {
  //       email.setOrgWideEmailAddressId(orgWideEmail[0].Id);
  //     } else {
  //       email.setSenderDisplayName(dfSettings.Receipt_Email_Display_From__c);
  //     }
  //     if (submission.Frequency__c != 'One-time') {
  //       email.setTemplateID(dfSettings.Recurring_Donation_Email_Template_Id__c);
  //     } else {
  //       email.setTemplateID(dfSettings.Receipt_Template_Id__c);
  //     }
  //     email.setTargetObjectId(con.Id);
  //     email.setWhatId(opp.Id);
  //     email.setSaveAsActivity(false);
  //     emailsToSend.add(email);
  //   }
  //   if (!Test.isRunningTest() && !emailsToSend.isEmpty()) {
  //     Messaging.sendEmail(emailsToSend);
  //   }
  // }
}