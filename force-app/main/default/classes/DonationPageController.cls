global class DonationPageController {
  public Id campaignId { get; private set; }
  public String title { get; set; }
  public Boolean renderStripe { get; set; }
  public Boolean renderAuthNet { get; set; }
  public Boolean testMode { get; set; }

  public DonationPageController() {
    campaignId = ApexPages.currentPage().getParameters().get('id');
    if (campaignId == null) {
      throw new DonationPageException(
        'Error loading donation page. Invalid Campaign Id in URL'
      );
    }
    Campaign camp = getCampaignData(campaignId);

    if (camp.Donation_Page_Settings__c == null) {
      throw new DonationPageException(
        'No Donation Page Settings defined for this Campaign'
      );
    }

    title = String.isNotBlank(
        camp.Donation_Page_Settings__r.Donation_Page_Title__c
      )
      ? camp.Donation_Page_Settings__r.Donation_Page_Title__c
      : 'SET TITLE';
    testMode = camp.Donation_Page_Settings__r.Test_Mode__c ? true : false;

    if (camp.Donation_Page_Settings__r.Payment_Processor__c == 'Stripe') {
      renderStripe = true;
      renderAuthNet = false;
    } else if (
      camp.Donation_Page_Settings__r.Payment_Processor__c == 'Authorize.net'
    ) {
      renderStripe = false;
      renderAuthNet = true;
    } else if (camp.Donation_Page_Settings__r.Payment_Processor__c == 'Test') {
      renderStripe = false;
      renderAuthNet = false;
    } else {
      throw new DonationPageException(
        'Error loading donation page. No Payment Processor Selected'
      );
    }
  }

  private static Campaign getCampaignData(Id campaignId) {
    List<Campaign> camp = [
      SELECT
        Id,
        IsActive,
        Name,
        Fundraising_Goal__c,
        AmountWonOpportunities,
        Donation_Page_Settings__c,
        Donation_Page_Settings__r.Add_Suffix_Field_to_Names__c,
        Donation_Page_Settings__r.Allow_Limited_Recurring_Donations__c,
        Donation_Page_Settings__r.Allow_Multiple_Designations__c,
        Donation_Page_Settings__r.Allow_Organization_Donations__c,
        Donation_Page_Settings__r.Allow_Recurring_Donations__c,
        Donation_Page_Settings__r.Allow_Tribute_Information__c,
        Donation_Page_Settings__r.Banner_Image_URL__c,
        Donation_Page_Settings__r.Billing_Information_Section_Header__c,
        Donation_Page_Settings__r.Check_Giving_Instructions__c,
        Donation_Page_Settings__r.Comments_Label__c,
        Donation_Page_Settings__r.Contact_Information_Section_Header__c,
        Donation_Page_Settings__r.Default_Country_Selection__c,
        Donation_Page_Settings__r.Do_Not_Send_Receipt__c,
        Donation_Page_Settings__r.Donation_Option_Section_Header__c,
        Donation_Page_Settings__r.Donation_Page_Title__c,
        Donation_Page_Settings__r.Email_Visibility__c,
        Donation_Page_Settings__r.Donor_Billing_Address_Visibility__c,
        Donation_Page_Settings__r.Donor_Contact_Address_Visibility__c,
        Donation_Page_Settings__r.Donor_Tribute_Address_Visibility__c,
        Donation_Page_Settings__r.Donor_Billing_Country_Visibility__c,
        Donation_Page_Settings__r.Donor_Contact_Country_Visibility__c,
        Donation_Page_Settings__r.Donor_Tribute_Country_Visibility__c,
        Donation_Page_Settings__r.Donor_Birthdate_Visibility__c,
        Donation_Page_Settings__r.Donor_Contact_Phone_Visibility__c,
        Donation_Page_Settings__r.Donor_Billing_Phone_Visibility__c,
        Donation_Page_Settings__r.Donor_Tribute_Phone_Visibility__c,
        Donation_Page_Settings__r.Footer_Text__c,
        Donation_Page_Settings__r.Header_Text__c,
        Donation_Page_Settings__r.How_Did_You_Hear_About_Us_Label__c,
        Donation_Page_Settings__r.How_Did_You_Hear_About_Us_Visibility__c,
        Donation_Page_Settings__r.Opt_In_for_Communication_Message__c,
        Donation_Page_Settings__r.Option_to_Cover_Processing_Fees__c,
        Donation_Page_Settings__r.Option_to_Opt_In_for_Communications__c,
        Donation_Page_Settings__r.Options_Have_Multiple_Frequencies__c,
        Donation_Page_Settings__r.Payment_Method_Section_Header__c,
        Donation_Page_Settings__r.Payment_Settings_Name__c,
        Donation_Page_Settings__r.Payment_Methods__c,
        Donation_Page_Settings__r.Payment_Processor__c,
        Donation_Page_Settings__r.Post_Submission_Redirect_URL__c,
        Donation_Page_Settings__r.Recurring_Donation_Options__c,
        Donation_Page_Settings__r.Recurring_Donation_Section_Header__c,
        Donation_Page_Settings__r.Show_Comments_Field__c,
        Donation_Page_Settings__r.Submit_Button_Label__c,
        Donation_Page_Settings__r.Test_Mode__c,
        Donation_Page_Settings__r.Tribute_Information_Section_Header__c,
        Donation_Page_Settings__r.Custom_Page_CSS__c,
        Donation_Page_Settings__r.facebook_campaign_url__c,
        Donation_Page_Settings__r.twitter_campaign_url__c,
        Donation_Page_Settings__r.Matching_Multiplier__c,
        Donation_Page_Settings__r.Donation_Option_Unit_Cost__c,
        Donation_Page_Settings__r.Donation_Option_Unit_Type__c,
        Donation_Page_Settings__r.Allow_Foreign_Transactions__c,
        Donation_Page_Settings__r.Page_Contact_Email__c,
        Donation_Page_Settings__r.Show_Page_Title__c,
        Donation_Page_Settings__r.Show_Progress_Bar__c,
        Donation_Page_Settings__r.Require_CVV2_Code__c,
        Type
      FROM Campaign
      WHERE Id = :campaignId
    ];
    return (!camp.isEmpty() ? camp[0] : null);
  }

  private static List<DonationPageModels.DonationOption> getDonationOptions(
    Id campaignId
  ) {
    List<Donation_Option__c> options = [
      SELECT
        Id,
        Name,
        Amount__c,
        Fund__c,
        Fund__r.Name,
        Checked_by_Default__c,
        Allow_Custom_Amount__c,
        Tooltip_Help_Text__c
      FROM Donation_Option__c
      WHERE
        Donation_Page_Settings__r.Campaign__c = :campaignId
        AND Active__c = true
      ORDER BY Sort_Order__c ASC NULLS LAST
    ];
    List<DonationPageModels.DonationOption> donationOptions = new List<DonationPageModels.DonationOption>();
    for (Donation_Option__c donOpt : options) {
      donationOptions.add(new DonationPageModels.DonationOption(donOpt));
    }
    return donationOptions;
  }

  private static Map<String, List<Schema.PicklistEntry>> getSelectOptions() {
    Map<String, List<Schema.PicklistEntry>> optionsMap = new Map<String, List<Schema.PicklistEntry>>();
    optionsMap.put(
      'state',
      Donation_Form_Submission__c.State__c.getDescribe().getPicklistValues()
    );
    optionsMap.put(
      'country',
      Donation_Form_Submission__c.Country__c.getDescribe().getPicklistValues()
    );
    optionsMap.put(
      'hearAboutUs',
      Donation_Form_Submission__c.How_Did_You_Hear_About_Us__c.getDescribe()
        .getPicklistValues()
    );
    return optionsMap;
  }

  @RemoteAction
  global static Decimal convertDonationAmount(Decimal amount, String srcCurr) {
    CurrencyExchangeRateCalculator exchangeCalculator = new CurrencyExchangeRateCalculator();
    amount = exchangeCalculator.convert(srcCurr, 'USD', amount);
    return amount;
  }

  @RemoteAction
  global static DonationPageModels.FormData loadData(Id campaignId) {
    DonationPageModels.FormData fd = new DonationPageModels.FormData();

    fd.campaign = getCampaignData(campaignId);
    fd.campaignId = fd.campaign.Id;
    fd.donationOptions = getDonationOptions(campaignId);
    fd.selectOptions = getSelectOptions();

    DonationPagePaymentService paymentService = DonationPagePaymentServiceFactory.getPaymentService(
      fd.campaign.Donation_Page_Settings__r.Payment_Processor__c,
      fd.campaign.Donation_Page_Settings__r.Payment_Settings_Name__c,
      fd.campaign.Donation_Page_Settings__r.Test_Mode__c
    );
    paymentService.setPublicKey(fd);

    return fd;
  }

  @RemoteAction
  global static Account getAccountData(Id accountId) {
    Account account = [
      SELECT
        Name,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingPostalCode,
        BillingCountry,
        Language_Preference__c,
        Phone,
        npe01__One2OneContact__r.MailingStreet,
        npe01__One2OneContact__r.MailingPostalCode,
        npe01__One2OneContact__r.MailingState,
        npe01__One2OneContact__r.MailingCountry,
        npe01__One2OneContact__r.MailingCity,
        npe01__One2OneContact__r.HomePhone,
        npe01__One2OneContact__r.Email,
        npe01__One2OneContact__r.FirstName,
        npe01__One2OneContact__r.LastName
      FROM Account
      WHERE Id = :accountId
    ];
    return account;
  }

  @RemoteAction
  global static Contact getContactData(Id contactId) {
    Contact contact = [
      SELECT
        MailingStreet,
        MailingPostalCode,
        MailingState,
        MailingCountry,
        MailingCity,
        HomePhone,
        Email,
        FirstName,
        LastName
      FROM Contact
      WHERE Id = :contactId
    ];
    return contact;
  }

  @RemoteAction
  global static DonationPageModels.FormResponse submitForm(
    DonationPageModels.FormSubmission submission
  ) {
    System.debug('submitForm');
    DonationPageModels.FormResponse res = new DonationPageModels.FormResponse();

    try {
      System.debug(submission);
      Campaign camp = [
        SELECT
          Id,
          Donation_Page_Settings__r.Test_Mode__c,
          Donation_Page_Settings__r.Do_Not_Send_Receipt__c,
          Donation_Page_Settings__r.Email_Visibility__c
        FROM Campaign
        WHERE Id = :submission.campaignId
      ];

      // If a payment comes in as INR or KES we need to convert to USD before submission for Authorize.net
      CurrencyExchangeRateCalculator exchangeCalculator = new CurrencyExchangeRateCalculator();
      string originalCurr = submission.dfs.Original_Currency__c;

      submission.dfs.Campaign__c = submission.campaignId;
      // Date submissionDate = Date.today();
      // if (submission.submissionDate != null) {
      //   String dateString = submission.submissionDate.substringBefore('T');
      //   submissionDate = Date.valueOf(dateString);
      // } else if (submission.submissionTimestamp != null) {
      //   submissionDate = Datetime.newInstance(submission.submissionTimestamp)
      //     .dateGmt();
      // }

      // Changed submission date to use system.now() to avoid timezone issues
      submission.dfs.Submission_Date__c = System.now().addHours(-7).dateGmt();
      submission.dfs.Submission_JSON__c = JSON.serialize(submission);
      if (camp.Donation_Page_Settings__r.Test_Mode__c == true) {
        submission.dfs.Test_Mode_Submission__c = true;
      }
      Boolean sendReceipt = !camp.Donation_Page_Settings__r.Do_Not_Send_Receipt__c;
      if (
        camp.Donation_Page_Settings__r.Email_Visibility__c != 'Required' &&
        String.isBlank(submission.dfs.Email__c)
      ) {
        sendReceipt = false;
      }
      submission.dfs.Send_Email_Receipt__c = sendReceipt;
      if (String.isNotBlank(submission.dfs.Recurring_Start_Date_String__c)) {
        submission.dfs.Recurring_Start_Date__c = Date.valueOf(
          submission.dfs.Recurring_Start_Date_String__c
        );
        System.debug(submission.dfs.Recurring_Start_Date__c);
      }
      if (String.isNotBlank(submission.dfs.Donor_Birthdate_String__c)) {
        submission.dfs.Donor_Birthdate__c = Date.valueOf(
          submission.dfs.Donor_Birthdate_String__c
        );
        System.debug(submission.dfs.Donor_Birthdate__c);
      }
      buildDonationSummary(submission);

      // if the original currency is not USD, convert the Donation and Total amount fields to USD
      if (submission.dfs.Original_Currency__c != 'USD') {
        System.debug('converting currency');
        submission.dfs.Donation_Amount__c = exchangeCalculator.convert(
          submission.dfs.Original_Currency__c,
          'USD',
          submission.dfs.Original_Amount__c
        );
        submission.dfs.Total_Amount__c = exchangeCalculator.convert(
          submission.dfs.Original_Currency__c,
          'USD',
          submission.dfs.Original_Amount_with_Fees__c
        );
      }
      res.donationAmount = submission.dfs.Donation_Amount__c;
      res.totalAmount = submission.dfs.Total_Amount__c;

      insert submission.dfs;

      List<Donation_Option_Selection__c> donationOptionSelections = new List<Donation_Option_Selection__c>();
      for (
        DonationPageModels.DonationOption donationOption : submission.chosenOptions
      ) {
        Donation_Option_Selection__c dos = new Donation_Option_Selection__c();
        dos.Donation_Option__c = donationOption.option.Id;
        dos.Donation_Form_Submission__c = submission.dfs.Id;
        dos.Amount__c = submission.dfs.Original_Currency__c == 'USD'
          ? donationOption.amount
          : exchangeCalculator.convert(
              submission.dfs.Original_Currency__c,
              'USD',
              donationOption.amount
            );
        dos.Original_Amount__c = donationOption.amount;
        dos.Original_Currency__c = submission.dfs.Original_Currency__c;
        dos.Frequency__c = donationOption.frequency;
        dos.Number_of_Recurring_Payments__c = donationOption.numPayments;
        donationOptionSelections.add(dos);
        System.debug(dos);
      }
      insert donationOptionSelections;

      if (String.isNotBlank(submission.dfs.GAU_Purpose_Code__c)) {
        npsp__General_Accounting_Unit__c matchingGAU = findMatchingGAU(
          submission.dfs.GAU_Purpose_Code__c
        );
        if (matchingGAU == null) {
          throw new DonationPageException('Invalid Purpose Code');
        }
      }

      res.success = true;
      res.donationFormSubmissionId = submission.dfs.Id;
    } catch (Exception e) {
      res.success = false;
      res.error = 'Error submitting donation: ' + e.getMessage();
      System.debug(
        'ERROR ON LINE ' +
        e.getLineNumber() +
        ': ' +
        e.getMessage()
      );
      Donation_Form_Submission__c dfs = new Donation_Form_Submission__c();
      dfs.Errors__c = res.error;
      if (submission.dfs.Id != null) {
        dfs.Id = submission.dfs.Id;
        update dfs;
      } else {
        insert dfs;
      }
    }
    return res;
  }

  public static npsp__General_Accounting_Unit__c findMatchingGAU(
    String purposeCode
  ) {
    List<npsp__General_Accounting_Unit__c> gauList = [
      SELECT Id, Name, Purpose_Code__c
      FROM npsp__General_Accounting_Unit__c
      WHERE Purpose_Code__c = :purposeCode
    ];
    return gauList.isEmpty() ? null : gauList[0];
  }

  public static Id createTransaction(
    DonationPageModels.PaymentResponse res,
    Donation_Form_Submission__c dfs,
    String processor
  ) {
    System.debug('createTransaction');
    Donation_Form_Settings__c dfSettings = Donation_Form_Settings__c.getOrgDefaults();
    Schema.SObjectType objectType = Schema.getGlobalDescribe()
      .get(dfSettings.Transaction_Object_API_Name__c);
    sObject obj = objectType.newSObject();
    obj.put('Transaction_Id__c', res.transactionId);
    obj.put('Amount__c', Double.valueof(dfs.Total_Amount__c));
    obj.put('Create_Time__c', res.createTime);
    obj.put('Status__c', res.status);
    obj.put('Email__c', dfs.Billing_Email__c);
    obj.put('Type__c', processor);
    obj.put('First_Name__c', dfs.Billing_First_Name__c);
    obj.put('Last_Name__c', dfs.Billing_Last_Name__c);
    obj.put('Billing_Street__c', dfs.Billing_Street_Address__c);
    obj.put('Billing_City__c', dfs.Billing_City__c);
    obj.put('Billing_State_Province__c', dfs.Billing_State__c);
    obj.put('Billing_Postal_Code__c', dfs.Billing_Postal_Code__c);
    obj.put('Billing_Country__c', dfs.Selected_Billing_Country__c);
    obj.put('Phone__c', dfs.Billing_Phone__c);
    obj.put('Credit_Card_Type__c', dfs.Credit_Card_Type__c);
    obj.put('Donation_Form_Submission__c', dfs.Id);
    obj.put('Retrieved_Details__c', true);
    obj.put('Processed__c', true);
    insert obj;
    return obj.Id;
  }

  @RemoteAction
  global static DonationPageModels.PaymentResponse submitPayment(
    DonationPageModels.FormSubmission submission
  ) {
    System.debug('submitPayment');
    DonationPageModels.PaymentResponse res = new DonationPageModels.PaymentResponse();
    Campaign camp = [
      SELECT
        Id,
        Donation_Page_Settings__r.Test_Mode__c,
        Donation_Page_Settings__r.Payment_Processor__c,
        Donation_Page_Settings__r.Payment_Settings_Name__c
      FROM Campaign
      WHERE Id = :submission.campaignId
    ];
    DonationPagePaymentService paymentService = DonationPagePaymentServiceFactory.getPaymentService(
      camp.Donation_Page_Settings__r.Payment_Processor__c,
      camp.Donation_Page_Settings__r.Payment_Settings_Name__c,
      camp.Donation_Page_Settings__r.Test_Mode__c
    );
    if (submission.dfs.Frequency__c == 'One-time') {
      paymentService.createOneTimePayment(submission, res);
    } else if (submission.dfs.Frequency__c != 'Multi-Frequency') {
      paymentService.createRecurringPayment(submission, res);
    } else {
      paymentService.createMultiFrequencyRecurringPayment(submission, res);
    }
    if (res.success) {
      System.debug('Success');
      System.debug(submission);
      if (String.isNotBlank(res.transactionId)) {
        submission.dfs.Historical_Transaction__c = createTransaction(
          res,
          submission.dfs,
          camp.Donation_Page_Settings__r.Payment_Processor__c
        );
        submission.dfs.Payment_Processor_Transaction_Id__c = res.transactionId;
      }
      if (res.type == 'Standard Recurring') {
        if (String.isNotBlank(res.customerId)) {
          submission.dfs.Payment_Processor_Customer_Id__c = res.customerId;
        }
        if (String.isNotBlank(res.paymentProfileId)) {
          submission.dfs.Payment_Profile_Id__c = res.paymentProfileId;
        }
      } else if (
        res.type == 'Per Option Recurring' && !res.optionResponses.isEmpty()
      ) {
        Set<Id> optionIds = new Set<Id>();
        for (DonationPageModels.OptionResponse optRes : res.optionResponses) {
          optionIds.add(optRes.donOptId);
        }
        List<Donation_Option_Selection__c> selectedOptionsQuery = [
          SELECT
            Id,
            Donation_Option__c,
            Donation_Form_Submission__c,
            Frequency__c
          FROM Donation_Option_Selection__c
          WHERE
            Donation_Option__c IN :optionIds
            AND Donation_Form_Submission__c = :submission.dfs.Id
        ];
        Map<Id, Donation_Option_Selection__c> selectedOptionsMap = new Map<Id, Donation_Option_Selection__c>();
        for (Donation_Option_Selection__c dos : selectedOptionsQuery) {
          selectedOptionsMap.put(dos.Donation_Option__c, dos);
        }
        for (DonationPageModels.OptionResponse optRes : res.optionResponses) {
          System.debug(optRes);
          Donation_Option_Selection__c dos = selectedOptionsMap.get(
            optRes.donOptId
          );
          System.debug(dos);
          if (dos != null) {
            if (optRes.success) {
              if (String.isNotBlank(optRes.subscriptionId)) {
                dos.Subscription_Id__c = optRes.subscriptionId;
              }
            } else {
              System.debug(optRes);
              dos.Errors__c = optRes.error;
            }
          }
        }
        update selectedOptionsMap.values();
      }

      update submission.dfs;
    } else {
      System.debug(res);
      Donation_Form_Submission__c dfs = new Donation_Form_Submission__c();
      dfs.Id = submission.dfs.Id;
      dfs.Errors__c = res.error;
      update dfs;
    }
    return res;
  }

  // private static String getQueryFields() {
  //   Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Donation_Form_Submission__c.fields.getMap();
  //   List<String> fields = new List<String>();
  //   for (Schema.SObjectField sObjField : fieldMap.values()) {
  //     Schema.DescribeFieldResult dfr = sObjField.getDescribe();
  //     fields.add(dfr.getName());
  //   }
  //   return String.join(fields, ',');
  // }

  @RemoteAction
  global static void processDonation(Id donationFormSubmissionId) {
    Donation_Submission_Event__e dse = new Donation_Submission_Event__e();
    dse.Donation_Form_Submission_Id__c = donationFormSubmissionId;
    EventBus.publish(dse);
    // String dfsQuery =
    //   'SELECT ' +
    //   getQueryFields() +
    //   ' FROM Donation_Form_Submission__c WHERE ID = \'' +
    //   donationFormSubmissionId +
    //   '\'';
    // List<Donation_Form_Submission__c> donationQuery = Database.query(dfsQuery);
    // // DonationPageProcessor processor = new DonationPageProcessor(donationQuery);
    // // processor.run();
    // System.enqueueJob(new DonationPageProcessor(donationQuery));
  }

  private static void buildDonationSummary(
    DonationPageModels.FormSubmission submission
  ) {
    String summary = '<table><tr><th>Summary</th><th>Amount</th><th>Frequency</th></tr>';
    for (
      DonationPageModels.DonationOption chosenOption : submission.chosenOptions
    ) {
      System.debug(chosenOption);
      summary += '<tr><td>' + chosenOption.option.Fund__r.Name + '</td>';
      summary +=
        '<td>' +
        submission.dfs.Original_Currency__c +
        chosenOption.amount.setScale(2) +
        '</td>';
      summary += '<td>' + chosenOption.frequency + '</td></tr>';
    }
    summary += '</table>';
    submission.dfs.Donation_Summary__c = summary;
  }

  public class DonationPageException extends Exception {
  }
}