global class BiblicaJitProvisioningHandler implements Auth.RegistrationHandler{
  private class JitException extends Exception {}  
  
  global boolean canCreateUser(Auth.UserData data) {
    //If data contains, first, last, and email, then create a user
    if(data != null && data.email != null && data.lastName != null && data.firstName != null) {
      return true;
    } else {
      String errorMessage = 'Error creating community user. Missing fields: ';
      errorMessage = data.email == null ? errorMessage + 'Email ' : errorMessage;
      errorMessage = data.firstName == null ? errorMessage + 'FirstName ' : errorMessage;
      errorMessage = data.lastName == null ? errorMessage + 'LastName ' : errorMessage;
      throw new JitException(errorMessage);
    }
  }

  global User createUser(Id portalId, Auth.UserData data){
    if(!canCreateUser(data)) {
      //Returning null or throwing an exception fails the SSO flow
      return null;
    }
    
    //We have a community id, so create a user with community access
    if(data.attributeMap.containsKey('sfdc_networkid')) {      
      System.debug('Registering a new Community User: ' + data.email);

      // Create the Contact
      Contact contact = new Contact();
      contact.firstName = data.firstName;
      contact.lastName = data.lastName;
      contact.email = data.email;
      contact.npe01__HomeEmail__c = data.email;
      contact.npe01__Preferred_Email__c = 'Personal';
      contact.leadSource = 'Donor Portal';

      // Look for duplicate contact
      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.AllowSave = true; 
      Database.SaveResult sr = Database.insert(contact, dml); 
      
      // Find community user profile and create the user
      List<Profile> profiles = [SELECT Id FROM profile WHERE name='Donor Portal User' LIMIT 1];
      if (!profiles.isEmpty()){
        User user = findExistingUserOrCreateNewUser(data, profiles[0], contact);
        return user;
      } else {
        throw new JitException('The community user profile "Donor Portal User" could not be found.');
      }
    } 
    // Only create a community user
    else {
      return null;
    }
  }

  global void updateUser(Id userId, Id portalId, Auth.UserData data){
    User u = new User(id=userId);
    u.email = data.email;
    u.lastName = data.lastName;
    u.firstName = data.firstName;
    u.sso_portal_user__c = true;
    update(u);
  }

  // private Contact findExistingContact(Contact c){
  //   Id existingContactId = null;
  //   List<Datacloud.FindDuplicatesResult> results = Datacloud.FindDuplicates.findDuplicates(new List<Contact>{c});
  //   for (Datacloud.FindDuplicatesResult findDupeResult : results) {
  //     for (
  //       Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()
  //     ) {
  //       for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
  //         for (
  //           Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()
  //         ) {
  //           System.debug(matchRecord);
  //           System.debug(matchRecord.getRecord());
  //           existingContactId = matchRecord.getRecord().Id;
  //         }
  //       }
  //     }
  //   }

  //   List<Contact> contacts = new List<Contact>();
  //   if (existingContactId != null){
  //     contacts = [
  //       SELECT Id, FirstName, LastName, Email 
  //       FROM Contact 
  //       WHERE Id = :existingContactId
  //     ];
  //   } else {
  //     contacts = [
  //       SELECT Id, FirstName, LastName, Email 
  //       FROM Contact 
  //       WHERE LastName = :c.LastName AND FirstName = :c.FirstName AND Email = :c.Email
  //     ];
  //   }
  //   if (!contacts.isEmpty()){
  //     c.Id = contacts[0].Id;
  //   } 
  //   return c;
  // }

  private User findExistingUserOrCreateNewUser(Auth.UserData data, Profile p, Contact c){
    List<User> users = [
      SELECT Id, Username, Email, LastName, FirstName, Alias, LanguageLocaleKey, 
        LocaleSidKey, EmailEncodingKey, TimeZoneSidKey, ProfileId, ContactId, SSO_Portal_User__c 
      FROM User 
      WHERE Username = :data.email OR ContactId = :c.Id];
    if (!users.isEmpty()){
      return users[0];
    } else {
      return createNewUser(data, p, c);
    }
  }

  private User createNewUser(Auth.UserData data, Profile p, Contact c){  
    User u = new User();
    u.username = data.email;
    u.email = data.email;
    u.lastName = data.lastName;
    u.firstName = data.firstName;
    u.sso_portal_user__c = true;
    String alias = data.firstName.substring(0, 1) + data.lastName;
    //Alias must be 8 characters or less
    if(alias.length() > 8) {
      alias = alias.substring(0, 8);
    }
    u.alias = alias;
    u.languagelocalekey = UserInfo.getLocale();
    u.localesidkey = UserInfo.getLocale();
    u.emailEncodingKey = 'UTF-8';
    u.timeZoneSidKey = 'America/Los_Angeles';
    u.profileId = p != null ? p.Id : null;
    u.contactId = c != null ? c.Id : null;
    insert u;
    return u;
  }
}