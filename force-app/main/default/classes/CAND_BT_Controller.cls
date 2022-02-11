public class CAND_BT_Controller {
  @AuraEnabled
  public static List<SObject> searchData(String queryParamsJSON) {
    String soslString = CAND_BT_Service.buildDynamicSOSLString(queryParamsJSON);
    System.debug(soslString);
    List<SObject> records = new List<SObject>();
    try {
      List<List<SObject>> results = Search.query(soslString);
      System.debug(results);
      for (List<SObject> result : results){
        records.addAll(result);
      }
      return records;
    } catch (Exception e) {
      throw new CAND_BT_Exception(e.getMessage());
    }
  }

  @AuraEnabled
  public static List<SObject> fetchData(String queryParamsJSON, String gauParamsJSON) {
    System.debug(queryParamsJSON);
    String queryString = CAND_BT_Service.buildDynamicQueryString(queryParamsJSON);
    List<SObject> records = new List<SObject>();
    try {
      System.debug('query');
      System.debug(queryString);
      records = Database.query(queryString);
      System.debug(records);
      if (gauParamsJSON != null) {
        String gauQueryString = CAND_BT_Service.buildDynamicQueryString(gauParamsJSON);
        List<SObject> oppsWithGaus = new List<SObject>();
        oppsWithGaus = Database.query(gauQueryString);
        for (SObject opp : oppsWithGaus) {
          if (!records.contains(opp)) {
            records.add(opp);
          }
        }
        records.sort();
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    System.debug(records);
    return records;
  }

  @AuraEnabled
  public static ConvertedLeadInfo convertLeadRecord(Id leadId){
    Lead l = [SELECT FirstName, LastName, Email FROM Lead WHERE Id = :leadId LIMIT 1];
    List<Contact> contactQuery = [
      SELECT
        Id,
        FirstName,
        LastName,
        Email,
        npe01__AlternateEmail__c,
        npe01__HomeEmail__c,
        npe01__WorkEmail__c,
        AccountId,
        Account.Language_Preference__c,
        Account.Receipt_Type__c
      FROM Contact
      WHERE
        FirstName LIKE :l.FirstName
        AND LastName LIKE :l.LastName
        AND (Email LIKE :l.Email
        OR npe01__AlternateEmail__c LIKE :l.Email
        OR npe01__HomeEmail__c LIKE :l.Email
        OR npe01__WorkEmail__c LIKE :l.Email)
    ];

    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
    Database.leadConvert lc = new Database.LeadConvert();
    lc.setLeadId(leadId);
    lc.setConvertedStatus(convertStatus.MasterLabel);
    lc.setDoNotCreateOpportunity(true);
    
    if (!contactQuery.isEmpty()){
      Contact c = contactQuery[0];
      lc.setAccountId(c.AccountId);
      lc.setContactId(c.Id);
    } else {
      Id rt = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household Account').getRecordTypeId();
      Account household = new Account(Name = 'Household', RecordTypeId = rt);
      insert household;
      lc.setAccountId(household.Id);
    }
    
    try {
      Database.LeadConvertResult lcr = Database.convertLead(lc);
      ConvertedLeadInfo cli = new ConvertedLeadInfo();
      cli.contactId = lcr.getContactId();
      cli.accountId = lcr.getAccountId();
      return cli;
    } catch (DmlException e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static SObject updateRecord(SObject record) {
    System.debug(record);
    try {
      update record;
    } catch (DmlException e) {
      throw new AuraHandledException(e.getMessage());
    }
    return record;
  }
  
  @AuraEnabled
  public static void updateAccountRecord(String recordId, Boolean ongoingDonor) {
    try {
      Account acct = new Account(
        Id = recordId,
        Is_Ongoing_Check_Donor__c = ongoingDonor
      );
      update acct;
    } catch (DmlException e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void updateRecordEdit(
    String formRecord,
    String formRecordSplits,
    String updateSplits,
    Boolean originalAmountHigher,
    String deleteRecordSplitList
  ) {
    System.debug(formRecord);
    System.debug(formRecordSplits);
    System.debug(updateSplits);
    System.debug(originalAmountHigher);
    try {
      List<npsp__Allocation__c> deleteAllocationList = (List<npsp__Allocation__c>) JSON.deserialize(
        deleteRecordSplitList,
        List<npsp__Allocation__c>.class
      );
      delete deleteAllocationList;

      List<npsp__Allocation__c> updateAllocationList = (List<npsp__Allocation__c>) JSON.deserialize(
        updateSplits,
        List<npsp__Allocation__c>.class
      );
      Opportunity opp = (Opportunity) JSON.deserialize(formRecord, Opportunity.class);
      List<npsp__Allocation__c> allocationList = (List<npsp__Allocation__c>) JSON.deserialize(
        formRecordSplits,
        List<npsp__Allocation__c>.class
      );
      for (npsp__Allocation__c allocation : allocationList) {
        allocation.npsp__Opportunity__c = opp.Id;
      }
      //needed because you can't have allocation Total higher than opp Amount
      if (originalAmountHigher) {
        update opp;
        update updateAllocationList;
        insert allocationList;
      } else {
        update updateAllocationList;
        insert allocationList;
        update opp;
      }
    } catch (Exception e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static CAND_BT_Models.PickList getFormPicklists(List<String> picklistFields, String sObjectAPIName) {
    CAND_BT_Models.PickList pl = new CAND_BT_Models.PickList();
    Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sObjectAPIName);
    Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
    pl.picklistFieldMap = getPicklistFieldMap(fieldMap, picklistFields);
    return pl;
  }

  private static Map<String, CAND_BT_Models.PicklistField> getPicklistFieldMap(
    Map<String, Schema.SObjectField> fieldMap,
    List<String> fieldAPINames
  ) {
    Map<String, CAND_BT_Models.PicklistField> picklistFieldMap = new Map<String, CAND_BT_Models.PicklistField>();
    for (String fieldAPIName : fieldAPINames) {
      Schema.SObjectField f = fieldMap.get(fieldAPIName.trim());
      Schema.DescribeFieldResult fd = f.getDescribe();

      CAND_BT_Models.PicklistField pf = new CAND_BT_Models.PicklistField(
        fd.getLabel(),
        fd.getName(),
        fd.getType().name().toLowerCase(),
        fd.getPicklistValues()
      );
      picklistFieldMap.put(fd.getName(), pf);
    }
    return picklistFieldMap;
  }

  @AuraEnabled
  public static List<Future_Gift__c> getFutureGifts(String accountId){
    return [SELECT 
              Id, 
              Name, 
              Account__r.Name,
              Primary_Contact__r.Name,
              Paid_By__r.Name,
              Account__c,
              Primary_Contact__c,
              Paid_By__c,
              Gift_Description__c,
              RecordType.Name, 
              Stage__c, 
              Giving_Start__c,
              Giving_End__c,
              Original_Currency__c, 
              Original_Target_Ask_Amount__c,
              Target_Ask_Amount__c,
              Original_Actual_Ask_Amount__c,
              Actual_Ask_Amount__c,
              (SELECT 
                Id, 
                Name,
                Allocation_Amount__c, 
                General_Accounting_Unit__c,
                General_Accounting_Unit__r.Id,
                General_Accounting_Unit__r.Name,
                General_Accounting_Unit__r.Default_Fund_GL_Account__c,
                General_Accounting_Unit__r.Default_Fund_GL_Account__r.Id,
                General_Accounting_Unit__r.Default_Fund_GL_Account__r.Name,
                Description__c, 
                Tax_Deductible__c,
                Campaign__c,
                Campaign__r.Id, 
                Campaign__r.Name 
              FROM Future_Gift_Allocations__r)
            FROM Future_Gift__c
            WHERE (
              Account__c = :accountId 
              OR Paid_By__c = :accountId) 
              AND Stage__c != 'Stewardship' AND Stage__c != 'Declined']; 
  }

  @AuraEnabled
  public static Opportunity submitForm(String formRecord, String formRecordSplits) {
    System.debug('CAND_BT_FormController.submitForm');
    System.debug(formRecord);
    System.debug(formRecordSplits);

    Opportunity opp;
    List<npsp__Allocation__c> allocationList = new List<npsp__Allocation__c>();

    try {
      opp = (Opportunity) JSON.deserialize(formRecord, Opportunity.class);
      allocationList = (List<npsp__Allocation__c>) JSON.deserialize(formRecordSplits, List<npsp__Allocation__c>.class);
    } catch (Exception e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }

    System.debug(opp);
    System.debug(allocationList);

    // Insert all or nothing
    Database.SaveResult formRecordResult = Database.insert(opp);
    System.debug(formRecordResult);

    if (formRecordResult.isSuccess()) {
      // Operation was successful, so get the ID of the record that was processed
      System.debug('Successfully inserted record. Id: ' + formRecordResult.getId());
      System.debug(formRecordResult);
    } else {
      // Operation failed, so get all errors
      for (Database.Error err : formRecordResult.getErrors()) {
        System.debug('The following error has occurred:');
        System.debug(err.getStatusCode() + ': ' + err.getMessage());
        System.debug('Fields that affected this error: ' + err.getFields());
        throw new AuraHandledException(err.getMessage());
      }
    }

    for (npsp__Allocation__c allocation : allocationList) {
      allocation.npsp__Opportunity__c = opp.Id;
    }

    List<Database.SaveResult> allocationResults = Database.insert(allocationList, true);
    for (Database.SaveResult sr : allocationResults) {
      if (sr.isSuccess()) {
        // Operation was successful, so get the ID of the record that was processed
        System.debug('Successfully inserted record. Id: ' + sr.getId());
        System.debug(sr);
      } else {
        // Operation failed, so get all errors
        for (Database.Error err : sr.getErrors()) {
          System.debug('The following error has occurred:');
          System.debug(err.getStatusCode() + ': ' + err.getMessage());
          System.debug('Fields that affected this error: ' + err.getFields());
          throw new AuraHandledException(err.getMessage());
        }
      }
    }

    return opp;
  }

  @AuraEnabled
  public static Cash_batch__c getNewParent(String parentRecordId) {
    Cash_Batch__c cb = [
      SELECT
        Id,
        Name,
        Status__c,
        Date__c,
        Original_Currency__c,
        Control_Batch_Size__c,
        Original_Control_Batch_Total__c,
        Original_Total_Included_in_Batch__c,
        Original_Balance__c,
        Control_Batch_Total__c,
        Records_included_in_Batch__c,
        Total_Included_in_Batch__c,
        Balance__c,
        CreatedDate,
        Type__c,
        Opportunity_Type__c
      FROM Cash_Batch__c
      WHERE id = :parentRecordId
      LIMIT 1
    ];
    return cb;
  }

  @AuraEnabled
  public static List<Opportunity> getOppRecord(String oppId) {
    List<Opportunity> opp = [
      SELECT
        Id,
        Name,
        AccountId,
        Account.Name,
        Account.Receipt_Type__c,
        Account.Language_Preference__c,
        Account.Is_Ongoing_Check_Donor__c,
        // Account.Receipting_Frequency__c, TO DO: Get these
        // Account.Receipting_Tax_Information_Preference__c,
        npsp__Primary_Contact__c,
        npsp__Primary_Contact__r.Name,
        npsp__Primary_Contact__r.Receipt_Type__c,
        CampaignId,
        Campaign.Name,
        Amount,
        Original_Amount__c, 
        Original_Currency__c,
        CloseDate,
        Description,
        Future_Gift__c,
        Future_Gift__r.Name,
        Language_Preference__c,
        Payment_Method__c,
        Paid_By__c,
        Paid_by__r.Name,
        Is_Anonymous__c,
        Donation_Source__c,
        Giving_Method__c,
        StageName,
        Payment_Reference_Number__c,
        Receipt_Type__c,
        Keyer__c,
        Keyer__r.Name,
        npsp__Acknowledgment_Status__c,
        Stock_Name__c,
        Stock_Symbol__c,
        Number_Of_Shares__c,
        Broker__c,
        RecordTypeId,
        npsp__Fair_Market_Value__c,
        npsp__In_Kind_Donor_Declared_Value__c,
        npsp__In_Kind_Type__c,
        npsp__In_Kind_Description__c,
        Cash_Batch__r.Original_Currency__c,
        (SELECT Id, Name, Original_Amount__c, Original_Currency__c, npsp__Amount__c, npsp__General_Accounting_Unit__r.Name, Campaign__r.Name, Campaign__c, Description__c, Tax_Deductible__c, Fund_GL_Account__r.Name, Fund_GL_Account__r.Id, Fund_GL_Account__c FROM npsp__Allocations__r),
        (SELECT Id, Name, npsp__Matching_Gift__c FROM npsp__MatchedGifts__r)
      FROM Opportunity
      WHERE id = :oppId
      LIMIT 1
    ];

    return opp;
  }

  @AuraEnabled
  public static List<CAND_BT_Receipt_Key_Over__mdt> getKeyovers() {
    return [SELECT Append_To_Front__c, Message_Title__c, Message_to_Add__c FROM CAND_BT_Receipt_Key_Over__mdt];
  }

  @AuraEnabled
  public static List<string> getGivingOptions() {
    List<String> pickListValuesList = new List<String>();
    Schema.DescribeFieldResult fieldResult = Opportunity.Giving_Method__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for (Schema.PicklistEntry pickListVal : ple) {
      pickListValuesList.add(pickListVal.getLabel());
    }
    return pickListValuesList;
  }

  @AuraEnabled
  public static List<string> getReceiptTypes() {
    List<String> pickListValuesList = new List<String>();
    Schema.DescribeFieldResult fieldResult = Opportunity.Receipt_Type__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for (Schema.PicklistEntry pickListVal : ple) {
      pickListValuesList.add(pickListVal.getLabel());
    }
    return pickListValuesList;
  }
  
  @AuraEnabled
  public static List<string> getLanguagePreferences() {
    List<String> pickListValuesList = new List<String>();
    Schema.DescribeFieldResult fieldResult = Account.Language_Preference__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for (Schema.PicklistEntry pickListVal : ple) {
      pickListValuesList.add(pickListVal.getLabel());
    }
    return pickListValuesList;
  }
  
  @AuraEnabled
  public static List<string> getDonationSources() {
    List<String> pickListValuesList = new List<String>();
    Schema.DescribeFieldResult fieldResult = Opportunity.Donation_Source__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for (Schema.PicklistEntry pickListVal : ple) {
      pickListValuesList.add(pickListVal.getLabel());
    }
    return pickListValuesList;
  }

  @AuraEnabled
  public static List<Account> donorSearch(List<String> searchTerms, Decimal amount) {
    List<Account> accounts = new List<Account>();
    if (searchTerms == null || searchTerms.isEmpty()) {
      return accounts;
    }
    List<String> searchWildcardValues = new List<String>();
    for (String searchVal : searchTerms) {
      searchWildcardValues.add(searchVal + '*');
    }
    String sosl = 'FIND \'' + String.join(searchWildcardValues, ' AND ') + '\' IN ALL FIELDS RETURNING Account(Id), Contact(AccountId)';
    List<List<SObject>> results = Search.query(sosl);
    List<SObject> combinedResults = new List<SObject>();
    for (List<SObject> sobjList : results){
      combinedResults.addAll(sobjList);
    }
    Map<Id, SObject> accountSearchResults = new Map<Id, SObject>(combinedResults);

    if (accountSearchResults.isEmpty()) {
      return accounts;
    }

    Set<Id> accountIds = accountSearchResults.keySet();
    String query =
      'SELECT Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, ' +
      '(SELECT Original_Amount__c, Amount, Original_Currency__c, CloseDate, Giving_Method__c FROM Opportunities';
    if (amount != null) {
      query += ' WHERE Original_Amount__c = ' + amount;
    } else {
      query += ' WHERE CloseDate <= TODAY';
    }
    query += ' AND (isClosed = true OR StageName = \'Adjustment\')';
    query += ' ORDER BY CloseDate DESC LIMIT 5)';
    query += ' FROM Account';
    query += ' WHERE Id IN :accountIds';
    query += ' LIMIT 150';

    return Database.query(query);
  }

  @AuraEnabled
  public static Opportunity opportunitySearch(String query) {
    return Database.query(query);
  }

  @AuraEnabled
  public static List<Opportunity> checkForOtherOpps(Id AccountId, Date CloseDate) {
    return [SELECT Id, Receipt_Type__c FROM Opportunity WHERE AccountId = :AccountId AND CloseDate = :CloseDate];
  }

  @AuraEnabled
  public static void setStageToAdjustment(Opportunity opp) {
    opp.StageName = 'Adjustment';
    update opp;
  }

  @AuraEnabled
  public static void markReceipted(String batchIdsJSON) {
    List<Cash_Batch__c> batchIds = (List<Cash_Batch__c>) JSON.deserialize(batchIdsJSON, List<Cash_Batch__c>.class);
    List<Cash_Batch__c> cashBatches = [SELECT Id, Receipted_Date__c FROM Cash_Batch__c WHERE Id IN :batchIds];

    List<Opportunity> oppList = [
      SELECT Id, npsp__Acknowledgment_Status__c
      FROM Opportunity
      WHERE
        Cash_Batch__c IN :batchIds
        AND npsp__Acknowledgment_Status__c != 'Do Not Acknowledge'
        AND (Receipt_Type__c = 'Email'
        OR Receipt_Type__c = 'Print' 
        OR Receipt_Type__c = 'Both')
    ];
    for (Opportunity opp : oppList) {
      opp.npsp__Acknowledgment_Status__c = 'Acknowledged';
    }
    update oppList;

    for (Cash_Batch__c cb : cashBatches) {
      cb.Receipted_Date__c = Date.today();
    }
    update cashBatches;
  }

  @AuraEnabled
  public static String getTodaysDate() {
    return DateTime.now().format('yyyy-MM-dd');
  }

  @AuraEnabled
  public static User getUserId() {
    String uid = UserInfo.getUserId();
    return [SELECT Id, Name, Username FROM User WHERE Id = :uid];
  }

  @AuraEnabled
  public static Id getReconciliationReportId() {
    List<Report> reports = [
      SELECT Id, Name
      FROM Report 
      WHERE Name = 'Batch Reconciliation Report'
    ];
    if (!reports.isEmpty()) {
      return reports[0].Id;
    } else {
      throw new CAND_BT_Exception('The "Batch Reconciliation Report" report couldn\'t be found!');
    }
  }
  
  @AuraEnabled
  public static Id getGauReportId() {
    List<Report> reports = [
      SELECT Id, Name
      FROM Report 
      WHERE Name = 'Opportunity: Missing GAU Allocations'
    ];
    if (!reports.isEmpty()) {
      return reports[0].Id;
    } else {
      throw new CAND_BT_Exception('The "Opportunity: Missing GAU Allocations" report couldn\'t be found!');
    }
  }

  @AuraEnabled
  public static IdTypes returnIdTypes() {
    IdTypes ids = new IdTypes();
    ids.matchingGift = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Matching Gift').getRecordTypeId();
    ids.inKindGift = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('In-Kind Gift').getRecordTypeId();
    return ids;
  }

  @AuraEnabled
  public static void setMatchingGiftLookup(List<Opportunity> matchingGifts, Opportunity opp) {
    for (Opportunity gift : matchingGifts) {
      gift.npsp__Matching_Gift__c = opp.Id;
    }
    update matchingGifts;
  }

  @AuraEnabled
  public static void removeMatchingGiftLookup(List<Opportunity> deleteMatchingGifts) {
    for (Opportunity gift : deleteMatchingGifts) {
      gift.npsp__Matching_Gift__c = null;
    }
    update deleteMatchingGifts;
  }

  public class IdTypes {
    @AuraEnabled
    public Id matchingGift;
    @AuraEnabled
    public Id inKindGift;
  }
  
  public class ConvertedLeadInfo {
    @AuraEnabled
    public Id contactId;
    @AuraEnabled
    public Id accountId;
  }
}