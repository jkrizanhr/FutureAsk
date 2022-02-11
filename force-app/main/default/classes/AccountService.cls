public inherited sharing class AccountService {
    
  public static void createAccountStageHistoryRecord(List<Account> accts, Map<Id, Account> oldMap) {
    List<Account_Stage_History__c> stageHistoryToUpsert = new List<Account_Stage_History__c>();
    Set<Id> accountIds = new Set<Id>();

    for (Account acct : accts){
      if (oldMap != null) {
        Account oldAcct = oldMap.get(acct.Id);
        if (oldAcct != null && (oldAcct.Donor_Stage__c != acct.Donor_Stage__c)) {
          Account_Stage_History__c ash = new Account_Stage_History__c(
            Previous_Stage__c = oldAcct.Donor_Stage__c,
            New_Stage__c = acct.Donor_Stage__c,
            Start_Date__c = Date.today(),
            Account__c = acct.Id
          );
          stageHistoryToUpsert.add(ash);
          accountIds.add(acct.Id);          
        }
      } else {
        if (acct.Donor_Stage__c != null) {
          Account_Stage_History__c ash = new Account_Stage_History__c(
            New_Stage__c = acct.Donor_Stage__c,
            Start_Date__c = Date.today(),
            Account__c = acct.Id
          );
          stageHistoryToUpsert.add(ash);
        }
      }
    }

    if (!accountIds.isEmpty()){
      for (Account_Stage_History__c ash : [SELECT Id, End_Date__c FROM Account_Stage_History__c WHERE Account__c IN :accountIds AND End_Date__c = null]){
        ash.End_Date__c = Date.today();
        stageHistoryToUpsert.add(ash);
      }
    }

    if (!stageHistoryToUpsert.isEmpty()){
      upsert stageHistoryToUpsert id;
    }
  }

  public static void createPrimaryPartnershipManager(List<Account> accts) {
    Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
    List<Account_Team__c> acctTeamMembersToInsert = new List<Account_Team__c>();

    for (Account acct : accts) {
      if (acct.RecordTypeId == partnerRecordTypeId){
        Account_Team__c at = new Account_Team__c(
          Account__c = acct.Id,
          Role__c = 'Primary Partnership Manager',
          User__c = acct.OwnerId,
          Status__c = 'Active',
          Start_Date__c = Date.today()
        );
        acctTeamMembersToInsert.add(at);
      }
    }

    if (!acctTeamMembersToInsert.isEmpty()){
      insert acctTeamMembersToInsert;
    }
  }

  public static void notifyRMofInvestorLevelChange(List<Account> accts, Map<Id, Account> oldMap){
    List<Account> acctsWithDonorLevelChange = new List<Account>();
    // Check to see if any accounts that were updated had their donor level changed.
    for (Account acct : accts){
      Account old = oldMap != null && !oldMap.isEmpty() ? oldMap.get(acct.Id) : null;
      if (old != null && acct.Donor_Giving_Level__c != old.Donor_Giving_Level__c && acct.Donor_Giving_Level__c != null){
        acctsWithDonorLevelChange.add(acct);
      }
    }

    // If accounts had their donor level change, send a notificiation to the correct person.
    if (!acctsWithDonorLevelChange.isEmpty()){
      // Get Mass and Mid-Level Donor Relations Coordinator's User Ids from a Custom Setting
      Relations_Coordinator_Defaults__c rcd = Relations_Coordinator_Defaults__c.getOrgDefaults();

      // Create a Map of Level Name to Level Id to determine how the Account changed
      Map<String, Id> levelMap = new Map<String, Id>();
      for (npsp__Level__c lvl : [SELECT Id, Name FROM npsp__Level__c WHERE Name LIKE '%Investor%']){
        levelMap.put(lvl.Name, lvl.Id);
      }

      // List of Notifications to Insert
      List<Notification__c> notificationsToInsert = new List<Notification__c>();
      
      for (Account acct : acctsWithDonorLevelChange){
        Account old = oldMap != null && !oldMap.isEmpty() ? oldMap.get(acct.Id) : null;
        if (old != null && acct.Donor_Giving_Level__c != old.Donor_Giving_Level__c){
          Notification__c n = new Notification__c();
          n.Record_Id__c = acct.Id;
          n.CRM__c = true;
          n.Status__c = 'Pending';
          n.Message__c = 'Your account, ' + acct.Name + ', has changed levels.';
          // Mass to Mid-Level: Notify RM. If RM is blank, send to Mass Donor Relations Coordinator.
          if (old.Donor_Giving_Level__c == levelMap.get('Mass Investor') && acct.Donor_Giving_Level__c == levelMap.get('Mid-Level Investor')){
            n.User__c = acct.Donor_Relationship_Manager__c != null ? acct.Donor_Relationship_Manager__c : rcd.Mass_Donor_Relations_Coordinator__c;
            n.Label__c = 'Level Change: Mass to Mid-Level Investor';
          } 
          // Mid-Level to Major: Notify RM. If RM is blank, send to Mid-Level Donor Relations Coordinator.
          else if (old.Donor_Giving_Level__c == levelMap.get('Mid-Level Investor') && acct.Donor_Giving_Level__c == levelMap.get('Major Investor')) {
            n.User__c = acct.Donor_Relationship_Manager__c != null ? acct.Donor_Relationship_Manager__c : rcd.Mid_Level_Donor_Relations_Coordinator__c;
            n.Label__c = 'Level Change: Mid-Level to Major Investor';
          } 
          // Major to Mid-Level or Mass: Notify RM. If RM is blank, send to Mid-Level Donor Relations Coordinator.
          else if (old.Donor_Giving_Level__c == levelMap.get('Major Investor') && acct.Donor_Giving_Level__c != levelMap.get('Major Investor')) {
            n.User__c = acct.Donor_Relationship_Manager__c != null ? acct.Donor_Relationship_Manager__c : rcd.Mid_Level_Donor_Relations_Coordinator__c;
            n.Label__c = 'Level Change: Major to Mid-Level or Mass Investor';
          } 
          // Mid-Level to Mass: Notify RM. If RM is blank, send to Mid-Level Donor Relations Coordinator.
          else if (old.Donor_Giving_Level__c == levelMap.get('Mid-Level Investor') && acct.Donor_Giving_Level__c == levelMap.get('Mass Investor')) {
            n.User__c = acct.Donor_Relationship_Manager__c != null ? acct.Donor_Relationship_Manager__c : rcd.Mid_Level_Donor_Relations_Coordinator__c;
            n.Label__c = 'Level Change: Mid-Level to Mass Investor'; 
          }
          // Else: Notify RM.
          else {
            n.User__c = acct.Donor_Relationship_Manager__c != null ? acct.Donor_Relationship_Manager__c : null;
            n.Label__c = 'Donor Changed Levels'; 
          }
          if (n.User__c != null){
            notificationsToInsert.add(n);
          }
        }
      }
      if (!notificationsToInsert.isEmpty()){
        insert notificationsToInsert;
      }
    }
  }
}