public inherited sharing class FutureGiftService {

  // Trigger Context: Before Insert. Also used as a utility method.
  public static void handleCurrencyConversionTargetAsk(List<Future_Gift__c> gifts) {
    // Initialize the calculator class because we are assuming that the Original_Currency__c field is populated.
    CurrencyExchangeRateCalculator calculator = new CurrencyExchangeRateCalculator();
    gifts = (List<Future_Gift__c>) calculator.handleBulkConversion(gifts, 'Target_Ask_Amount__c', 'Original_Target_Ask_Amount__c');
  }
  
  public static void handleCurrencyConversionActualAsk(List<Future_Gift__c> gifts) {
    // Initialize the calculator class because we are assuming that the Original_Currency__c field is populated.
    CurrencyExchangeRateCalculator calculator = new CurrencyExchangeRateCalculator();
    gifts = (List<Future_Gift__c>) calculator.handleBulkConversion(gifts, 'Actual_Ask_Amount__c', 'Original_Actual_Ask_Amount__c');
  }

  // Trigger Context: Before Update.
  // Convert currencies if Amount, Original_Amount__c, or Original_Currency__c field has changed.
  public static void handleCurrencyConversionBeforeUpdate(List<Future_Gift__c> newGifts, Map<Id, Future_Gift__c> oldGiftMap) {
    List<Future_Gift__c> giftsToConvertTargetAsk = new List<Future_Gift__c>();
    List<Future_Gift__c> giftsToConvertActualAsk = new List<Future_Gift__c>();

    // Determine if there are gifts to convert so that we don't have to waste a soql query when
    // initalizing the CurrencyExchangeRateCalculator
    for (Future_Gift__c newGift : newGifts) {
      if (String.isBlank(newGift.Original_Currency__c)) {
        newGift.Original_Actual_Ask_Amount__c = 0;
        newGift.Original_Target_Ask_Amount__c = 0;
      } else {
        Future_Gift__c oldGift = oldGiftMap.get(newGift.Id);
        if (oldGift.Original_Currency__c != newGift.Original_Currency__c) {
          // Before Update, field changed
          giftsToConvertTargetAsk.add(newGift);
          giftsToConvertActualAsk.add(newGift);
        } else {
          if (oldGift.Original_Target_Ask_Amount__c != newGift.Original_Target_Ask_Amount__c){
            giftsToConvertTargetAsk.add(newGift);
          }
          if (oldGift.Original_Actual_Ask_Amount__c != newGift.Original_Actual_Ask_Amount__c){
            giftsToConvertActualAsk.add(newGift);
          }
        }
      }
    }

    if (!giftsToConvertTargetAsk.isEmpty()) {
      handleCurrencyConversionTargetAsk(giftsToConvertTargetAsk);
    }
    if (!giftsToConvertActualAsk.isEmpty()) {
      handleCurrencyConversionActualAsk(giftsToConvertActualAsk);
    }
  }

  public static void futureGiftRollupsToAccount(List<Future_Gift__c> fgList, Map<Id, Future_Gift__c> oldMap) {
    Id proposalRecordTypeId = Schema.SObjectType.Future_Gift__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
    Id pledgeRecordTypeId = Schema.SObjectType.Future_Gift__c.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
    Id legacyRecordTypeId = Schema.SObjectType.Future_Gift__c.getRecordTypeInfosByName().get('Legacy').getRecordTypeId();
    Set<Id> accountIds = new Set<Id>();

    for (Future_Gift__c fg : fgList) {
      if (oldMap != null) {
        Future_Gift__c oldGift = oldMap.get(fg.Id);
        if (oldGift != null && (
          (oldGift.Account__c != fg.Account__c) || (oldGift.Account__c == fg.Account__c && oldGift.RecordTypeId != fg.RecordTypeId))
        ) {
          if (oldGift.Account__c != null) {
            accountIds.add(oldGift.Account__c);
          }
          if (fg.Account__c != null) {
            accountIds.add(fg.Account__c);
          }
        }
      } else {
        accountIds.add(fg.Account__c);
      }
    }

    if (!accountIds.isEmpty()){
      Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
      for (Account acct : [SELECT Id, Number_of_Future_Gift_Proposals__c, Legacy_Club__c, Has_Pledge__c, Has_Proposal__c FROM Account WHERE Id IN :accountIds]) {
        Account temp = new Account();
        temp.Id = acct.Id;
        temp.Number_of_Future_Gift_Proposals__c = 0;
        temp.Legacy_Club__c = false;
        temp.Has_Pledge__c = false;
        temp.Has_Proposal__c = false;
        accountsToUpdate.put(acct.Id, temp);
      }
  
      for (AggregateResult ar : [
        SELECT count(Id) ct, Account__c, RecordTypeId
        FROM Future_Gift__c
        WHERE Account__c IN :accountsToUpdate.keySet()
        GROUP BY Account__c, RecordTypeId
      ]) {
        Id acctId = String.valueOf(ar.get('Account__c'));
        Id rtId = String.valueOf(ar.get('RecordTypeId'));
        if (acctId != null) {
          Account acct = accountsToUpdate.get(acctId);
          if (rtId != null){
            if (rtId == proposalRecordTypeId){
              acct.Number_of_Future_Gift_Proposals__c = Double.valueOf(ar.get('ct'));
              acct.Has_Proposal__c = true;
            } else if (rtId == pledgeRecordTypeId){
              acct.Has_Pledge__c = true;
            } else if (rtId == legacyRecordTypeId){
              acct.Legacy_Club__c = true;
            }
          }
        }
      }
      if (!accountsToUpdate.isEmpty()) {
        update accountsToUpdate.values();
      }
    }
  }

  public static void createFutureGiftRoleForDonorRelationshipManager(List<Future_Gift__c> fgs) {
    Set<Id> accIds = new Set<Id>();
    for (Future_Gift__c fg : fgs) {
      accIds.add(fg.Account__c);
    }
    Map<Id, Id> accMap = new Map<Id, Id>();
    for (Account acc : [SELECT Id, Donor_Relationship_Manager__c FROM Account WHERE Id IN: accIds AND Donor_Relationship_Manager__c != null]) {
      accMap.put(acc.Id, acc.Donor_Relationship_Manager__c);
    }
    List<Future_Gift_Role__c> fgRoles = new List<Future_Gift_Role__c>();
    if (accMap != null) {
      for (Future_Gift__c fg : fgs) {
        if (accMap.get(fg.Account__c) != null) {
          Future_Gift_Role__c fgRole = new Future_Gift_Role__c();
          fgRole.Future_Gift__c = fg.Id;
          fgRole.Status__c = 'Current';
          fgRole.Role__c = 'Relationship Manager';
          fgRole.Biblica_Staff_Member__c = accMap.get(fg.Account__c);
          fgRoles.add(fgRole);
        }
      }
    }
    if (!fgRoles.isEmpty()) {
      insert fgRoles;
    }
  }

  public static void createFutureGiftStageHistoryRecord(List<Future_Gift__c> gifts, Map<Id, Future_Gift__c> oldMap) {
    List<Future_Gift_Stage_History__c> stageHistoryToUpsert = new List<Future_Gift_Stage_History__c>();
    Set<Id> futureGiftIds = new Set<Id>();

    for (Future_Gift__c fg : gifts){
      if (oldMap != null) {
        Future_Gift__c oldfg = oldMap.get(fg.Id);
        if (oldfg != null && (oldfg.Stage__c != fg.Stage__c)) {
          Future_Gift_Stage_History__c ash = new Future_Gift_Stage_History__c(
            Previous_Stage__c = oldfg.Stage__c,
            New_Stage__c = fg.Stage__c,
            Start_Date__c = Date.today(),
            Future_Gift__c = fg.Id
          );
          stageHistoryToUpsert.add(ash);
          futureGiftIds.add(fg.Id);          
        }
      } else {
        if (fg.Stage__c != null) {
          Future_Gift_Stage_History__c ash = new Future_Gift_Stage_History__c(
            New_Stage__c = fg.Stage__c,
            Start_Date__c = Date.today(),
            Future_Gift__c = fg.Id
          );
          stageHistoryToUpsert.add(ash);
        }
      }
    }

    if (!futureGiftIds.isEmpty()){
      for (Future_Gift_Stage_History__c ash : [SELECT Id, End_Date__c FROM Future_Gift_Stage_History__c WHERE Future_Gift__c IN :futureGiftIds AND End_Date__c = null]){
        ash.End_Date__c = Date.today();
        stageHistoryToUpsert.add(ash);
      }
    }

    if (!stageHistoryToUpsert.isEmpty()){
      upsert stageHistoryToUpsert id;
    }
  }

  public static void validateAllocationsOnStageChange(List<Future_Gift__c> gifts, Map<Id, Future_Gift__c> oldMap) {
    Map<Id, Future_Gift__c> futureGiftMap = new Map<Id, Future_Gift__c>();
    for (Future_Gift__c fg : gifts){
      if (oldMap != null) {
        Future_Gift__c oldfg = oldMap.get(fg.Id);
        if (oldfg != null && fg.Validate_Allocations__c == true && (oldfg.Stage__c != fg.Stage__c)) {
          futureGiftMap.put(fg.Id, fg);          
        }
      } 
    }

    if (!futureGiftMap.isEmpty()){
      for (AggregateResult ar : [
        SELECT sum(Allocation_Amount__c) amt, Future_Gift__c
        FROM Future_Gift_Allocation__c
        WHERE Future_Gift__c IN :futureGiftMap.keySet()
        GROUP BY Future_Gift__c
      ]) {
        Id fgId = String.valueOf(ar.get('Future_Gift__c'));
        if (fgId != null) {
          Double askAmount = futureGiftMap.get(fgId).Actual_Ask_Amount__c;
          Double allocAmount = Double.valueOf(ar.get('amt'));
          if (askAmount == null || askAmount == 0){
            futureGiftMap.get(fgId).addError('The Future Ask must have the Original Actual Amount set before moving past the "Solicitation" stage.');
          } else if (allocAmount > askAmount){
            futureGiftMap.get(fgId).addError('The sum of the Future Ask Allocations cannot exceed the Future Ask Actual Amount. Please fix the Allocations before moving past the "Solicitation" stage.');
          }
        }
      }
    }
  }
}