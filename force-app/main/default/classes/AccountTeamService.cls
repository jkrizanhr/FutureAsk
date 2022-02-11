public inherited sharing class AccountTeamService {
  
  // CREATE
  public static void assignAccountTeamRoles (List<Account_Team__c> atList){
    Set<String> roles = new Set<String>{'Primary Partnership Manager', 'Donor Relationship Manager', 'Grants Manager'};
    Map<String, String> roleToKeyMap = new Map<String, String>{
      'Primary Partnership Manager' => 'PPM', 
      'Donor Relationship Manager' => 'DRM', 
      'Grants Manager' => 'GM'
    };
    Map<String, String> roleToFieldMap = new Map<String, String>{
      'Primary Partnership Manager' => 'Primary_Partnership_Manager__c', 
      'Donor Relationship Manager' => 'Donor_Relationship_Manager__c', 
      'Grants Manager' => 'Grants_Manager__c'
    };
    Map<String, List<Account_Team__c>> roleMap = new Map<String, List<Account_Team__c>>();
    Map<Id, sObject> acctsToUpdate = new Map<Id, sObject>();
    Set<Id> acctIds = new Set<Id>();

    // Make a Map of Role to new Account Team List
    for (String role : roles){
      roleMap.put(role, new List<Account_Team__c>());
    } 

    // Make a List of Account Team Members by Role Type
    for (Account_Team__c at : atList) {
      if (roles.contains(at.Role__c) && at.Status__c == 'Active'){
        acctIds.add(at.Account__c);
        List<Account_Team__c> tempList = roleMap.get(at.Role__c);
        tempList.add(at);
        roleMap.put(at.Role__c, tempList);
      }
    }

    // Query out Account Records
    if (!acctIds.isEmpty()){
      // Query Account Records for Current Manager Information
      Map<Id, Account> acctMap = new Map<Id, Account>([
        SELECT Id, Primary_Partnership_Manager__c, Donor_Relationship_Manager__c, Grants_Manager__c 
        FROM Account 
        WHERE Id IN :acctIds
      ]);  

      // Get Active Account Team Members
      Map<String, List<Account_Team__c>> acctTeamMap = new Map<String, List<Account_Team__c>>();
      for (Account_Team__c at : [
        SELECT Id, Role__c, Status__c, Start_Date__c, End_Date__c, User__c, Account__c 
        FROM Account_Team__c 
        WHERE Account__c IN :acctIds 
          AND Status__c = 'Active' 
          AND Start_Date__c <= :Date.today() 
          AND (End_Date__c >= :Date.today() OR End_Date__c = null)
      ]){
        String key = roleToKeyMap.get(at.Role__c);
        List<Account_Team__c> temp = !acctTeamMap.isEmpty() && acctTeamMap.get(at.Account__c + key) != null
          ? acctTeamMap.get(at.Account__c + key)
          : new List<Account_Team__c>();
        temp.add(at);
        acctTeamMap.put(at.Account__c + key, temp);
      }
      
      // Loop through each list, so each role gets covered
      for (String role : roleMap.keySet()){
        List<Account_Team__c> atmList = roleMap.get(role);
        if (!atmList.isEmpty()){
          for (Account_Team__c atm : atmList){
            // Get Account From Accts to Update or Pull from the List of Accounts queried if AcctsToUpdate is empty
            String fieldName = roleToFieldMap.get(atm.Role__c);
            String key = roleToKeyMap.get(atm.Role__c);
            
            // Cast Account to a sObject to use the .get(FieldName) method to make this reusable
            sObject sObjAcct = !acctsToUpdate.isEmpty() && acctsToUpdate.get(atm.Account__c) != null 
              ? acctsToUpdate.get(atm.Account__c) 
              : acctMap.get(atm.Account__c);
            Id acctId = (Id)sObjAcct.get('Id');

            // If the Field is Blank OR the AcctTeamMap is Empty OR The AcctTeamMap is not empty but the specific Id + Key set doesn't match then update the lookup field.
            if (sObjAcct.get(fieldName) == null || acctTeamMap.isEmpty() || (!acctTeamMap.isEmpty() && (acctTeamMap.get(acctId + key) == null || acctTeamMap.get(acctId + key).isEmpty()))){
              sObjAcct.put(fieldName, atm.User__c);
              acctsToUpdate.put(String.valueOf(acctId), sObjAcct);
            } 
            // If the Field is Equal to the Assigned User through an Error that they're already the Manager for the account.
            else if (sObjAcct.get(fieldName) == atm.User__c){
              atm.Role__c.addError('This user is already the ' + role + ' for this Account.');
            } 
            // If the lookup is already set, through an error that someone is already fulfilling the role and to remove the other user first.
            else if(sObjAcct.get(fieldName) != null){
              atm.Role__c.addError('There is already a ' + role + ' set. Please change the Role or remove the other ' + role + '.');
            } 
          }
        }
      }
      
      if (!acctsToUpdate.isEmpty()){
        update acctsToUpdate.values();
      }
    }
  }

  // UPDATE
  public static void updateAccountTeamRoles (Map<Id, Account_Team__c> newMap, Map<Id, Account_Team__c> oldMap) {
    Set<String> roles = new Set<String>{
      'Primary Partnership Manager', 'Donor Relationship Manager', 'Grants Manager'
    };
    Map<String, String> roleToKeyMap = new Map<String, String>{
      'Primary Partnership Manager' => 'PPM', 
      'Donor Relationship Manager' => 'DRM', 
      'Grants Manager' => 'GM'
    };
    Map<String, String> roleToFieldMap = new Map<String, String>{
      'Primary Partnership Manager' => 'Primary_Partnership_Manager__c', 
      'Donor Relationship Manager' => 'Donor_Relationship_Manager__c', 
      'Grants Manager' => 'Grants_Manager__c'
    };
    
    if (oldMap != null){  
      Set<Id> acctIds = new Set<Id>();
      Map<Id, sObject> acctsToUpdate = new Map<Id, sObject>();
      Map<Id, Account_Team__c> acctTeamMap = new Map<Id, Account_Team__c>();
      Map<Id, String> clearFieldMap = new Map<Id, String>();

      for (Id key : newMap.keyset()){
        Account_Team__c at = newMap.get(key);
        Account_Team__c old_at = oldMap.get(key);

        // If their role changed and was one of the manager role at any point verify lookups.
        if ((roles.contains(at.Role__c) || roles.contains(old_at.Role__c))) {
          acctIds.add(at.Account__c);
          acctTeamMap.put(at.Id, at);
          
          // Special Case: If Role Changed from one Manager Role to Another Manager Role blank out the old role field
          if (at.Role__c != old_at.Role__c && roles.contains(at.Role__c) && roles.contains(old_at.Role__c)){
            clearFieldMap.put(at.Account__c, roleToKeyMap.get(old_at.Role__c));
          }
        }
      }

      // Query out Accounts that are effected by the change
      Map<Id, Account> acctMap = new Map<Id, Account>([
        SELECT Id, Primary_Partnership_Manager__c, Donor_Relationship_Manager__c, Grants_Manager__c 
        FROM Account 
        WHERE Id IN :acctIds
      ]);

      // For Each Account Team Member, check if their role can be set/changed. 
      for (Id atmId : acctTeamMap.keyset()){
        Account_Team__c atm = acctTeamMap.get(atmId);
        sObject sObjAcct = !acctsToUpdate.isEmpty() && acctsToUpdate.get(atm.Account__c) != null 
        ? acctsToUpdate.get(atm.Account__c) 
        : acctMap.get(atm.Account__c);
        
        // Field Name and Key based on Role
        Id acctId = (Id)sObjAcct.get('Id');
        String fieldName = roleToFieldMap.get(atm.Role__c);
        String key = roleToKeyMap.get(atm.Role__c);

        //If the Role's lookup field is not equal to the user check the field
        if (roles.contains(atm.Role__c) && atm.Status__c == 'Active' && sObjAcct.get(fieldName) != atm.User__c ){
          // If Not Blank: Throw an Error
          if (sObjAcct.get(fieldName) != null){
            atm.Role__c.addError(
              'There is already a ' + atm.Role__c + '. Please change the Role__c or remove the other ' + atm.Role__c + '.'
              );
            } 
            // If Blank: Set the Field and Check if another lookup field needs to be removed.
            else { 
            sObjAcct.put(fieldName, atm.User__c);
            
            for (String role : roleToFieldMap.keySet()){
              String roleField = roleToFieldMap.get(role);
              String roleKey = roleToKeyMap.get(role);
              if (fieldName != roleField && !clearFieldMap.isEmpty() && clearFieldMap.get(acctId) == roleKey){
                sObjAcct.put(roleField, null);
              }
            }
            
            acctsToUpdate.put(acctId, sObjAcct);
          }
        } 
        
        //If the role is not in the list of roles or the status is inactive set to null
        else if (!roles.contains(atm.Role__c) || 
        (atm.Status__c != 'Active' && sObjAcct.get(fieldName) == atm.User__c)
        ){
          for (String role : roleToFieldMap.keySet()){
            String roleField = roleToFieldMap.get(role);
            if ((atm.Role__c != role || atm.Status__c != 'Active') && sObjAcct.get(roleField) == atm.User__c){
              sObjAcct.put(roleField, null);
            }
          }
          acctsToUpdate.put(sObjAcct.Id, sObjAcct);
        }
      }

      if (!acctsToUpdate.isEmpty()){
        update acctsToUpdate.values();
      } 
    }
  }

  // DELETE
  public static void removeAccountTeamRoles (List<Account_Team__c> atList) {
    Set<Id> acctIds = new Set<Id>();
    Map<Id, Id> ppmMap = new Map<Id, Id>();
    Map<Id, Id> rmMap = new Map<Id, Id>();
    Map<Id, Id> gmMap = new Map<Id, Id>();
    List<Account> acctsToUpdate = new List<Account>();

    for (Account_Team__c at : atList){
      if (at.Role__c == 'Primary Partnership Manager' && at.Status__c == 'Active') {
        acctIds.add(at.Account__c);
        ppmMap.put(at.Account__c, at.User__c);
      }
      if (at.Role__c == 'Donor Relationship Manager' && at.Status__c == 'Active') {
        acctIds.add(at.Account__c);
        rmMap.put(at.Account__c, at.User__c);
      }
      if (at.Role__c == 'Grants Manager' && at.Status__c == 'Active') {
        acctIds.add(at.Account__c);
        gmMap.put(at.Account__c, at.User__c);
      }
    }

    for (Account acct : [
      SELECT Id, Primary_Partnership_Manager__c, Donor_Relationship_Manager__c, Grants_Manager__c
      FROM Account 
      WHERE Id IN :acctIds
    ]){
      if (acct.Primary_Partnership_Manager__c == ppmMap.get(acct.Id)){
        acct.Primary_Partnership_Manager__c = null;
      }
      if (acct.Donor_Relationship_Manager__c == rmMap.get(acct.Id)){
        acct.Donor_Relationship_Manager__c = null;
      }
      if (acct.Grants_Manager__c == gmMap.get(acct.Id)){
        acct.Grants_Manager__c = null;
      }
      acctsToUpdate.add(acct);
    }

    if (!acctsToUpdate.isEmpty()){
      update acctsToUpdate;
    } 
  }
}