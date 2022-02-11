public without sharing class OpportunityService {
  public static final String recordIsLockedError = 'The following fields cannot edited if the Opportunity belongs to a Batch that has already been approved: Amount, Stage, CloseDate, Account, Primary Contact, Paid By, Cash Batch, Recurring Donation, CampaignId, and Record Type.';
  
  // Trigger Context: Before Insert. Also used as a utility method.
  public static void handleCurrencyConversion(List<Opportunity> opps) {
    List<Opportunity> oppsForConversion = new List<Opportunity>();
    // Initialize the calculator class because we are assuming that the Original_Currency__c field is populated.
    CurrencyExchangeRateCalculator calculator = new CurrencyExchangeRateCalculator();
    for (Opportunity opp : opps){
      if (!opp.Override_Currency_Conversion__c){
        if (opp.Original_Amount__c == null && opp.Amount != null){
          opp.Original_Amount__c = opp.Amount;
          opp.Original_Currency__c = opp.Original_Currency__c == null 
            ? 'USD' : opp.Original_Currency__c;
        }
        oppsForConversion.add(opp);
      }
    }
    oppsForConversion = (List<Opportunity>) calculator.handleBulkConversion(oppsForConversion, 'Amount', null);
  }

  // Trigger Context: Before Update.
  // Convert currencies if Amount, Original_Amount__c, or Original_Currency__c field has changed.
  public static void handleCurrencyConversionBeforeUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppMap) {
    List<Opportunity> oppsToConvert = new List<Opportunity>();

    // Determine if there are opps to convert so that we don't have to waste a soql query when
    // initalizing the CurrencyExchangeRateCalculator
    for (Opportunity newOpp : newOpps) {
      if (!newOpp.Override_Currency_Conversion__c){
        if (String.isBlank(newOpp.Original_Currency__c)) {
          newOpp.Amount = 0;
        } else {
          Opportunity oldOpp = oldOppMap.get(newOpp.Id);
          if (oldOpp.Amount != newOpp.Amount ||
            oldOpp.Original_Amount__c != newOpp.Original_Amount__c ||
            oldOpp.Original_Currency__c != newOpp.Original_Currency__c
          ) {
            // Before Update, field changed
            oppsToConvert.add(newOpp);
          }
        }
      }
    }

    if (!oppsToConvert.isEmpty()) {
      handleCurrencyConversion(oppsToConvert);
    }
  }
  
  public static void assignAccountSoftCredits(List<Opportunity> oppList) {
    Set<Id> acctIds = new Set<Id>();
    Map<Id, List<Account_Relationship__c>> acctRelMap = new Map<Id, List<Account_Relationship__c>>();

    for (Opportunity opp : oppList) {
      acctIds.add(opp.AccountId);
      acctRelMap.put(opp.AccountId, new List<Account_Relationship__c>());
    }

    List<Account_Relationship__c> acctList = [
      SELECT Id, Account__c, Related_Account__c, Soft_Credit_Role__c
      FROM Account_Relationship__c
      WHERE Related_Account__c IN :acctIds AND Receives_Soft_Credit__c = true
    ];

    for (Account_Relationship__c ar : acctList) {
      List<Account_Relationship__c> scAcctList = acctRelMap.get(ar.Related_Account__c);
      scAcctList.add(ar);
      acctRelMap.put(ar.Related_Account__c, scAcctList);
    }

    List<npsp__Account_Soft_Credit__c> ascList = new List<npsp__Account_Soft_Credit__c>();

    for (Opportunity opp : oppList) {
      List<Account_Relationship__c> scAcctList = acctRelMap.get(opp.AccountId);
      if (!scAcctList.isEmpty()) {
        for (Account_Relationship__c scAcct : scAcctList) {
          npsp__Account_Soft_Credit__c sc = new npsp__Account_Soft_Credit__c(
            npsp__Account__c = scAcct.Account__c,
            npsp__Amount__c = opp.Amount,
            npsp__Opportunity__c = opp.Id,
            npsp__Role__c = scAcct.Soft_Credit_Role__c
          );
          ascList.add(sc);
        }
      }
    }
    insert ascList;
  }

  public static void updateAmountOnSoftCredit(List<Opportunity> oppList, Map<Id, Opportunity> oldOppMap) {
    if (oldOppMap != null) {
      Set<Id> oppIds = new Set<Id>();
      Map<Id, List<npsp__Account_Soft_Credit__c>> scMap = new Map<Id, List<npsp__Account_Soft_Credit__c>>();

      for (Opportunity opp : oppList) {
        oppIds.add(opp.Id);
        scMap.put(opp.Id, new List<npsp__Account_Soft_Credit__c>());
      }

      List<npsp__Account_Soft_Credit__c> ascList = [
        SELECT Id, npsp__Amount__c, npsp__Opportunity__c
        FROM npsp__Account_Soft_Credit__c
        WHERE npsp__Opportunity__c IN :oppIds
      ];

      for (npsp__Account_Soft_Credit__c sc : ascList) {
        List<npsp__Account_Soft_Credit__c> tempList = scMap.get(sc.npsp__Opportunity__c);
        tempList.add(sc);
        scMap.put(sc.npsp__Opportunity__c, tempList);
      }

      List<npsp__Account_Soft_Credit__c> scUpdateList = new List<npsp__Account_Soft_Credit__c>();

      for (Opportunity opp : oppList) {
        List<npsp__Account_Soft_Credit__c> scList = scMap.get(opp.Id);
        Opportunity oldOpp = oldOppMap.get(opp.Id);

        for (npsp__Account_Soft_Credit__c sc : scList) {
          if (sc.npsp__Amount__c == null || sc.npsp__Amount__c == oldOpp.Amount) {
            sc.npsp__Amount__c = opp.Amount;
            scUpdateList.add(sc);
          }
        }
      }

      update scUpdateList;
    }
  }

  public static void batchIncomingDonationsHandler(List<Opportunity> oppList) {
    Set<Date> dates = new Set<Date>();
    Map<Id, Donation_Form_Submission__c> dfsMap = new Map<Id, Donation_Form_Submission__c>();
    Map<Date, List<Opportunity>> closeDateMap = new Map<Date, List<Opportunity>>();
    for (Opportunity opp : oppList) {
      // if the opp has a DFS add it to the dfsMap
      if (opp.Donation_Form_Submission__c != null) {
        dfsMap.put(opp.Donation_Form_Submission__c, null);
      }
    }
    if (dfsMap != null) {
      // if dfsMap has values, get the DFS records 
      List<Donation_Form_Submission__c> dfsList = [SELECT Id, Test_Mode_Submission__c FROM Donation_Form_Submission__c WHERE Id IN :dfsMap.keySet()];
      for (Donation_Form_Submission__c dfs : dfsList) {
        dfsMap.put(dfs.Id, dfs);
      }
    }
    for (Opportunity opp : oppList) {
      // only check opps with a DFS set
      if (opp.Donation_Form_Submission__c != null) {
        // null pointer check
        if (dfsMap != null) {
          Donation_Form_Submission__c dfs = dfsMap.get(opp.Donation_Form_Submission__c);
          // null pointer check
          if (dfs != null) {
            // if dfs is in test mode, remove from batch
            if (dfs.Test_Mode_Submission__c == true) {
              System.debug('Opp is Test Mode Submission');
              break;
            }
          }
        }
      } 
      // extra check for neon migration
      if (opp.NeonId__c != null) {
        break;
      }
      // set up closeDateMap with close_date -> list<opp>
      List<Opportunity> opps = closeDateMap.get(opp.CloseDate);
      if (opps == null) {
        opps = new List<Opportunity>();
      }
      opps.add(opp);
      closeDateMap.put(opp.CloseDate, opps);
      dates.add(opp.CloseDate);
    }
    // for each close date in the batch, call batchIncomingDonations
    for (Date closeDate : dates) {
      if (closeDateMap.get(closeDate) != null) {
        batchIncomingDonations(closeDateMap.get(closeDate), closeDate);
      }
    }
  }

  public static void batchIncomingDonations(List<Opportunity> oppList, Date closeDate) {
    Set<String> amexList = new Set<String>{'AMEX','AmericanExpress','American Express','AmEx'};
    // allow this function to be called from dev console and batchIncomingDonationsHandler, but default to today if not set
    if (closeDate == null) {
      closeDate = Date.today();
    }

    Map<String, Cash_Batch__c> batchMap = new Map<String, Cash_Batch__c>();
    Map<String, Cash_Batch__c> batchesToUpdate = new Map<String, Cash_Batch__c>();
    Set<String> batchKeys = new Set<String>();
    Set<String> types = new Set<String>();
    Set<String> variations = new Set<String>();
    Set<String> regions = new Set<String>();

    // set up types, variations and batchKeys lists
    for (Opportunity opp : oppList) {
      // only run for posted opps with the given close date that do not have a batch assigned or for adjustment opps
      if (
        (opp.StageName == 'Posted' || opp.StageName == 'Adjustment') 
        && opp.CloseDate == closeDate 
        && opp.Cash_Batch__c == null
      ){
        String type = null;
        String variation = null;
        String batchKey = null;
        String region = null;
        if (opp.Payment_Method__c == 'Credit Card' && !amexList.contains(opp.Credit_Card_Type__c)
        ){
          type = opp.StageName == 'Posted' ? 'Credit Cards' : 'Adjustments';
          variation = opp.StageName == 'Posted' ? 'A' : 'AA';
          batchKey = opp.StageName == 'Posted' ? 'Credit Cards_A' : 'Adjustments_AA';
        } 
        else if (opp.Payment_Method__c == 'Credit Card' && amexList.contains(opp.Credit_Card_Type__c)  
        ){
          type = opp.StageName == 'Posted' ? 'Credit Cards' : 'Adjustments';
          variation = opp.StageName == 'Posted' ? 'B' : 'BB';
          batchKey = opp.StageName == 'Posted' ? 'Credit Cards_B' : 'Adjustments_BB';
        } 
        else if (opp.Payment_Method__c == 'Bank Account') {
          type = opp.StageName == 'Posted' ? 'Bank Accounts' : 'Adjustments';
          variation = opp.StageName == 'Posted' ? 'C' : 'CC';
          batchKey = opp.StageName == 'Posted' ? 'Bank Accounts_C' : 'Adjustments_CC';
        }
        if (opp.Region_Category__c != null) {
          batchKey = batchKey + '_' + opp.Region_Category__c;
          region = opp.Region_Category__c;
        }
        if (type != null) {types.add(type);}
        if (variation != null) {variations.add(variation);}
        if (region != null) {regions.add(region);}
        if (batchKey != null) {batchKeys.add(batchKey);}
        System.debug(batchKey);
      }
    }

    // make sure types and variations are set, otherwise avoid SOQL 
    if (!types.isEmpty() && !variations.isEmpty()) {
      for (Cash_Batch__c batch : [
        SELECT Id, Type__c, Is_Locked__c, Batch_Variation__c, Status__c, Region_Category__c
        FROM Cash_Batch__c
        WHERE 
          (Type__c IN :types 
          AND Batch_Variation__c IN :variations
          AND Date__c = :closeDate
          AND (Region_Category__c = :regions OR Region_Category__c = null))
      ]) {
        String batchKey = batch.Region_Category__c != null
          ? batch.Type__c + '_' + batch.Batch_Variation__c + '_' + batch.Region_Category__c
          : batch.Type__c + '_' + batch.Batch_Variation__c;
        batchMap.put(batchKey, batch);
      }
    }
    
    List<Cash_Batch__c> newBatches = new List<Cash_Batch__c>();
    for (String key : batchKeys) {
      // if there is not a batch with the type + variation combination, create a new batch
      if (batchMap.get(key) == null) {
        Cash_Batch__c cashBatch = new Cash_Batch__c();
        cashBatch.Date__c = closeDate;
        cashBatch.Type__c = key.substringBefore('_');
        cashBatch.Batch_Variation__c = key.indexOf('_') != key.lastIndexOf('_')
          ? key.substringBetween('_') : key.substringAfter('_'); 
        cashBatch.Region_Category__c = key.indexOf('_') != key.lastIndexOf('_')
          ? key.substringAfterLast('_') : null;
        newBatches.add(cashBatch);
        batchMap.put(key, cashBatch);
      }
    }
    
    // insert new batches if there are any
    if (!newBatches.isEmpty()) {
      insert newBatches;
    }
    // match the opps up with both existing and newly created batches
    // assign batch id if a match is found
    for (Opportunity opp : oppList) {
      String key = null;

      if (opp.Payment_Method__c == 'Credit Card' && !amexList.contains(opp.Credit_Card_Type__c)
      ){
        key = opp.StageName == 'Posted' ? 'Credit Cards_A' : 'Adjustments_AA';
      } else if (opp.Payment_Method__c == 'Credit Card' && amexList.contains(opp.Credit_Card_Type__c)
      ){
        key = opp.StageName == 'Posted' ? 'Credit Cards_B' : 'Adjustments_BB';
      } else if (opp.Payment_Method__c == 'Bank Account') {
        key = opp.StageName == 'Posted' ? 'Bank Accounts_C' : 'Adjustments_CC';
      }
      if (key != null && opp.Region_Category__c != null){
        key = key + '_' + opp.Region_Category__c;
      }
  
      if (key != null && batchMap.containsKey(key)){
        Cash_Batch__c tempBatch = batchMap.get(key);
        opp.Cash_Batch__c = tempBatch.Id;
        // check and see if the batch is closed then update status to "Under Review"
        if (tempBatch.Status__c == 'Closed' || tempBatch.Status__c == 'Approved'){
          tempBatch.Status__c = 'Under Review';
          batchesToUpdate.put(tempBatch.Id, tempBatch);
        }      
      }
    }
    if (!batchesToUpdate.isEmpty()){
      update batchesToUpdate.values();
    }
  }

  public static void rollupBatchedOpps(List<Opportunity> opportunities, Map<Id, Opportunity> oldMap) {
    Set<Id> cashBatchIds = new Set<Id>();
    for (Opportunity opp : opportunities) {
      if (oldMap != null) {
        Opportunity oldOpp = oldMap != null ? oldMap.get(opp.Id) : null;       
        if (
          oldOpp != null && 
          ((oldOpp.Cash_Batch__c != opp.Cash_Batch__c) ||
          (oldOpp.Amount != opp.Amount))
        ) {
          if (opp.Cash_Batch__c != null) {
            cashBatchIds.add(opp.Cash_Batch__c);
          }
          if (oldOpp.Cash_Batch__c != null) {
            cashBatchIds.add(oldOpp.Cash_Batch__c);
          }
        }
      } else {
        if (opp.Cash_Batch__c != null) {
          cashBatchIds.add(opp.Cash_Batch__c);
        }
      }
    }
    if (!cashBatchIds.isEmpty()) {
      rollupToBatch(cashBatchIds);
    }
  }

  public static void rollupToBatch(Set<Id> cashBatchIds) {
    if (!cashBatchIds.isEmpty()) {
      Map<Id, Cash_Batch__c> batchesToUpdate = new Map<Id, Cash_Batch__c>();
      for (Cash_Batch__c cb : [SELECT Id, Records_Included_in_Batch__c, Total_Included_in_Batch__c
                                FROM Cash_Batch__c WHERE Id IN :cashBatchIds AND Turn_off_Cash_Batch_Rollups__c = false]
      ){
        Cash_Batch__c temp = new Cash_Batch__c();
        temp.Id = cb.Id;
        temp.Records_Included_in_Batch__c = 0;
        temp.Total_Included_in_Batch__c = 0;
        batchesToUpdate.put(cb.Id, temp);
      }

      for (AggregateResult ar : [
        SELECT sum(Amount) total, count(Id) ct, Cash_Batch__c
        FROM Opportunity
        WHERE Cash_Batch__c IN :batchesToUpdate.keySet()
        AND Cash_Batch__r.Turn_off_Cash_Batch_Rollups__c = false
        GROUP BY Cash_Batch__c
      ]){
        Id cbId = String.valueOf(ar.get('Cash_Batch__c'));
        if (cbId != null){
          Cash_Batch__c cb = batchesToUpdate.get(cbId);
          cb.Records_Included_in_Batch__c = Double.valueOf(ar.get('ct'));
          cb.Total_Included_in_Batch__c = Double.valueOf(ar.get('total'));
        }
      }

      if (!batchesToUpdate.isEmpty()){
        update batchesToUpdate.values();
      }
    }
  }

  public static void ensureBatchIsEditable(List<Opportunity> opportunities, Map<Id, Opportunity> oldMap) {
    Set<Id> cashBatchIds = new Set<Id>();
    for (Opportunity opp : opportunities) {
      // update
      if (oldMap != null) {
        Opportunity oldOpp = oldMap.get(opp.Id);
        // can't edit specified fields in a closed batch
        if (
          (opp.StageName != oldOpp.StageName &&
          opp.StageName != 'Adjustment') ||
          (opp.CloseDate != oldOpp.CloseDate || 
          opp.AccountId != oldOpp.AccountId || 
          opp.Paid_By__c != oldOpp.Paid_By__c || 
          opp.npsp__Primary_Contact__c != oldOpp.npsp__Primary_Contact__c || 
          opp.Amount != oldOpp.Amount || 
          opp.Cash_Batch__c != oldOpp.Cash_Batch__c || 
          opp.npe03__Recurring_Donation__c != oldOpp.npe03__Recurring_Donation__c || 
          opp.RecordTypeId != oldOpp.RecordTypeId || 
          opp.CampaignId != oldOpp.CampaignId)
        ) {
          cashBatchIds.add(opp.Cash_Batch__c);
        }
      // create/delete/undelete
      } else if (opp.Cash_Batch__c != null) {
        cashBatchIds.add(opp.Cash_Batch__c);
      }
    }
    if (!cashBatchIds.isEmpty()) {
      Map<Id, Cash_Batch__c> batchMap = new Map<Id, Cash_Batch__c>(
        [
          SELECT Id, Status__c, Is_Locked__c
          FROM Cash_Batch__c
          WHERE Id IN :cashBatchIds AND Is_Locked__c = true
        ]
      );
      if (!batchMap.isEmpty()) {
        for (Opportunity opp : opportunities) {
          if (batchMap.get(opp.Cash_Batch__c) != null) {
            opp.addError(recordIsLockedError);
          }
        }
      }
    }
  }

  public static void futureGiftRollups(List<Opportunity> oppList, Map<Id, Opportunity> oldMap) {
    Set<Id> futureGiftIds = new Set<Id>();
    for (Opportunity opp : oppList) {
      if (oldMap != null) {
        Opportunity oldOpp = oldMap.get(opp.Id);
        if (
          oldOpp != null &&
          ((oldOpp.Future_Gift__c != opp.Future_Gift__c) ||
          (oldOpp.Future_Gift__c == opp.Future_Gift__c &&
          (oldOpp.Amount != opp.Amount ||
          oldOpp.IsWon != opp.IsWon)))
        ) {
          if (oldOpp.Future_Gift__c != null) {
            futureGiftIds.add(oldOpp.Future_Gift__c);
          }
          if (opp.Future_Gift__c != null) {
            futureGiftIds.add(opp.Future_Gift__c);
          }
        }
      } else {
        if (opp.Future_Gift__c != null) {
          futureGiftIds.add(opp.Future_Gift__c);
        }
      }
    }

    Map<Id, Future_Gift__c> futureGiftsToUpdate = new Map<Id, Future_Gift__c>();
    for (Future_Gift__c fg : [SELECT Id, Amount_Received__c FROM Future_Gift__c WHERE Id IN :futureGiftIds]) {
      Future_Gift__c temp = new Future_Gift__c();
      temp.Id = fg.Id;
      temp.Amount_Received__c = 0;
      futureGiftsToUpdate.put(fg.Id, temp);
    }

    for (AggregateResult ar : [
      SELECT sum(Amount) amt, Future_Gift__c
      FROM Opportunity
      WHERE Future_Gift__c IN :futureGiftsToUpdate.keySet() AND IsWon = true
      GROUP BY Future_Gift__c
    ]) {
      Id fgId = String.valueOf(ar.get('Future_Gift__c'));
      if (fgId != null) {
        Future_Gift__c fg = futureGiftsToUpdate.get(fgId);
        fg.Amount_Received__c = Double.valueOf(ar.get('amt'));
      }
    }
    if (!futureGiftsToUpdate.isEmpty()) {
      update futureGiftsToUpdate.values();
    }
  }

  public static void createOpportuntityContactRolesFromFutureGift(List<Opportunity> oppList) {
    Map<Id, List<Opportunity>> futureGiftMap = new Map<Id, List<Opportunity>>();
    
    for (Opportunity opp : oppList) {
      if (opp.Future_Gift__c != null) {
        List<Opportunity> tempList = !futureGiftMap.isEmpty() && futureGiftMap.get(opp.Future_Gift__c) != null
          ? futureGiftMap.get(opp.Future_Gift__c)
          : new List<Opportunity>();
        tempList.add(opp);
        futureGiftMap.put(opp.Future_Gift__c, tempList);
      }
    }

    if (!futureGiftMap.isEmpty()){
      List<OpportunityContactRole> ocrToCreate = new List<OpportunityContactRole>();
      List<npsp__Account_Soft_Credit__c> ascToCreate = new List<npsp__Account_Soft_Credit__c>();

      List<Future_Gift__c> futureGifts = [
        SELECT Id, (
          SELECT Id, Status__c, Contact__c, Role__c, Soft_Credit__c, Organization__c 
          FROM Future_Gift_Roles__r
          WHERE Contact__c != null 
            OR (Organization__c != null AND Soft_Credit__c = true)
        ) 
        FROM Future_Gift__c
        WHERE Id IN :futureGiftMap.keySet()
      ];

      for (Future_Gift__c fg : futureGifts) {
        List<Opportunity> opps = !futureGiftMap.isEmpty() && futureGiftMap.get(fg.Id) != null
          ? futureGiftMap.get(fg.Id)
          : null;

        if (!opps.isEmpty()){
          for (Opportunity opp : opps){
            if (!fg.Future_Gift_Roles__r.isEmpty()){
              for (Future_Gift_Role__c fgr : fg.Future_Gift_Roles__r){
                if (fgr.Contact__c != null && fgr.Contact__c != opp.npsp__Primary_Contact__c){
                  OpportunityContactRole ocr = new OpportunityContactRole(
                    ContactId = fgr.Contact__c,
                    OpportunityId = opp.Id,
                    Role = fgr.Soft_Credit__c == true ? 'Soft Credit' : 'Influencer'
                  );
                  ocrToCreate.add(ocr);
                }
                if (fgr.Organization__c != null && fgr.Soft_Credit__c == true && fgr.Organization__c != opp.AccountId){
                  npsp__Account_Soft_Credit__c sc = new npsp__Account_Soft_Credit__c(
                    npsp__Account__c = fgr.Organization__c,
                    npsp__Opportunity__c = opp.Id,
                    npsp__Role__c = 'Soft Credit',
                    npsp__Amount__c = opp.Amount
                  );
                  ascToCreate.add(sc);
                }
              }
            }
          }
        }
      }
  
      if (!ocrToCreate.isEmpty()) {
        insert ocrToCreate;
      }
      if (!ascToCreate.isEmpty()) {
        insert ascToCreate;
      }
    }
  }
}