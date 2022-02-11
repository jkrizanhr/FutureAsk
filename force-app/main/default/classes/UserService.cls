public inherited sharing class UserService {
  
  public static void setCommunityUserLookupOnContact(List<User> users, Map<Id, User> oldUsers){
    System.enqueueJob(new UpdateContactQueueable(users, oldUsers));
  }

  private class UpdateContactQueueable implements Queueable {
    private List<User> users;
    private Map<Id, User> oldUsers;
    
    public void execute(QueueableContext qc){
      setCommunityUserLookupOnContactHelper(users, oldUsers);
    }

    public UpdateContactQueueable(List<User> users, Map<Id, User> oldUsers){
      this.users = users;
      this.oldUsers = oldUsers;
    }
  }

  private static void setCommunityUserLookupOnContactHelper(List<User> users, Map<Id, User> oldUsers) {
    Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();
    for (User u : users){
      User oldUser = oldUsers != null && oldUsers.containsKey(u.Id) ? oldUsers.get(u.Id) : null;
      Id contactId = null;
      Id userId = u.Id;
      
      // IF: old user exists and the user is deactivated
      if (oldUser != null && u.IsPortalEnabled != oldUser.IsPortalEnabled){
        contactId = u.ContactId != null ? u.ContactId : u.Contact_Id__c;
        userId = u.IsPortalEnabled ? u.Id : null;
        contactsToUpdate.put(contactId, new Contact(Id = contactId, User__c = userId));
      } 
      // ELSE IF: old user exists and the contact id field has changed then update the contact
      else if (oldUser != null && (u.ContactId != oldUser.ContactId || u.Contact_Id__c != oldUser.Contact_Id__c)){
        // Update the contact to store the user id
        if (u.ContactId != null){
          contactsToUpdate.put(u.ContactId, new Contact(Id = u.ContactId, User__c = userId));
        }
        // Set the old contact user lookup to null
        if (oldUser.ContactId != null){
          contactsToUpdate.put(oldUser.ContactId, new Contact(Id = oldUser.ContactId, User__c = null));
        }
        // Check for valid SF Contact Id, update the contact user lookup to the user id
        if (u.Contact_Id__c != null && Utils.checkIdValidity(u.Contact_Id__c)){
          contactsToUpdate.put(u.Contact_Id__c, new Contact(Id = u.Contact_Id__c, User__c = userId));
        }
        // Check for valid SF Contact Id, set the old contact user lookup to null
        if (oldUser.Contact_Id__c != null && Utils.checkIdValidity(oldUser.Contact_Id__c)){
          contactsToUpdate.put(oldUser.Contact_Id__c, new Contact(Id = oldUser.Contact_Id__c, User__c = null));  
        }
      } 
      // ELSE IF: old user is null and the user contact id is not equal to null, update the contact
      else if (oldUser == null 
        && (u.ContactId != null || (u.Contact_Id__c != null && Utils.checkIdValidity(u.Contact_Id__c)))
      ){
        contactId = u.ContactId != null ? u.ContactId : u.Contact_Id__c;
        contactsToUpdate.put(contactId, new Contact(Id = contactId, User__c = userId));
      }
    }
    if (!contactsToUpdate.isEmpty()){
      update contactsToUpdate.values();
    }
  }
}