public with sharing class AccountRelationshipService {
  public static void handleInsert(List<Account_Relationship__c> relationships) {
    List<Account_Relationship__c> relationshipsToCreate = new List<Account_Relationship__c>();
    List<Account_Relationship__c> reciprocalsToUpdate = new List<Account_Relationship__c>();

    for (Account_Relationship__c rel : relationships) {
      if (rel.Reciprocal_Relationship__c == null) {
        relationshipsToCreate.add(new Account_Relationship__c(
                                    Account__c = rel.Related_Account__c,
                                    Related_Account__c = rel.Account__c,
                                    Status__c = rel.Status__c,
                                    Type__c = rel.Type__c,
                                    Reciprocal_Relationship__c = rel.Id,
                                    Description__c = rel.Description__c,
                                    Start_Date__c = rel.Start_Date__c,
                                    End_Date__c = rel.End_Date__c,
                                    System_Created__c = true
                                  ));
      }

      if (rel.Reciprocal_Relationship__c != null) {
        reciprocalsToUpdate.add(new Account_Relationship__c(
                                  Id = rel.Reciprocal_Relationship__c,
                                  Reciprocal_Relationship__c = rel.Id
                                ));
      }
    }

    if (relationshipsToCreate.size() > 0) {
      insert relationshipsToCreate;
    }

    if (reciprocalsToUpdate.size() > 0) {
      update reciprocalsToUpdate;
    }
  }

  public static void handleUpdate(List<Account_Relationship__c> relationships, Map<Id, Account_Relationship__c> oldRelationshipsMap) {
    List<Account_Relationship__c> relationshipsToUpdate = new List<Account_Relationship__c>();
    List<Account_Relationship__c> relationshipsToDelete = new List<Account_Relationship__c>();

    for (Account_Relationship__c rel : relationships) {
      Account_Relationship__c oldRel = oldRelationshipsMap.get(rel.Id);

      if (rel.Reciprocal_Relationship__c == oldRel.Reciprocal_Relationship__c && rel.Related_Account__c != null) {
        if ((rel.Status__c != oldRel.Status__c ||
             rel.Type__c != oldRel.Type__c ||
             rel.Description__c != oldRel.Description__c ||
             rel.Start_Date__c != oldRel.Start_Date__c ||
             rel.End_Date__c != oldRel.End_Date__c
            ) && rel.Reciprocal_Relationship__c != null) {
          Account_Relationship__c updatedRel = new Account_Relationship__c(Id = rel.Reciprocal_Relationship__c);
          if (oldRel.Related_Account__c != rel.Related_Account__c) {
            updatedRel.Account__c = rel.Related_Account__c;
          }
          updatedRel.Status__c = rel.Status__c;
          updatedRel.Description__c = rel.Description__c;
          updatedRel.Type__c = rel.Type__c;
          updatedRel.Start_Date__c = rel.Start_Date__c;
          updatedRel.End_Date__c = rel.End_Date__c;
          relationshipsToUpdate.add(updatedRel);
        }
      }

      if (rel.Related_Account__c == null) {
        if (rel.Reciprocal_Relationship__c != null) {
          relationshipsToDelete.add(new Account_Relationship__c(Id = rel.Reciprocal_Relationship__c));
        } else if (rel.Related_Account__c == null) {
          relationshipsToDelete.add(new Account_Relationship__c(Id = rel.Id));
        }
      }
    }

    if (relationshipsToUpdate.size() > 0) {
      update relationshipsToUpdate;
    }

    if (relationshipsToDelete.size() > 0) {
      delete relationshipsToDelete;
    }
  }

  public static void handleDelete(List<Account_Relationship__c> relationships) {
    List<Account_Relationship__c> reciprocalsToDelete = new List<Account_Relationship__c>();

    for (Account_Relationship__c rel : relationships) {
      if (rel.Reciprocal_Relationship__c != null) {
        if (rel.Related_Account__c == null) {
          reciprocalsToDelete.add(new Account_Relationship__c(Id = rel.Id));
        } else {
          reciprocalsToDelete.add(new Account_Relationship__c(Id = rel.Reciprocal_Relationship__c));
        }
      }
    }

    if (reciprocalsToDelete.size() > 0) {
      delete reciprocalsToDelete;
    }
  }
}