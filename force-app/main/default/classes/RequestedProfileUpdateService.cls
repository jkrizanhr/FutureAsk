public inherited sharing class RequestedProfileUpdateService {

  private static Contact buildContactUpdates(Requested_Profile_Update__c rpu){
    Contact con = new Contact();
    con.Id = rpu.Contact__c;
    con.Salutation = String.isNotBlank(rpu.Prefix__c) 
      ? rpu.Prefix__c : null;
    con.FirstName = String.isNotBlank(rpu.First_Name__c) 
      ? rpu.First_Name__c : null;
    con.LastName = String.isNotBlank(rpu.Last_Name__c) 
      ? rpu.Last_Name__c : null;
    con.Suffix = String.isNotBlank(rpu.Suffix__c) 
      ? rpu.Suffix__c : null;
    con.npe01__PreferredPhone__c = String.isNotBlank(rpu.Preferred_Phone__c) 
      ? rpu.Preferred_Phone__c : null;
    con.HomePhone = String.isNotBlank(rpu.Home_Phone__c) 
      ? rpu.Home_Phone__c : null;
    con.npe01__WorkPhone__c = String.isNotBlank(rpu.Work_Phone__c) 
      ? rpu.Work_Phone__c : null;
    con.MobilePhone = String.isNotBlank(rpu.Mobile_Phone__c) 
      ? rpu.Mobile_Phone__c : null;
    con.npe01__Preferred_Email__c = String.isNotBlank(rpu.Preferred_Email__c) 
      ? rpu.Preferred_Email__c : null;
    con.npe01__HomeEmail__c = String.isNotBlank(rpu.Personal_Email__c) 
      ? rpu.Personal_Email__c : null;
    con.npe01__WorkEmail__c = String.isNotBlank(rpu.Work_Email__c) 
      ? rpu.Work_Email__c : null;
    con.npe01__AlternateEmail__c = String.isNotBlank(rpu.Alternate_Email__c) 
      ? rpu.Alternate_Email__c : null;
    con.MailingCountry = String.isNotBlank(rpu.Country__c) 
      ? rpu.Country__c : null;
    con.MailingStreet = String.isNotBlank(rpu.Street__c) 
      ? rpu.Street__c : null;
    con.MailingCity = String.isNotBlank(rpu.City__c) 
      ? rpu.City__c : null;
    con.MailingState = String.isNotBlank(rpu.State__c) 
      ? rpu.State__c : null;
    con.MailingPostalCode = String.isNotBlank(rpu.Postal_Code__c) 
      ? rpu.Postal_Code__c : null;
    
    return con;
  }

  public static void approveRequestedProfileUpdate(
    List<Requested_Profile_Update__c> updates, Map<Id, Requested_Profile_Update__c> oldMap
  ){
    List<Contact> contactsToUpdate = new List<Contact>();
    for (Requested_Profile_Update__c rpu : updates){
      Requested_Profile_Update__c old = oldMap != null && oldMap.containsKey(rpu.Id)
        ? oldMap.get(rpu.Id)
        : null;
      if (old != null && rpu.Update_Status__c != old.Update_Status__c && rpu.Update_Status__c == 'Approved'){
        Contact c = buildContactUpdates(rpu);
        contactsToUpdate.add(c);
      } 
    }

    if (!contactsToUpdate.isEmpty()){
      update contactsToUpdate;
    }
  }

  public static void autoApproveBlankFields(
    Map<Id, Requested_Profile_Update__c> updates, Map<Id, Requested_Profile_Update__c> oldMap
  ){
    Map<String, String> contactFieldMap = buildFieldMap();
    Map<Id, Id> contactToProfileMap = new Map<Id, Id>();
    
    for (Requested_Profile_Update__c rpu : updates.values()){
      Requested_Profile_Update__c old = oldMap != null && oldMap.containsKey(rpu.Id)
        ? oldMap.get(rpu.Id)
        : null;
      if (old != null && rpu.Update_Status__c != old.Update_Status__c && rpu.Update_Status__c == 'Waiting for Approval'){
        contactToProfileMap.put(rpu.Contact__c, rpu.Id);
      } 
    }

    List<Contact> contactsToUpdate = new List<Contact>();
    List<Requested_Profile_Update__c> profilesToUpdate = new List<Requested_Profile_Update__c>();
    
    for (Contact c : [
      SELECT Id,Salutation,FirstName,LastName,Suffix,npe01__PreferredPhone__c,HomePhone,npe01__WorkPhone__c,MobilePhone,npe01__Preferred_Email__c,npe01__HomeEmail__c,npe01__WorkEmail__c,npe01__AlternateEmail__c,MailingCountry,MailingStreet,MailingCity,MailingState,MailingPostalCode
      FROM Contact WHERE Id IN :contactToProfileMap.keySet()]
    ){
      Boolean approveUpdate = true;
      Boolean contactUpdated = false;
      Id rpuId = contactToProfileMap.get(c.Id);
      Requested_Profile_Update__c rpu = updates.get(rpuId);
      
      for (String contactField : contactFieldMap.keySet()){
        String rpuField = contactFieldMap.get(contactField);
        if (c.get(contactField) != null && c.get(contactField) != rpu.get(rpuField)){
          approveUpdate = false;
        } 
        else if (c.get(contactField) == null && rpu.isSet(rpuField)){
          c.put(contactField, rpu.get(rpuField));
          contactUpdated = true;
        } 
      }
      if (contactUpdated){
        contactsToUpdate.add(c);
      }
      if (approveUpdate){
        Requested_Profile_Update__c temp = new Requested_Profile_Update__c();
        temp.Id = rpu.Id;
        temp.Update_Status__c = 'Approved';
        profilesToUpdate.add(temp);
      }
    }

    if (!contactsToUpdate.isEmpty()){
      update contactsToUpdate;
    }
    if (!profilesToUpdate.isEmpty()){
      update profilesToUpdate;
    }
  }

  private static Map<String, String> buildFieldMap(){
    Map<String, String> contactFieldMap = new Map<String, String>();
    contactFieldMap.put('Salutation', 'Prefix__c');
    contactFieldMap.put('FirstName', 'First_Name__c');
    contactFieldMap.put('LastName', 'Last_Name__c');
    contactFieldMap.put('Suffix', 'Suffix__c');
    contactFieldMap.put('npe01__PreferredPhone__c', 'Preferred_Phone__c');
    contactFieldMap.put('HomePhone', 'Home_Phone__c');
    contactFieldMap.put('npe01__WorkPhone__c', 'Work_Phone__c');
    contactFieldMap.put('MobilePhone', 'Mobile_Phone__c');
    contactFieldMap.put('npe01__Preferred_Email__c', 'Preferred_Email__c');
    contactFieldMap.put('npe01__HomeEmail__c', 'Personal_Email__c');
    contactFieldMap.put('npe01__WorkEmail__c', 'Work_Email__c');
    contactFieldMap.put('npe01__AlternateEmail__c', 'Alternate_Email__c');
    contactFieldMap.put('MailingCountry', 'Country__c');
    contactFieldMap.put('MailingStreet', 'Street__c');
    contactFieldMap.put('MailingCity', 'City__c');
    contactFieldMap.put('MailingState', 'State__c');
    contactFieldMap.put('MailingPostalCode', 'Postal_Code__c');
    return contactFieldMap;
  }

  public static void createNotificationWhenProfileChanges(
    Map<Id, Requested_Profile_Update__c> updates, Map<Id, Requested_Profile_Update__c> oldMap
  ){
    List<Notification__c> notifications = new List<Notification__c>();
    List<Contact> contacts = new List<Contact>();

    for (Requested_Profile_Update__c rpu : updates.values()){
      Requested_Profile_Update__c old = oldMap != null && oldMap.containsKey(rpu.Id)
        ? oldMap.get(rpu.Id)
        : null;
      if (old != null && rpu.Update_Status__c != old.Update_Status__c && rpu.Update_Status__c == 'Waiting for Approval' && rpu.Last_Profile_Update_Notification_Sent__c != Date.today()){
        Notification__c n = new Notification__c();
        n.Contact__c = rpu.Contact__c;
        n.Status__c = 'Pending';
        n.Template_Id__c = '00X3i000000pk1nEAA';
        n.Org_Wide_Address__c = '0D23i000000fyb8CAA';
        n.Is_Donation_Page_Receipt__c = false;
        n.Email__c = true;
        n.Label__c = 'Your profile has been updated!';
        n.Message__c = 'Your donor profile has been updated. The following fields have been changed: ' + rpu.Fields_Changed__c;
        n.Message2__c = 'Your donor profile has been updated. The following fields have been changed: ' + rpu.Fields_Changed__c;
        notifications.add(n);
        Contact c = new Contact();
        c.Id = rpu.Contact__c;
        c.Profile_Update_Notification_Sent__c = Date.today();
        contacts.add(c);
      } 
    }
    if (!notifications.isEmpty()) {
      insert notifications;
    }
    if (!contacts.isEmpty()){
      update contacts;
    }
  }
}