public without sharing class Portal_Controller {
  
  // UTILITY METHODS - USED IN ALL THE COMPONENTS
  @AuraEnabled(cacheable=true)
  public static Id getContactId(){
    User user = [SELECT ContactId, Contact_Id__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    return String.isNotBlank(user.ContactId) ? user.ContactId : user.Contact_Id__c;
  }
  @AuraEnabled
  public static Map<String, Portal_Models.PicklistInfo> buildPicklists(Map<String, List<String>> fieldsAndObjectMap){
    Map<String, Portal_Models.PicklistInfo> picklists = new Map<String, Portal_Models.PicklistInfo>();
    
    for (String objectName : fieldsAndObjectMap.keySet()){
      List<String> reqFields = fieldsAndObjectMap.get(objectName);

      Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
      Schema.DescribeSObjectResult res = sObjType.getDescribe();
      Map<String, Schema.SobjectField> fields = res.fields.getMap();

      for (String fieldName : reqFields){
        Portal_Models.PicklistInfo pi = new Portal_Models.PicklistInfo();
        List<Portal_Models.MySelectOption> options = new List<Portal_Models.MySelectOption>();
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry plv : ple){
          options.add(new Portal_Models.MySelectOption(plv.getLabel(), plv.getValue()));
        }
        pi.picklistValues = options;
        picklists.put(fieldName, pi);
      }
    }
    return picklists;
  }
  
  // Home Page Components

  // FEATURED PROJECTS COMPONENT METHOD
  @AuraEnabled
  public static List<Project__c> fetchFeaturedProjects(){
    List<Project__c> featuredProjects = new List<Project__c>();
    List<Project__c> projects = [
      SELECT Id, Name, Public_Name__c, Public_Description__c, Project_Image_URL__c, General_Accounting_Unit__c 
      FROM Project__c 
      WHERE Featured_Project__c = true 
    ];

    if (projects.size() > 5){
      for (Integer i = 0; i < 5; i++){
        Integer random = Integer.valueOf(Math.random() * (projects.size()));
        Project__c p = projects[random];
        featuredProjects.add(p);
        projects.remove(random);
      }
      return featuredProjects;
    } else {
      return projects;
    }
  }

  // MY GIVING IMPACT COMPONENT METHOD
  @AuraEnabled
  public static Contact fetchDonorTotals(){
    Id contactId = getContactId();
    if (String.isNotBlank(contactId)){
      return [
        SELECT Id, Calendar_YTD_Total_Gifts__c, npo02__NumberOfClosedOpps__c, npo02__TotalOppAmount__c, Calendar_YTD_Total_Giving__c FROM Contact WHERE Id = :contactId LIMIT 1
      ];
    } else {
      return null;
    }
  }
  
  // MY QUARTERLY REPORTS
  @AuraEnabled
  public static List<Quarterly_Report__c> fetchQuarterlyReports(){
    return [SELECT Id, Quarter__c, Year__c, Date__c,Report_File_Id__c,Community_URL__c
            FROM Quarterly_Report__c 
            ORDER BY Date__c DESC
            LIMIT 4];
  }
  
  // REDIRECT COMPONENT METHOD
  @AuraEnabled
  public static Map<String, String> fetchCurrentSessionType(){
    return Auth.SessionManagement.getCurrentSession();
  }

  // Giving History Page

  // MY GIVING HISTORY COMPONENT METHODS
  @AuraEnabled
  public static List<Portal_Models.Gift> fetchAllocations(){
    Id contactId = getContactId();
    if (String.isNotBlank(contactId)){
      Map<Id, Portal_Models.Gift> giftMap = new Map<Id, Portal_Models.Gift>();

      List<Opportunity> oppList = [
        SELECT 
          Id,
          Payment_Method__c,
          Donation_Form_Submission__c,
          Donation_Form_Submission__r.Will_Cover_Processing_Fees__c,
          Donation_Form_Submission__r.Total_Amount__c,
          Donation_Form_Submission__r.Donation_Amount__c,
          Donation_Form_Submission__r.Original_Amount_With_Fees__c,
          Donation_Form_Submission__r.Original_Amount__c,
          (SELECT
            Id,
            Close_Date__c,
            npsp__Amount__c,
            Original_Amount__c,
            Original_Currency__c,
            npsp__General_Accounting_Unit__r.Name
          FROM npsp__Allocations__r
          ORDER BY npsp__Amount__c DESC NULLS LAST)
        FROM Opportunity
        WHERE npsp__Primary_Contact__c = :contactId 
          AND (IsWon = true OR StageName = 'Test Mode')
        ORDER BY CloseDate DESC NULLS LAST
      ];

      if (!oppList.isEmpty()){
        for (Opportunity opp : oppList){
          if (!opp.npsp__Allocations__r.isEmpty()){
            // calculate processing fees to make sure they get added correctly
            Boolean processingFees = opp.Donation_Form_Submission__r.Will_Cover_Processing_Fees__c;
          
            // No Processing Fees: Create the Gift records as usual
            // Only 1 Allocation: Should display with processing fees included
            if (!processingFees || opp.npsp__Allocations__r.size() == 1){
              for (npsp__Allocation__c alloc : opp.npsp__Allocations__r){
                if (giftMap.containsKey(opp.Id)){
                  Portal_Models.Gift gift = giftMap.get(opp.Id);
                  Portal_Models.ExtraGiftAllocation ega = new Portal_Models.ExtraGiftAllocation(alloc);
                  gift.additionalAllocations.add(ega);
                  giftMap.put(opp.Id, gift);
                } else {
                  Portal_Models.Gift gift = new Portal_Models.Gift(alloc, opp);
                  giftMap.put(opp.Id, gift);
                }
              }
            } 
            // Processing Fees and multiple allocations: Don't include allocation if only for processing fees
            else {
              // Donation Amounts with/without Fees in Foreign/USD
              Decimal usdTotalAmount = opp.Donation_Form_Submission__r.Total_Amount__c;
              Decimal usdDonationAmt = opp.Donation_Form_Submission__r.Donation_Amount__c;
              Decimal orgTotalAmount = opp.Donation_Form_Submission__r.Original_Amount_With_Fees__c;
              Decimal orgDonationAmt = opp.Donation_Form_Submission__r.Original_Amount__c;
              
              // Multiple Allocations: Check if one of the Allocations covers the entire processing fees amount and if so remove it from the list. Else: Remove the processing fees from the additional allocation.
              for (npsp__Allocation__c alloc : opp.npsp__Allocations__r){
                if (giftMap.containsKey(opp.Id)){
                  Portal_Models.Gift gift = giftMap.get(opp.Id);
                  if (alloc.npsp__Amount__c != usdTotalAmount - usdDonationAmt){
                    Portal_Models.ExtraGiftAllocation ega = new Portal_Models.ExtraGiftAllocation(alloc);
                    gift.additionalAllocations.add(ega);
                  } else {
                    gift.amount += alloc.npsp__Amount__c;
                  }
                  giftMap.put(opp.Id, gift);
                } else {
                  Portal_Models.Gift gift = new Portal_Models.Gift(alloc, opp);
                  giftMap.put(opp.Id, gift);
                }
              }
            }
          }
        }
      }

      return !giftMap.isEmpty() ? giftMap.values() : null;
    } else {
      return null;
    }
  }
  @AuraEnabled
  public static Id fetchStandardReceiptTemplate(){    
    List<Document_Template__c> dtList = [
      SELECT Id FROM Document_Template__c WHERE Name = 'Biblica Standard Receipt Portal Users' LIMIT 1
    ];
    return !dtList.isEmpty() ? dtList[0].Id : null;
  }
  @AuraEnabled
  public static Portal_Models.ReceiptInfo fetchReceiptTemplate(){
    Id contactId = getContactId();
    Id acctId = [SELECT AccountId FROM Contact WHERE Id = :contactId LIMIT 1].AccountId;
    List<Document_Template__c> dtList = [
      SELECT 
        Id, (
          SELECT Id 
          FROM Document_Template_Questions__r 
          ORDER BY Question_Order__c 
          LIMIT 2
        )
      FROM Document_Template__c
      WHERE Name = 'Biblica End of Year Receipt Portal Users'
      LIMIT 1
    ];
    Document_Template__c dt = !dtList.isEmpty() ? dtList[0] : null;

    Portal_Models.ReceiptInfo ri = new Portal_Models.ReceiptInfo();
    ri.acctId = acctId != null ? acctId : null;
    ri.templateId = dt != null ? dt.Id : null;
    ri.questOneId = dt != null && !dt.Document_Template_Questions__r.isEmpty()
      ? dt.Document_Template_Questions__r[0].Id : null;
    ri.questTwoId = dt != null && !dt.Document_Template_Questions__r.isEmpty()
      ? dt.Document_Template_Questions__r[1].Id : null;
    
    return ri;
  }

  // My Profile Page

  // MY PROFILE COMPONENT METHODS
  @AuraEnabled
  public static Portal_Models.ProfileInfo fetchProfileInformation(){
    Id contactId = getContactId();
    if (String.isNotBlank(contactId)){
      Contact c = [
        SELECT 
          Id, AccountId, npsp__Primary_Affiliation__c, Salutation, FirstName, LastName, Suffix, npe01__PreferredPhone__c, HomePhone, npe01__WorkPhone__c, MobilePhone, OtherPhone, npe01__Preferred_Email__c, npe01__HomeEmail__c, npe01__WorkEmail__c, npe01__AlternateEmail__c, MailingCountry, MailingState, MailingStreet, MailingCity, MailingPostalCode, Account.Receipt_Type__c, Account.Language_Preference__c,
          (SELECT 
            Id, Prefix__c, First_Name__c, Last_Name__c, Suffix__c, Preferred_Phone__c, Home_Phone__c, Work_Phone__c, Mobile_Phone__c, Preferred_Email__c, Personal_Email__c, Work_Email__c, Alternate_Email__c, Country__c, Street__c, City__c, State__c, Postal_Code__c
          FROM Requested_Profile_Updates__r
          WHERE Update_Status__c = 'Pending' OR Update_Status__c = 'Waiting for Approval'
          ORDER BY CreatedDate DESC
          LIMIT 1)
        FROM Contact 
        WHERE Id = :contactId 
        LIMIT 1
      ];
      Portal_Models.ProfileInfo pi = new Portal_Models.ProfileInfo(c);
      return pi;
    } else {
      return null;
    }
  }
  @AuraEnabled
  public static Map<String, Portal_Models.PicklistInfo> getPicklistValues(){
    Map<String, List<String>> fieldsAndObjectMap = new Map<String, List<String>>();
    
    fieldsAndObjectMap.put('Contact', new List<String>{'npe01__PreferredPhone__c', 'npe01__Preferred_Email__c', 'Salutation'});
    fieldsAndObjectMap.put('Account', new List<String>{'Receipt_Type__c', 'Language_Preference__c'});

    return buildPicklists(fieldsAndObjectMap);   
  }
  @AuraEnabled
  public static void updateAccount(Account account){
    update account;
  }

  // MY ACTIVE RECURRING DONATIONS COMPONENT METHODS
  @AuraEnabled
  public static List<npe03__Recurring_Donation__c> fetchActiveRecurringDonations(){
    Id contactId = getContactId();
    if (String.isNotBlank(contactId)){
      Contact con = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId];
      return [
        SELECT 
          Id, 
          npe03__Organization__c,
          npe03__Amount__c,
          npe03__Contact__c,
          npsp__InstallmentFrequency__c,
          npe03__Installment_Period__c,
          npe03__Next_Payment_Date__c,
          npe03__Paid_Amount__c,
          Original_Amount__c,
          Original_Total_Paid_Amount__c,
          Original_Currency__c,
          npsp__Status__c,
          npe03__Last_Payment_Date__c,
          npsp__Day_of_Month__c
        FROM npe03__Recurring_Donation__c 
        WHERE 
          (npe03__Contact__c = :contactId OR  
          npe03__Organization__c = :con.AccountId)
          AND npsp__Status__c = 'Active'
      ];
    } else {
      return null;
    }
  }
  @AuraEnabled
  public static ManageAuthNetSubscriptionController.SubscriptionInfo fetchSubscription(Id recordId){
    // Uses the ManageAuthNetSubscriptionController because the same functionality is needed in the Portal Component as the internal ManageAuthNetSubscription.
    return ManageAuthNetSubscriptionController.fetchData(recordId);
  }
  @AuraEnabled
  public static String updateSubscriptionPaymentMethod(Id recordId, String subscription, String paymentMethod){
    System.debug('updateSubscriptionPaymentMethod');
    Portal_Models.SubscriptionInfo subscriptionInfo = (Portal_Models.SubscriptionInfo) JSON.deserialize(
      subscription, Portal_Models.SubscriptionInfo.class
    );
    Portal_Models.PaymentMethodInfo paymentInfo = (Portal_Models.PaymentMethodInfo) JSON.deserialize(
      paymentMethod, Portal_Models.PaymentMethodInfo.class
    );

    return Portal_AuthNetController.updateSubscriptionPaymentMethod(recordId, subscriptionInfo, paymentInfo);
  }

  // MY SAVED PAYMENT METHODS COMPONENT METHODS
  /* PaymentInfo is a map storing all the updated/new payment method information. 
    It has these fields:
    - paymentMethod
    - cardNumber (set when paymentMethod = Credit Card)
    - cvv (set when paymentMethod = Credit Card)
    - selectedMonth (set when paymentMethod = Credit Card)
    - selectedYear (set when paymentMethod = Credit Card)
    - accountHolder (set when paymentMethod = Bank Account)
    - routingNumber (set when paymentMethod = Bank Account)
    - accountNumber (set when paymentMethod = Bank Account)
  */
  @AuraEnabled
  public static List<Portal_Models.PaymentMethodInfo> fetchSavedPaymentMethods(){
    Id contactId = getContactId();
    return Portal_AuthNetController.fetchPaymentMethods(contactId);    
  }
  @AuraEnabled
  public static Boolean newPaymentMethod(Map<String, String> paymentInfo){
    Boolean successful = false;
    Boolean validPaymentType = Portal_AuthNetController.validatePaymentMethodInformation(paymentInfo);
    
    if (validPaymentType){
      Id contactId = getContactId();
      Contact con = [
        SELECT Id, Email, FirstName, LastName, Title, 
          MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Phone 
        FROM Contact 
        WHERE Id = :contactId
        LIMIT 1
      ];
      String customerProfileId = Portal_AuthNetController.buildOrGetProfile(con);
      AuthorizeNetModels.customerPaymentProfileType pp = Portal_AuthNetController.buildPaymentProfile(paymentInfo, null, con);
     
      successful = Portal_AuthNetController.createPaymentProfile(contactId, customerProfileId, pp);
    }

    return successful;    
  }
  @AuraEnabled
  public static Boolean updatePaymentMethod(Map<String, String> paymentInfo, String paymentMethod){
    Portal_Models.PaymentMethodInfo pmi = (Portal_Models.PaymentMethodInfo) JSON.deserialize(paymentMethod, Portal_Models.PaymentMethodInfo.class);
    Boolean successful = false;
    Boolean validPaymentType = Portal_AuthNetController.validatePaymentMethodInformation(paymentInfo);

    if (validPaymentType){
      Id contactId = getContactId();
      Contact con = [
        SELECT Id, Email, FirstName, LastName, Title, 
          MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Phone 
        FROM Contact 
        WHERE Id = :contactId
        LIMIT 1
      ];
      AuthorizeNetModels.customerPaymentProfileType pp = Portal_AuthNetController.buildPaymentProfile(paymentInfo, pmi, con);
      successful = Portal_AuthNetController.updatePaymentProfile(pp, pmi.customerId);
    }

    return successful;    
  }
  @AuraEnabled
  public static Boolean deletePaymentMethod(String paymentMethod){
    Portal_Models.PaymentMethodInfo pmi = (Portal_Models.PaymentMethodInfo) JSON.deserialize(paymentMethod, Portal_Models.PaymentMethodInfo.class);
    Boolean deleteCustomerProfile = Portal_AuthNetController.verifyDeleteCustomerProfile(pmi.customerId, pmi.id);
    if (!Test.isRunningTest()){
      if (deleteCustomerProfile){
        return Portal_AuthNetController.deleteCustomerProfile(pmi.customerId, pmi.id);
      } else {
        return Portal_AuthNetController.deleteCustomerPaymentProfile(pmi.customerId, pmi.id);
      }
    } else {
      return null;
    }
  }

   // PORTAL DONATION PAGE COMPONENT METHODS
  @AuraEnabled
  public static Portal_Models.DonationPageInfo fetchDonationPageInformation(String idParam){
    Portal_Models.DonationPageInfo dpi = new Portal_Models.DonationPageInfo();
    // Get Contact Id
    Id contactId = getContactId();
    Contact con = [SELECT Id, FirstName, LastName, Email, Phone, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Account.Language_Preference__c FROM Contact WHERE Id = :contactId];
    dpi.contact = con;

    // Get Currency Types
    Map<String, List<String>> fieldsAndObjectMap = new Map<String, List<String>>();
    fieldsAndObjectMap.put('Opportunity', new List<String>{'Original_Currency__c'});
    Map<String, Portal_Models.PicklistInfo> picklists = buildPicklists(fieldsAndObjectMap);
    dpi.currencyTypes = picklists.containsKey('Original_Currency__c') ? picklists.get('Original_Currency__c') : null;

    // Get Selected Funds
    if (idParam != null){
      if (idParam.substring(0,3) == Opportunity.getSObjectType().getDescribe().getKeyPrefix()){
        dpi = useOpportunityIdForDonationPage(idParam, dpi);
      } 
      else if (idParam.substring(0,3) == npsp__General_Accounting_Unit__c.getSObjectType().getDescribe().getKeyPrefix()){
        dpi = useGauIdForDonationPage(idParam, dpi);
      }
    }

    if (idParam == null || dpi.selectedFunds.size() == 0) {
      for (npsp__General_Accounting_Unit__c gau : [
        SELECT Id, Name 
        FROM npsp__General_Accounting_Unit__c 
        WHERE Name LIKE '317%' AND Name LIKE '%Where Needed Most']
      ){
        Portal_Models.SelectedFundInfo sfi = new Portal_Models.SelectedFundInfo();
        sfi.id = gau.Id;
        sfi.name = gau.Name;
        sfi.percent = 100;
        dpi.selectedFunds.add(sfi);
      }
    }

    // Get Payment Methods
    dpi.paymentMethods = Portal_AuthNetController.fetchPaymentMethods(contactId);

    return dpi;
  }
  private static Portal_Models.DonationPageInfo useGauIdForDonationPage(
    String gauId, Portal_Models.DonationPageInfo dpi
  ){
    Id validGauId = null;
    try { validGauId = gauId; }
    catch(Exception ex) {}
    for (npsp__General_Accounting_Unit__c gau : [
      SELECT Id, Name 
      FROM npsp__General_Accounting_Unit__c 
      WHERE Id = :gauId]
    ){
      Portal_Models.SelectedFundInfo sfi = new Portal_Models.SelectedFundInfo();
      sfi.id = gau.Id;
      sfi.name = gau.Name;
      sfi.percent = 100;
      dpi.selectedFunds.add(sfi);
    }
    return dpi;
  }
  private static Portal_Models.DonationPageInfo useOpportunityIdForDonationPage(
    String oppId, Portal_Models.DonationPageInfo dpi
  ){
    Id validOppId = null;
    try { validOppId = oppId; }
    catch(Exception ex) {}
      
    List<Opportunity> oppList = [
      SELECT Id, Amount, Original_Currency__c, Original_Amount__c, Donation_Form_Submission__r.Will_Cover_Processing_Fees__c, Donation_Form_Submission__r.Original_Amount__c, Donation_Form_Submission__r.Original_Amount_with_Fees__c, Donation_Form_Submission__r.Donation_Amount__c, Donation_Form_Submission__r.Total_Amount__c,
        (SELECT Id, npsp__Amount__c, Original_Amount__c, npsp__General_Accounting_Unit__r.Name, npsp__General_Accounting_Unit__r.Id
        FROM npsp__Allocations__r)
      FROM Opportunity 
      WHERE Id = :validOppId
      LIMIT 1
    ];
    if (!oppList.isEmpty()){
      Opportunity opp = oppList[0];
      dpi.previousOpp = opp;
      // calculate processing fees to make sure they get added correctly
      dpi.processingFees = opp.Donation_Form_Submission__r.Will_Cover_Processing_Fees__c;

      if (!opp.npsp__Allocations__r.isEmpty()){
        // No Processing Fees: Create the Allocations as usual
        if (!dpi.processingFees){
          for (npsp__Allocation__c alloc : opp.npsp__Allocations__r){
            Portal_Models.SelectedFundInfo sfi = new Portal_Models.SelectedFundInfo();
            sfi.id = alloc.npsp__General_Accounting_Unit__r.Id;
            sfi.name = alloc.npsp__General_Accounting_Unit__r.Name;
            sfi.amount = alloc.Original_Amount__c;
            dpi.selectedFunds.add(sfi);
          }
        } 
        // Processing Fees: Don't include allocation if only for processing fees or remove the additional processing fees if wrapped in to one allocation
        else {
          // Donation Amounts with/without Fees in Foreign/USD
          Decimal usdTotalAmount = opp.Donation_Form_Submission__r.Total_Amount__c;
          Decimal usdDonationAmt = opp.Donation_Form_Submission__r.Donation_Amount__c;
          Decimal orgTotalAmount = opp.Donation_Form_Submission__r.Original_Amount_With_Fees__c;
          Decimal orgDonationAmt = opp.Donation_Form_Submission__r.Original_Amount__c;
          // One Allocation: Remove Processing Fees from Total Allocation Amount
          if (opp.npsp__Allocations__r.size() == 1){
            npsp__Allocation__c alloc = opp.npsp__Allocations__r[0];
            Portal_Models.SelectedFundInfo sfi = new Portal_Models.SelectedFundInfo();
            sfi.id = alloc.npsp__General_Accounting_Unit__r.Id;
            sfi.name = alloc.npsp__General_Accounting_Unit__r.Name;
            sfi.amount = alloc.Original_Amount__c == orgTotalAmount
              ? orgDonationAmt : alloc.Original_Amount__c;
            dpi.selectedFunds.add(sfi);
          } 
          // Multiple Allocations: Check if one of the Allocations covers the entire processing fees amount and if so remove it from the list. Else: Remove the processing fees from the additional allocation.
          else {
            for (npsp__Allocation__c alloc : opp.npsp__Allocations__r){
              if (alloc.npsp__Amount__c != usdTotalAmount - usdDonationAmt){
                Portal_Models.SelectedFundInfo sfi = new Portal_Models.SelectedFundInfo();
                sfi.id = alloc.npsp__General_Accounting_Unit__r.Id;
                sfi.name = alloc.npsp__General_Accounting_Unit__r.Name;
                sfi.amount = alloc.Original_Amount__c;
                dpi.selectedFunds.add(sfi);
              }
            }
          }
        }
      }
    }
    return dpi;
  }
  @AuraEnabled
  public static Donation_Form_Submission__c createDonationFormSubmission(String submission){
    Portal_Models.SubmissionInfo submissionInfo = (Portal_Models.SubmissionInfo) JSON.deserialize(submission, Portal_Models.SubmissionInfo.class);
    Campaign campaign = getPortalDonationPageCampaign();
     
    // Step 1: Build Donation Form Submission Record
    Donation_Form_Submission__c dfs = Portal_AuthNetController.buildDonationFormSubmission(submissionInfo, campaign);
    
    // Step 2: (Recurring) Create the Subscription in Auth.net and put Subscription Id on DFS
    // Step 2: (Both) Charge the Payment Profile in Auth.net and put Transaction Id on DFS
    try {
      if (dfs.Frequency__c != 'One-time'){
        dfs = Portal_AuthNetController.createRecurringAuthNetSubscription(dfs);
        // Charge card for RD if the donation starts todaay
        if (Date.valueOf(submissionInfo.startDate) == Date.today()){
          dfs = Portal_AuthNetController.createAuthNetTransaction(dfs);
        }
      } 
      else {
        dfs = Portal_AuthNetController.createAuthNetTransaction(dfs);
      }
    } catch (Exception e){
      dfs.Errors__c = e.getMessage();
      System.debug(e.getMessage());
      System.debug(e.getStackTraceString());
    }
    
    // Step 3: Insert the Donation Form Submission Record
    insert dfs;

    // Step 4: Create Donation Option Selection records
    createSelectedDonationOptions(dfs, submissionInfo, campaign);
    
    // Step 5: (One-Time) Take DFS Id and pass to the Platform Event to process the donation
    if (dfs.Frequency__c == 'One-time' && !Test.isRunningTest()){
      DonationPageController.processDonation(dfs.Id);
    } 
    // Step 5: (Recurring)Create the RD record in Salesforce
    else {
      createRecurringDonation(dfs, campaign);
    }
    
    // Step 6: Return the DFS record to the component.
    return dfs;
  }
   
  // GetPortalDonationPageCampaign
  public static void createSelectedDonationOptions(
    Donation_Form_Submission__c dfs, Portal_Models.SubmissionInfo si, Campaign campaign
  ){
    Set<Id> gauIds = new Set<Id>();
    for (Portal_Models.SelectedFundInfo sf : si.selectedFunds){
      if (sf.amount > 0){
        gauIds.add(sf.id);
      }
    }
    
    // Create Campaign if none exist
    if (campaign == null){
      Campaign temp = new Campaign(
        Name = 'Biblica Donor Portal Give Page',
        IsActive = true,
        RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Donation Page').getRecordTypeId()
      );
      insert temp;
      
      campaign = getPortalDonationPageCampaign();
      if (campaign != null){
        dfs.Campaign__c = campaign.Id;
        update dfs;
      }
    }
    
    Map<Id, Donation_Option__c> doMap = getDonationOptions(gauIds, campaign.Donation_Page_Settings__c);
    List<Donation_Option_Selection__c> dosList = new List<Donation_Option_Selection__c>();

    for (Portal_Models.SelectedFundInfo sf : si.selectedFunds){
      Donation_Option_Selection__c dos = new Donation_Option_Selection__c();
      dos.Donation_Form_Submission__c = dfs.Id;
      dos.Donation_Option__c = doMap.get(sf.id).Id;
      // Set Frequency
      dos.Subscription_Id__c = dfs.Payment_Processor_Subscription_Id__c;
      dos.Frequency__c = dfs.Frequency__c;
      dos.Number_of_Recurring_Payments__c = dfs.Number_of_Recurring_Payments__c;
      // Set Currency
      dos.Original_Currency__c = si.currencyType;
      dos.Original_Amount__c = sf.amount;
      dos.Amount__c = sf.amount;
      dosList.add(dos);
    }
    
    if (!dosList.isEmpty()){
      insert dosList;
    }
  }
  public static Campaign getPortalDonationPageCampaign(){
    List<Campaign> campaignList = [
      SELECT Id, Name, Donation_Page_Settings__c
      FROM Campaign
      WHERE Name = 'Biblica Donor Portal Give Page'
      LIMIT 1
    ];
    // Campaign Exists: Return the Campaign
    return !campaignList.isEmpty() ? campaignList[0] : null;
  }
  public static Map<Id, Donation_Option__c> getDonationOptions(Set<Id> gauIds, Id dpSetting){
    Map<Id, Donation_Option__c> doMap = new Map<Id, Donation_Option__c>();
    Boolean upsertNeeded = false;

    for (Donation_Option__c donOpt : [
      SELECT Id, Fund__c 
      FROM Donation_Option__c 
      WHERE Donation_Page_Settings__c = :dpSetting AND Active__c = true AND Fund__c IN :gauIds]
    ){
      doMap.put(donOpt.Fund__c, donOpt);
    }

    for (Id gauId : gauIds){
      if (!doMap.containsKey(gauId)){
        Donation_Option__c donOpt = new Donation_Option__c(
          Active__c = true,
          Allow_Custom_Amount__c = true, 
          Name = 'Temp Name',
          Donation_Page_Settings__c = dpSetting,
          Fund__c = gauId
        );
        doMap.put(gauId, donOpt);
        upsertNeeded = true;
      }
    }

    if (upsertNeeded){
      upsert doMap.values();
    }

    return doMap;
  }
  public static void createRecurringDonation(Donation_Form_Submission__c dfs, Campaign campaign){
    Contact con = DonationPageAuthNetSubscriptionHandler.getContact(dfs);
    Account acct = DonationPageAuthNetSubscriptionHandler.getAccount(dfs, con);
    List<npe03__Recurring_Donation__c> rds = DonationPageAuthNetSubscriptionHandler.createRecurringDonation(
      dfs, acct, con, campaign
    );
    if (!rds.isEmpty()){
      Opportunity opp;
      if (String.isNotBlank(dfs.Payment_Processor_Transaction_Id__c)) {
        opp = DonationPageAuthNetSubscriptionHandler.createOpportunity(dfs, acct, con, rds[0], campaign);
      }
      DonationPageAuthNetSubscriptionHandler.createGAUAllocations(dfs, opp, rds[0]);
    }
  }
}