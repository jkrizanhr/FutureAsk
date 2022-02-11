public inherited sharing class GAUAllocationService {
  public static final String recordIsLockedError = 'The following fields cannot edited if the Opportunity belongs to a Batch that has already been approved: Opportunity, Amount, Percent, Campaign, NPSP Campaign, Recurring Donation and General Accounting Unit.';

  // Trigger Context: Before Insert. Also used as a utility method.
  public static void handleCurrencyConversion(
    List<npsp__Allocation__c> allocs
  ) {
    List<npsp__Allocation__c> allocToConvert = new List<npsp__Allocation__c>();
    // Initialize the calculator class because we are assuming that the Original_Currency__c field is populated.
    CurrencyExchangeRateCalculator calculator = new CurrencyExchangeRateCalculator();
    for (npsp__Allocation__c alloc : allocs) {
      if (!alloc.Override_Currency_Conversion__c) {
        if (alloc.Original_Amount__c == null && alloc.npsp__Amount__c != null) {
          alloc.Original_Amount__c = alloc.npsp__Amount__c;
          alloc.Original_Currency__c = alloc.Original_Currency__c == null
            ? 'USD'
            : alloc.Original_Currency__c;
        }
        allocToConvert.add(alloc);
      }
    }
    allocToConvert = (List<npsp__Allocation__c>) calculator.handleBulkConversion(
      allocToConvert,
      'npsp__Amount__c',
      null
    );
  }

  // Trigger Context: Before Update.
  // Convert currencies if Amount, Original_Amount__c, or Original_Currency__c field has changed.
  public static void handleCurrencyConversionBeforeUpdate(
    List<npsp__Allocation__c> newAllocs,
    Map<Id, npsp__Allocation__c> oldAllocMap
  ) {
    List<npsp__Allocation__c> allocToConvert = new List<npsp__Allocation__c>();

    // Determine if there are allocs to convert so that we don't have to waste a soql query when
    // initalizing the CurrencyExchangeRateCalculator
    for (npsp__Allocation__c newAlloc : newAllocs) {
      if (!newAlloc.Override_Currency_Conversion__c) {
        if (String.isBlank(newAlloc.Original_Currency__c)) {
          newAlloc.npsp__Amount__c = 0;
        } else {
          npsp__Allocation__c oldAlloc = oldAllocMap.get(newAlloc.Id);
          if (
            oldAlloc.Original_Amount__c != newAlloc.Original_Amount__c ||
            oldAlloc.Original_Currency__c != newAlloc.Original_Currency__c
          ) {
            // Before Update, field changed
            allocToConvert.add(newAlloc);
          }
        }
      }
    }

    if (!allocToConvert.isEmpty()) {
      handleCurrencyConversion(allocToConvert);
    }
  }

  private static String getCloseMonth(Integer month) {
    String closeMonth = null;
    switch on month {
      when 1 {
        closeMonth = 'January';
      }
      when 2 {
        closeMonth = 'February';
      }
      when 3 {
        closeMonth = 'March';
      }
      when 4 {
        closeMonth = 'April';
      }
      when 5 {
        closeMonth = 'May';
      }
      when 6 {
        closeMonth = 'June';
      }
      when 7 {
        closeMonth = 'July';
      }
      when 8 {
        closeMonth = 'August';
      }
      when 9 {
        closeMonth = 'September';
      }
      when 10 {
        closeMonth = 'October';
      }
      when 11 {
        closeMonth = 'November';
      }
      when 12 {
        closeMonth = 'December';
      }
    }
    return closeMonth;
  }

  public static void updateCloseMonthOnGauAllocation(
    List<npsp__Allocation__c> allocList
  ) {
    Map<Id, List<npsp__Allocation__c>> oppMap = new Map<Id, List<npsp__Allocation__c>>();
    Map<Id, List<npsp__Allocation__c>> allocMap = new Map<Id, List<npsp__Allocation__c>>();
    for (npsp__Allocation__c alloc : allocList) {
      if (
        alloc.npsp__Recurring_Donation__c != null &&
        (alloc.Close_Month__c == null ||
        alloc.Account_Id__c == null)
      ) {
        List<npsp__Allocation__c> temp = allocMap.containsKey(
            alloc.npsp__Recurring_Donation__c
          )
          ? allocMap.get(alloc.npsp__Recurring_Donation__c)
          : new List<npsp__Allocation__c>();
        temp.add(alloc);
        allocMap.put(alloc.npsp__Recurring_Donation__c, temp);
      } else if (
        alloc.npsp__Opportunity__c != null &&
        (alloc.Close_Month__c == null ||
        alloc.Account_Id__c == null)
      ) {
        List<npsp__Allocation__c> temp = oppMap.containsKey(
            alloc.npsp__Opportunity__c
          )
          ? oppMap.get(alloc.npsp__Opportunity__c)
          : new List<npsp__Allocation__c>();
        temp.add(alloc);
        oppMap.put(alloc.npsp__Opportunity__c, temp);
      }
    }
    if (!oppMap.isEmpty()) {
      for (Opportunity opp : [
        SELECT Id, npe03__Recurring_Donation__c, CloseDate
        FROM Opportunity
        WHERE Id IN :oppMap.keySet()
      ]) {
        String closeMonth = getCloseMonth(opp.CloseDate.month());
        for (npsp__Allocation__c alloc : oppMap.get(opp.Id)) {
          alloc.Close_Month__c = closeMonth;
          alloc.Account_Id__c = opp.AccountId;
        }
      }
    }
    if (!allocMap.isEmpty()) {
      for (npe03__Recurring_Donation__c rd : [
        SELECT Id, npe03__Date_Established__c, npe03__Organization__c
        FROM npe03__Recurring_Donation__c
        WHERE Id IN :allocMap.keySet()
      ]) {
        String closeMonth = getCloseMonth(
          rd.npe03__Date_Established__c.month()
        );
        for (npsp__Allocation__c alloc : allocMap.get(rd.Id)) {
          alloc.Close_Month__c = closeMonth;
          alloc.Account_Id__c = rd.npe03__Organization__c;
        }
      }
    }
  }

  public static void getCampaignFromRecurringDonation(
    List<npsp__Allocation__c> allocList,
    Boolean isUpdate
  ) {
    Map<Id, List<npsp__Allocation__c>> oppMap = new Map<Id, List<npsp__Allocation__c>>();
    Map<Id, List<npsp__Allocation__c>> allocMap = new Map<Id, List<npsp__Allocation__c>>();
    for (npsp__Allocation__c alloc : allocList) {
      if (
        alloc.npsp__Recurring_Donation__c != null &&
        alloc.Campaign__c == null
      ) {
        List<npsp__Allocation__c> temp = allocMap.containsKey(
            alloc.npsp__Recurring_Donation__c
          )
          ? allocMap.get(alloc.npsp__Recurring_Donation__c)
          : new List<npsp__Allocation__c>();
        temp.add(alloc);
        allocMap.put(alloc.npsp__Recurring_Donation__c, temp);
      } else if (
        alloc.npsp__Opportunity__c != null &&
        alloc.Campaign__c == null
      ) {
        List<npsp__Allocation__c> temp = oppMap.containsKey(
            alloc.npsp__Opportunity__c
          )
          ? oppMap.get(alloc.npsp__Opportunity__c)
          : new List<npsp__Allocation__c>();
        temp.add(alloc);
        oppMap.put(alloc.npsp__Opportunity__c, temp);
      }
    }
    if (!oppMap.isEmpty()) {
      for (Opportunity opp : [
        SELECT
          Id,
          npe03__Recurring_Donation__c,
          npe03__Recurring_Donation__r.npe03__Recurring_Donation_Campaign__c
        FROM Opportunity
        WHERE
          Id IN :oppMap.keySet()
          AND npe03__Recurring_Donation__c != null
          AND npe03__Recurring_Donation__r.npe03__Recurring_Donation_Campaign__c != null
      ]) {
        for (npsp__Allocation__c alloc : oppMap.get(opp.Id)) {
          alloc.Campaign__c = opp.npe03__Recurring_Donation__r.npe03__Recurring_Donation_Campaign__c !=
            null
            ? opp.npe03__Recurring_Donation__r.npe03__Recurring_Donation_Campaign__c
            : null;
        }
      }
    }
    if (!allocMap.isEmpty()) {
      for (npe03__Recurring_Donation__c rd : [
        SELECT Id, npe03__Recurring_Donation_Campaign__c
        FROM npe03__Recurring_Donation__c
        WHERE Id IN :allocMap.keySet()
      ]) {
        for (npsp__Allocation__c alloc : allocMap.get(rd.Id)) {
          alloc.Campaign__c = rd.npe03__Recurring_Donation_Campaign__c != null
            ? rd.npe03__Recurring_Donation_Campaign__c
            : null;
        }
      }
    }
  }

  public static void taxDeductibleRollupToOpp(
    List<npsp__Allocation__c> allocList,
    Map<Id, npsp__Allocation__c> oldMap
  ) {
    Set<Id> oppIds = new Set<Id>();
    for (npsp__Allocation__c alloc : allocList) {
      if (oldMap != null) {
        npsp__Allocation__c oldAlloc = oldMap.get(alloc.Id);
        if (
          oldAlloc != null &&
          ((oldAlloc.Tax_Deductible__c != alloc.Tax_Deductible__c) ||
          (oldAlloc.Tax_Deductible__c == alloc.Tax_Deductible__c &&
          alloc.Tax_Deductible__c == true &&
          (oldAlloc.npsp__Amount__c != alloc.npsp__Amount__c) ||
          (oldAlloc.npsp__Opportunity__c != alloc.npsp__Opportunity__c)))
        ) {
          if (oldAlloc.npsp__Opportunity__c != null) {
            oppIds.add(oldAlloc.npsp__Opportunity__c);
          }
          if (alloc.npsp__Opportunity__c != null) {
            oppIds.add(alloc.npsp__Opportunity__c);
          }
        }
      } else {
        if (
          alloc.Tax_Deductible__c == true &&
          alloc.npsp__Opportunity__c != null
        ) {
          oppIds.add(alloc.npsp__Opportunity__c);
        }
      }
    }

    Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
    for (Opportunity opp : [
      SELECT Id, Tax_Deductible_Amount__c
      FROM Opportunity
      WHERE Id IN :oppIds
    ]) {
      Opportunity temp = new Opportunity();
      temp.Id = opp.Id;
      temp.Tax_Deductible_Amount__c = 0;
      oppsToUpdate.put(opp.Id, temp);
    }

    for (AggregateResult ar : [
      SELECT sum(npsp__Amount__c) amt, npsp__Opportunity__c
      FROM npsp__Allocation__c
      WHERE
        npsp__Opportunity__c IN :oppsToUpdate.keySet()
        AND Tax_Deductible__c = true
      GROUP BY npsp__Opportunity__c
    ]) {
      Id oppId = String.valueOf(ar.get('npsp__Opportunity__c'));
      if (oppId != null) {
        Opportunity opp = oppsToUpdate.get(oppId);
        opp.Tax_Deductible_Amount__c = Double.valueOf(ar.get('amt'));
      }
    }
    if (!oppsToUpdate.isEmpty()) {
      update oppsToUpdate.values();
    }
  }

  public static void ensureBatchIsEditable(
    List<npsp__Allocation__c> gauAllocations,
    Map<Id, npsp__Allocation__c> oldMap
  ) {
    Set<Id> opportunityIds = new Set<Id>();
    for (npsp__Allocation__c allocation : gauAllocations) {
      if (oldMap != null) {
        npsp__Allocation__c oldAlloc = oldMap.get(allocation.Id);
        if (
          allocation.npsp__Opportunity__c != oldAlloc.npsp__Opportunity__c ||
          allocation.npsp__Amount__c != oldAlloc.npsp__Amount__c ||
          allocation.npsp__Percent__c != oldAlloc.npsp__Percent__c ||
          allocation.Campaign__c != oldAlloc.Campaign__c ||
          allocation.npsp__Campaign__c != oldAlloc.npsp__Campaign__c ||
          allocation.npsp__General_Accounting_Unit__c !=
          oldAlloc.npsp__General_Accounting_Unit__c ||
          allocation.npsp__Recurring_Donation__c !=
          oldAlloc.npsp__Recurring_Donation__c
        ) {
          opportunityIds.add(allocation.npsp__Opportunity__c);
        }
      } else {
        opportunityIds.add(allocation.npsp__Opportunity__c);
      }
    }
    Map<Id, Opportunity> opportunityWithApprovedBatchMap = new Map<Id, Opportunity>();
    if (!opportunityIds.isEmpty()) {
      List<Opportunity> oppList = [
        SELECT Id, Cash_Batch__c
        FROM Opportunity
        WHERE Id IN :opportunityIds AND Cash_Batch__r.Is_Locked__c = true
      ];
      if (oppList != null && !oppList.isEmpty()) {
        for (Opportunity opp : oppList) {
          opportunityWithApprovedBatchMap.put(opp.Id, opp);
        }
      }
    }
    if (!opportunityWithApprovedBatchMap.isEmpty()) {
      for (npsp__Allocation__c allocation : gauAllocations) {
        if (
          opportunityWithApprovedBatchMap.get(
            allocation.npsp__Opportunity__c
          ) != null
        ) {
          allocation.addError(recordIsLockedError);
        }
      }
    }
  }

  public static void updateCampaignMembers(
    List<npsp__Allocation__c> allocationList
  ) {
    Map<String, CampaignMember> campaignMembers = new Map<String, CampaignMember>();
    List<npsp__Allocation__c> allocations = new List<npsp__Allocation__c>();
    Map<npsp__Allocation__c, Id> campaignIds = new Map<npsp__Allocation__c, Id>();
    Map<npsp__Allocation__c, Id> contactIds = new Map<npsp__Allocation__c, Id>();

    List<npsp__Allocation__c> allocationsToCheck = [
      SELECT Campaign__c, npsp__Opportunity__r.npsp__Primary_contact__c
      FROM npsp__Allocation__c
      WHERE Id IN :allocationList
    ];

    for (npsp__Allocation__c a : allocationsToCheck) {
      if (
        a.Campaign__c != null &&
        a.npsp__Opportunity__r.npsp__Primary_contact__c != null
      ) {
        campaignIds.put(a, a.Campaign__c);
        contactIds.put(a, a.npsp__Opportunity__r.npsp__Primary_contact__c);
        allocations.add(a);
      }
    }

    if (!allocations.isEmpty()) {
      //get campaigns (alloc, campaign) map
      //subquery campaignMembers
      Map<Id, Campaign> campaigns = new Map<Id, Campaign>(
        [
          SELECT
            Id,
            (
              SELECT Id, CampaignId, ContactId, Status
              FROM CampaignMembers
              WHERE ContactId IN :contactIds.values()
            )
          FROM Campaign
          WHERE Id IN :campaignIds.values()
        ]
      );

      //Query and Map member statuses to ensure status is HasResponded
      List<CampaignMemberStatus> memberStatus = [
        SELECT Id, HasResponded, Label, CampaignId
        FROM CampaignMemberStatus
        WHERE CampaignId IN :campaignIds.values() AND HasResponded = true
      ];
      Map<String, String> memberStatusMap = new Map<String, String>();
      for (CampaignMemberStatus cms : memberStatus) {
        memberStatusMap.put(cms.CampaignId, cms.Label);
      }

      //iterate through allocs
      for (npsp__Allocation__c a : allocations) {
        //get campign and contact from map
        Id campaignId = campaignIds.get(a);
        Id contactId = contactIds.get(a);
        Campaign campaign = campaigns.get(campaignId);
        String respondedStatusLabel = memberStatusMap.get(campaignId);

        //check if contact in campaign members
        Boolean exists = false;
        for (CampaignMember cm : campaign.CampaignMembers) {
          if (cm.ContactId == contactId) {
            exists = true;
            if (cm.Status != respondedStatusLabel) {
              cm.Status = respondedStatusLabel;
              campaignMembers.put(cm.ContactId + '-' + cm.CampaignId, cm);
            }
            break;
            // check to see if it is active and then update if not
          }
        }

        //if not add it
        if (!exists) {
          CampaignMember cm = new CampaignMember();
          cm.ContactId = contactId;
          cm.CampaignId = campaignId;
          cm.Status = respondedStatusLabel;
          campaignMembers.put(cm.ContactId + '-' + cm.CampaignId, cm);
        }
      }

      if (!campaignMembers.isEmpty()) {
        upsert campaignMembers.values();
      }
    }
  }

  public static void setDefaultFundGLAccount(
    List<npsp__Allocation__c> allocationList
  ) {
    Set<Id> gauIds = new Set<Id>();
    for (npsp__Allocation__c all : allocationList) {
      if (
        all.Fund_GL_Account__c == null &&
        all.npsp__General_Accounting_Unit__c != null
      ) {
        gauIds.add(all.npsp__General_Accounting_Unit__c);
      }
    }

    Map<Id, npsp__General_Accounting_Unit__c> gauMap = new Map<Id, npsp__General_Accounting_Unit__c>();
    for (npsp__General_Accounting_Unit__c gau : [
      SELECT Id, Default_Fund_GL_Account__c
      FROM npsp__General_Accounting_Unit__c
      WHERE Id IN :gauIds
    ]) {
      gauMap.put(gau.Id, gau);
    }

    for (npsp__Allocation__c all : allocationList) {
      if (
        all.Fund_GL_Account__c == null &&
        all.npsp__General_Accounting_Unit__c != null
      ) {
        npsp__General_Accounting_Unit__c gau = gauMap.get(
          all.npsp__General_Accounting_Unit__c
        );
        if (gau != null && gau.Default_Fund_GL_Account__c != null) {
          all.Fund_GL_Account__c = gau.Default_Fund_GL_Account__c;
        }
      }
    }
  }

  /**
   * Utility method to retrieve the campaigns and parent campaigns for a total of 3 levels along
   * with the associated receipt message or major donor receipt message rich text fields
   * for campaigns that are related to the allocations.
   * @param campaignIds - A set of campaign ids from the allocations
   * @return Map<Id, Campaign> - A map of the campaign query results
   */
  private static Map<Id, Campaign> fetchCampaigns(Set<Id> campaignIds) {
    return new Map<Id, Campaign>(
      [
        SELECT
          Id,
          Major_Donor_Receipt_Message__c,
          Parent.Major_Donor_Receipt_Message__c,
          Parent.Parent.Major_Donor_Receipt_Message__c,
          Parent.Parent.Receipt_Message__c,
          Parent.Parent.Recurring_Donation_Receipt_Message__c,
          Parent.ParentId,
          Parent.Receipt_Message__c,
          Parent.Recurring_Donation_Receipt_Message__c,
          ParentId,
          Receipt_Message__c,
          Recurring_Donation_Receipt_Message__c
        FROM Campaign
        WHERE Id IN :campaignIds
      ]
    );
  }

  /**
   * Utility method to retrieve a mutable version of the gau allocations along with the
   * traversal to retrieve the is major donor value on the account, which is used to determine
   * which receipt message field to use from the campaign.
   * @param allocations - A list of allocations from the trigger
   * @return Map<Id, npsp__Allocation> - A map of allocations from the query results
   */
  private static Map<Id, npsp__Allocation__c> fetchMutableAllocations(
    List<npsp__Allocation__c> allocations
  ) {
    return new Map<Id, npsp__Allocation__c>(
      [
        SELECT
          Id,
          npsp__Opportunity__c,
          npsp__Opportunity__r.AccountId,
          npsp__Opportunity__r.Account.Is_Major_Donor__c,
          Receipt_Message__c,
          Campaign__c,
          npsp__Opportunity__r.npe03__Recurring_Donation__c
        FROM npsp__Allocation__c
        WHERE Id IN :allocations
      ]
    );
  }

  /**
   * Utility method to contain the logic for determining which receipt message rich text field
   * to use in relation to the gau allocation.
   * @param mutableAllocation - The gau allocation which contains the reference for traversing to
   * the is major donor checkbox value on the account
   * @param campaign - The campaign related to the gau allocation which contains references
   * to the parent campaign up to a total of 3 levels including the current campaign. This is
   * used for obtaining the receipt message.
   * @return String - The rich text field value from the receipt message, major donor receipt
   * message or recurring donation receipt message, prior to doing any merge field processing.
   */
  private static String getCampaignReceiptMessage(
    npsp__Allocation__c mutableAllocation,
    Campaign campaign
  ) {
    String campaignReceiptMessage;
    if (
      mutableAllocation.npsp__Opportunity__c != null &&
      mutableAllocation.npsp__Opportunity__r.AccountId != null &&
      mutableAllocation.npsp__Opportunity__r.Account.Is_Major_Donor__c == true
    ) {
      // Use the major donor receipt message
      if (String.isNotBlank(campaign.Major_Donor_Receipt_Message__c)) {
        campaignReceiptMessage = campaign.Major_Donor_Receipt_Message__c;
      } else if (
        campaign.ParentId != null &&
        String.isNotBlank(campaign.Parent.Major_Donor_Receipt_Message__c)
      ) {
        campaignReceiptMessage = campaign.Parent.Major_Donor_Receipt_Message__c;
      } else if (
        campaign.ParentId != null &&
        campaign.Parent.ParentId != null &&
        String.isNotBlank(campaign.Parent.Parent.Major_Donor_Receipt_Message__c)
      ) {
        campaignReceiptMessage = campaign.Parent.Parent.Major_Donor_Receipt_Message__c;
      }
    } else if (
      mutableAllocation.npsp__Opportunity__c != null &&
      mutableAllocation.npsp__Opportunity__r.npe03__Recurring_Donation__c !=
      null
    ) {
      // Use the recurring donation receipt message
      if (String.isNotBlank(campaign.Recurring_Donation_Receipt_Message__c)) {
        campaignReceiptMessage = campaign.Recurring_Donation_Receipt_Message__c;
      } else if (
        campaign.ParentId != null &&
        String.isNotBlank(campaign.Parent.Recurring_Donation_Receipt_Message__c)
      ) {
        campaignReceiptMessage = campaign.Parent.Recurring_Donation_Receipt_Message__c;
      } else if (
        campaign.ParentId != null &&
        campaign.Parent.ParentId != null &&
        String.isNotBlank(
          campaign.Parent.Parent.Recurring_Donation_Receipt_Message__c
        )
      ) {
        campaignReceiptMessage = campaign.Parent.Parent.Recurring_Donation_Receipt_Message__c;
      }
    } else {
      // Use the standard receipt message
      if (String.isNotBlank(campaign.Receipt_Message__c)) {
        campaignReceiptMessage = campaign.Receipt_Message__c;
      } else if (
        campaign.ParentId != null &&
        String.isNotBlank(campaign.Parent.Receipt_Message__c)
      ) {
        campaignReceiptMessage = campaign.Parent.Receipt_Message__c;
      } else if (
        campaign.ParentId != null &&
        campaign.Parent.ParentId != null &&
        String.isNotBlank(campaign.Parent.Parent.Receipt_Message__c)
      ) {
        campaignReceiptMessage = campaign.Parent.Parent.Receipt_Message__c;
      }
    }

    return campaignReceiptMessage;
  }

  /**
   * After Insert, After Update
   * This method is responsible for copying the receipt message from the campaign or a campaign
   * in the hierarchy and then replacing merge fields in the receipt message.
   * This has to be after insert and after update so that we can use formula fields for the
   * merge field processing.
   * @param allocations - Trigger.new
   * @param oldMap - Trigger.oldMap
   */
  public static void copyReceiptMessage(
    List<npsp__Allocation__c> allocationList,
    Map<Id, npsp__Allocation__c> oldMap
  ) {
    Set<Id> campaignIds = new Set<Id>();
    List<npsp__Allocation__c> allocations = new List<npsp__Allocation__c>();
    List<npsp__Allocation__c> allocationUpdateList = new List<npsp__Allocation__c>();

    // Iterate over the allocations determine those that need the receipt message updated
    // and get the campaign ids as well
    for (npsp__Allocation__c allocation : allocationList) {
      if (allocation.Campaign__c == null) {
        if (String.isNotBlank(allocation.Receipt_Message__c)) {
          npsp__Allocation__c allocationUpdate = new npsp__Allocation__c();
          allocationUpdate.Id = allocation.Id;
          allocationUpdate.Receipt_Message__c = null;
          allocationUpdateList.add(allocationUpdate);
        }
      } else if (oldMap == null) {
        // After Insert and has a campaign
        campaignIds.add(allocation.Campaign__c);
        allocations.add(allocation);
      } else {
        // After Update and has a campaign
        npsp__Allocation__c oldAllocation = oldMap.get(allocation.Id);
        if (allocation.Campaign__c != oldAllocation.Campaign__c) {
          // Campaign lookup has changed
          campaignIds.add(allocation.Campaign__c);
          allocations.add(allocation);
        } else if (
          allocation.Campaign__c != null &&
          String.isBlank(allocation.Receipt_Message__c)
        ) {
          // Receipt Message was blanked out so we need to rerun the copy and merge process
          campaignIds.add(allocation.Campaign__c);
          allocations.add(allocation);
        }
      }
    }

    if (campaignIds.isEmpty()) {
      if (!allocationUpdateList.isEmpty()) {
        // Update the allocations that need the receipt message cleared out before exiting the method
        update allocationUpdateList;
      }
      return;
    }

    // Get allocations that can be updated as well as the account is major donor checkbox value
    Map<Id, npsp__Allocation__c> mutableAllocationMap = fetchMutableAllocations(
      allocations
    );

    // Get the campaigns and their receipt messages
    Map<Id, Campaign> campaignMap = fetchCampaigns(campaignIds);

    // Instantiate the merge field processor class
    DocumentMergeFieldProcessor mergeFieldProcessor = new DocumentMergeFieldProcessor();

    // Iterate over allocations that need the receipt message copied
    for (npsp__Allocation__c allocation : allocations) {
      npsp__Allocation__c mutableAllocation = mutableAllocationMap.get(
        allocation.Id
      );
      Campaign campaign = campaignMap.get(allocation.Campaign__c);
      // Get the receipt message from the related campaign
      String campaignReceiptMessage = getCampaignReceiptMessage(
        mutableAllocation,
        campaign
      );

      if (String.isNotBlank(campaignReceiptMessage)) {
        // Run the merge field processing to replace any merge fields with fields
        // that exist on the allocation record
        mergeFieldProcessor.record = allocation;
        mergeFieldProcessor.stringToParseThru = campaignReceiptMessage;
        mutableAllocation.Receipt_Message__c = mergeFieldProcessor.processString();
        // Add the allocation to the list for updating
        allocationUpdateList.add(mutableAllocation);
      } else if (String.isNotBlank(allocation.Receipt_Message__c)) {
        // The campaign receipt message is blank, so make sure it's blank on the allocation as well
        mutableAllocation.Receipt_Message__c = null;
        // Add the allocation to the list for updating
        allocationUpdateList.add(mutableAllocation);
      }
    }

    // Update the allocations
    update allocationUpdateList;
  }

  /**
   * @description This method runs after insert of a new allocation record. It copies the overhead
   * percentages from the GAU to the allocation record.
   * @param allocations Trigger.new
   */
  public static void copyOverheadPercentageToAllocations(
    List<npsp__Allocation__c> allocations
  ) {
    Set<Id> gauIds = new Set<Id>();

    for (npsp__Allocation__c alloc : allocations) {
      gauIds.add(alloc.npsp__General_Accounting_Unit__c);
    }

    Map<Id, npsp__General_Accounting_Unit__c> gauMap = new Map<Id, npsp__General_Accounting_Unit__c>(
      [
        SELECT Id, Global_Admin_Overhead__c, Program_Management_Overhead__c
        FROM npsp__General_Accounting_Unit__c
        WHERE Id IN :gauIds
      ]
    );

    for (npsp__Allocation__c alloc : allocations) {
      npsp__General_Accounting_Unit__c overhead = gauMap.get(
        alloc.npsp__General_Accounting_Unit__c
      );

      if (overhead != null) {
        if (alloc.Global_Admin_Percentage__c == null) {
          alloc.Global_Admin_Percentage__c = overhead.Global_Admin_Overhead__c;
        }
        if (alloc.Program_Management_Percentage__c == null) {
          alloc.Program_Management_Percentage__c = overhead.Program_Management_Overhead__c;
        }
      }
    }
  }
}