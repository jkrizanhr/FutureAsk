public class DonationPageProcessor implements Queueable {
  private List<Donation_Form_Submission__c> formSubmissions;
  private Map<Id, Campaign> relatedCampaignMap;
  private Map<Id, Contact> contactMap;
  private Map<Id, Lead> leadMap;
  private Map<Id, Account> accountMap;
  private Map<Id, npe03__Recurring_Donation__c> recDonMap;
  private Map<Id, Opportunity> opportunityMap;
  private Map<Id, List<Donation_Option_Selection__c>> donOptSelectionMap;
  private Map<Id, npe03__Recurring_Donation__c> donOptRecDonMap;
  private Map<String, Campaign> campaignInputMap;

  public DonationPageProcessor(List<Donation_Form_Submission__c> submissions) {
    this.formSubmissions = submissions;
  }

  public void execute(QueueableContext qc) {
    this.run();
  }

  private Map<Id, Lead> matchLeads(
    List<Donation_Form_Submission__c> formSubmissions
  ) {
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.AllowSave = true;
    Map<Id, Lead> matchedLeadMap = new Map<Id, Lead>();
    List<String> emails = new List<String>();
    List<String> lastNames = new List<String>();
    List<String> firstNames = new List<String>();
    for (Donation_Form_Submission__c dfs : formSubmissions) {
      if (String.isNotBlank(dfs.Email__c)) {
        emails.add(dfs.Email__c);
      }
      if (String.isNotBlank(dfs.Last_Name__c)) {
        lastNames.add(dfs.Last_Name__c);
      }
      if (String.isNotBlank(dfs.First_Name__c)) {
        firstNames.add(dfs.First_Name__c);
      }
    }

    List<Lead> leads = [
      SELECT Id, FirstName, LastName, Email
      FROM Lead
      WHERE
        FirstName IN :firstNames
        AND LastName IN :lastNames
        AND Email IN :emails
    ];

    for (Donation_Form_Submission__c dfs : formSubmissions) {
      for (Lead dfsLead : leads) {
        if (
          String.isNotBlank(dfsLead.FirstName) &&
          dfsLead.FirstName.equalsIgnoreCase(dfs.First_Name__c) &&
          String.isNotBlank(dfsLead.LastName) &&
          dfsLead.LastName.equalsIgnoreCase(dfs.Last_Name__c) &&
          String.isNotBlank(dfsLead.Email) &&
          dfsLead.Email.equalsIgnoreCase(dfs.Email__c)
        ) {
          matchedLeadMap.put(dfs.Id, dfsLead);
          break;
        }
      }
    }

    return matchedLeadMap;
  }

  private Map<Id, Lead> matchLeadsWithDuplicateRules(
    List<Donation_Form_Submission__c> formSubmissions
  ) {
    Map<Id, Lead> matchedLeadMap = new Map<Id, Lead>();
    Map<Id, Id> dfsIdToExistingLeadIdMap = new Map<Id, Id>();
    for (Donation_Form_Submission__c dfs : formSubmissions) {
      Lead l = new Lead();
      l.FirstName = dfs.First_Name__c;
      l.LastName = dfs.Last_Name__c;
      l.Email = dfs.Email__c;
      l.Phone = dfs.Phone__c;
      Lead existingLead = findExistingLead(l);
      if (existingLead != null) {
        matchedLeadMap.put(dfs.Id, existingLead);
      }
    }
    System.debug(matchedLeadMap);
    return matchedLeadMap;
  }

  private Lead findExistingLead(Lead l) {
    Lead matchLead;
    List<Datacloud.FindDuplicatesResult> results = Datacloud.FindDuplicates.findDuplicates(
      new List<Lead>{l}
    );
    for (Datacloud.FindDuplicatesResult findDupeResult : results) {
      for (
        Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()
      ) {
        for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
          for (
            Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()
          ) {
            System.debug(matchRecord);
            System.debug(matchRecord.getRecord());
            matchLead = (Lead) matchRecord.getRecord();
          }
        }
      }
    }
    return matchLead;
  }

  private Map<Id, Contact> matchContacts(
    List<Donation_Form_Submission__c> formSubmissions
  ) {
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.AllowSave = true;
    Map<Id, Contact> matchedContactMap = new Map<Id, Contact>();
    Set<Id> setConIds = new Set<Id>();
    List<String> emails = new List<String>();
    List<String> lastNames = new List<String>();
    List<String> firstNames = new List<String>();
    for (Donation_Form_Submission__c dfs : formSubmissions) {
      if (dfs.Contact__c != null) {
        setConIds.add(dfs.Contact__c);
      } else {
        if (String.isNotBlank(dfs.Email__c)) {
          emails.add(dfs.Email__c);
        }
        if (String.isNotBlank(dfs.Last_Name__c)) {
          lastNames.add(dfs.Last_Name__c);
        }
        if (String.isNotBlank(dfs.First_Name__c)) {
          firstNames.add(dfs.First_Name__c);
        }
      }
    }

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
        Id IN :setConIds
        OR (FirstName IN :firstNames
        AND LastName IN :lastNames
        AND (Email IN :emails
        OR npe01__AlternateEmail__c IN :emails
        OR npe01__HomeEmail__c IN :emails
        OR npe01__WorkEmail__c IN :emails))
    ];

    Map<Id, Contact> leadToContact = new Map<Id, Contact>();
    List<Contact> contactsToInsert = new List<Contact>();
    List<Lead> leadsToConvert = new List<Lead>();
    for (Donation_Form_Submission__c dfs : formSubmissions) {
      Boolean foundMatch = false;
      for (Contact con : contactQuery) {
        if (
          con.Id == dfs.Contact__c ||
          (String.isNotBlank(con.FirstName) &&
          con.FirstName.equalsIgnoreCase(dfs.First_Name__c) &&
          String.isNotBlank(con.LastName) &&
          con.LastName.equalsIgnoreCase(dfs.Last_Name__c) &&
          ((String.isNotBlank(con.Email) &&
          con.Email.equalsIgnoreCase(dfs.Email__c)) ||
          (String.isNotBlank(con.npe01__WorkEmail__c) &&
          con.npe01__WorkEmail__c.equalsIgnoreCase(dfs.Email__c)) ||
          (String.isNotBlank(con.npe01__HomeEmail__c) &&
          con.npe01__HomeEmail__c.equalsIgnoreCase(dfs.Email__c)) ||
          (String.isNotBlank(con.npe01__AlternateEmail__c) &&
          con.npe01__AlternateEmail__c.equalsIgnoreCase(dfs.Email__c))))
        ) {
          if (this.leadMap.containsKey(dfs.Id)) {
            Lead l = this.leadMap.get(dfs.Id);
            leadToContact.put(l.Id, con);
            leadsToConvert.add(l);
          }
          matchedContactMap.put(dfs.Id, con);
          foundMatch = true;
          break;
        }
      }
      if (!foundMatch) {
        if (this.leadMap.containsKey(dfs.Id)) {
          leadsToConvert.add(this.leadMap.get(dfs.Id));
        } else {
          Contact c = new Contact();
          c.FirstName = dfs.First_Name__c;
          c.LastName = dfs.Last_Name__c;
          c.Suffix = dfs.Suffix__c;
          c.npe01__HomeEmail__c = dfs.Email__c;
          c.npe01__Preferred_Email__c = 'Personal';
          c.HomePhone = dfs.Phone__c;
          c.npe01__PreferredPhone__c = 'Home';
          c.MailingStreet = dfs.Street_Address__c;
          c.MailingCity = dfs.City__c;
          c.MailingState = dfs.State_Province__c;
          c.MailingPostalCode = dfs.Postal_Code__c;
          c.MailingCountry = dfs.Selected_Country__c;
          c.LeadSource = 'Donation Page';
          c.Region_Category__c = this.relatedCampaignMap.get(dfs.Id)?.Region_Category__c;
          contactsToInsert.add(c);
        }
      }
    }

    Set<Id> conIds = new Set<Id>();
    if (!leadsToConvert.isEmpty()) {
      List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
      for (Lead myLead : leadsToConvert) {
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(myLead.Id);
        lc.convertedStatus = 'Closed - Converted';
        //Database.ConvertLead(lc,true);
        lc.setDoNotCreateOpportunity(true);
        if (leadToContact.containsKey(myLead.Id)) {
          Contact c = leadToContact.get(myLead.Id);
          lc.setContactId(c.Id);
          lc.setAccountId(c.AccountId);
        }
        System.debug(lc);
        leadConverts.add(lc);
      }
      List<Database.LeadConvertResult> leadConvertResults = Database.convertLead(
        leadConverts
      );
      for (Database.LeadConvertResult lcr : leadConvertResults) {
        conIds.add(lcr.getContactId());
      }
    }

    if (!contactsToInsert.isEmpty()) {
      Database.insert(contactsToInsert, dml);
      for (Contact c : contactsToInsert) {
        conIds.add(c.Id);
      }
    }

    if (!contactsToInsert.isEmpty() || !leadsToConvert.isEmpty()) {
      List<Contact> newContactQuery = [
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
        WHERE Id IN :conIds
      ];

      for (Donation_Form_Submission__c dfs : formSubmissions) {
        if (matchedContactMap.get(dfs.Id) == null) {
          for (Contact con : newContactQuery) {
            if (
              String.isNotBlank(con.FirstName) &&
              con.FirstName.equalsIgnoreCase(dfs.First_Name__c) &&
              String.isNotBlank(con.LastName) &&
              con.LastName.equalsIgnoreCase(dfs.Last_Name__c) &&
              ((String.isNotBlank(con.Email) &&
              con.Email.equalsIgnoreCase(dfs.Email__c)) ||
              (String.isNotBlank(con.npe01__WorkEmail__c) &&
              con.npe01__WorkEmail__c.equalsIgnoreCase(dfs.Email__c)) ||
              (String.isNotBlank(con.npe01__HomeEmail__c) &&
              con.npe01__HomeEmail__c.equalsIgnoreCase(dfs.Email__c)) ||
              (String.isNotBlank(con.npe01__AlternateEmail__c) &&
              con.npe01__AlternateEmail__c.equalsIgnoreCase(dfs.Email__c)))
            ) {
              System.debug('New con');
              System.debug(con);
              matchedContactMap.put(dfs.Id, con);
              break;
            }
          }
        }
      }
    }

    return matchedContactMap;
  }

  private Id findExistingContact(Contact con) {
    System.debug('Looking for matching contacts');
    System.debug(con);
    Id existingContactId = null;
    List<Datacloud.FindDuplicatesResult> results = Datacloud.FindDuplicates.findDuplicates(
      new List<Contact>{con}
    );
    for (Datacloud.FindDuplicatesResult findDupeResult : results) {
      for (
        Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()
      ) {
        for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
          for (
            Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()
          ) {
            System.debug(matchRecord);
            System.debug(matchRecord.getRecord());
            existingContactId = matchRecord.getRecord().Id;
          }
        }
      }
    }
    return existingContactId;
  }

  private Map<Id, Contact> matchContactsWithDuplicateRules(
    List<Donation_Form_Submission__c> formSubmissions
  ) {
    Map<Id, Contact> matchedContactMap = new Map<Id, Contact>();
    Map<Id, Id> dfsIdToExistingContactIdMap = new Map<Id, Id>();
    Map<Id, Contact> conIds = new Map<Id, Contact>();
    Map<Id, Id> leadToContact = new Map<Id, Id>();
    List<Lead> leadsToConvert = new List<Lead>();
    List<Contact> contactsToInsert = new List<Contact>();
    List<Contact> contactsToUpdate = new List<Contact>();
    for (Donation_Form_Submission__c dfs : formSubmissions) {
      if (dfs.Contact__c != null) {
        conIds.put(dfs.Contact__c, new Contact(Id = dfs.Contact__c));
        dfsIdToExistingContactIdMap.put(dfs.Id, dfs.Contact__c);
      } else {
        Contact c = new Contact();
        c.FirstName = dfs.First_Name__c;
        c.LastName = dfs.Last_Name__c;
        c.Suffix = dfs.Suffix__c;
        c.npe01__HomeEmail__c = dfs.Email__c;
        c.npe01__Preferred_Email__c = 'Personal';
        c.HomePhone = dfs.Phone__c;
        c.npe01__PreferredPhone__c = 'Home';
        c.MailingStreet = dfs.Street_Address__c;
        c.MailingCity = dfs.City__c;
        c.MailingState = dfs.State_Province__c;
        c.MailingPostalCode = dfs.Postal_Code__c;
        c.MailingCountry = dfs.Selected_Country__c;
        c.LeadSource = 'Donation Page';
        c.Region_Category__c = this.relatedCampaignMap.get(dfs.Id)?.Region_Category__c;
        Id existingContactId = findExistingContact(c);
        if (existingContactId == null) {
          if (this.leadMap.containsKey(dfs.Id)) {
            leadsToConvert.add(this.leadMap.get(dfs.Id));
          } else {
            contactsToInsert.add(c);
          }
        } else {
          c.Id = existingContactId;
          conIds.put(existingContactId, c);
          dfsIdToExistingContactIdMap.put(dfs.Id, existingContactId);
          if (this.leadMap.containsKey(dfs.Id)) {
            Lead l = this.leadMap.get(dfs.Id);
            leadToContact.put(l.Id, existingContactId);
            leadsToConvert.add(l);
          }
        }
      }
    }

    Map<Id, Contact> contactsToConvertFromLeads = new Map<Id, Contact>(
      [SELECT Id, AccountId FROM Contact WHERE Id IN :leadToContact.values()]
    );

    if (!leadsToConvert.isEmpty()) {
      List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
      for (Lead myLead : leadsToConvert) {
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(myLead.Id);
        lc.convertedStatus = 'Closed - Converted';
        //Database.ConvertLead(lc,true);
        lc.setDoNotCreateOpportunity(true);
        if (leadToContact.containsKey(myLead.Id)) {
          Id conId = leadToContact.get(myLead.Id);
          lc.setContactId(conId);
          Contact temp = contactsToConvertFromLeads.get(conId);
          lc.setAccountId(temp.AccountId);
        }
        leadConverts.add(lc);
      }
      List<Database.LeadConvertResult> leadConvertResults = Database.convertLead(
        leadConverts
      );
      for (Database.LeadConvertResult lcr : leadConvertResults) {
        conIds.put(lcr.getContactId(), new Contact(Id = lcr.getContactId()));
      }
    }

    if (!contactsToInsert.isEmpty()) {
      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.AllowSave = true;
      Database.insert(contactsToInsert, dml);
      for (Contact c : contactsToInsert) {
        conIds.put(c.Id, c);
      }
    }

    if (!conIds.isEmpty()) {
      List<Contact> contactQuery = [
        SELECT
          Id,
          FirstName,
          LastName,
          Email,
          npe01__AlternateEmail__c,
          npe01__HomeEmail__c,
          npe01__Preferred_Email__c,
          npe01__WorkEmail__c,
          AccountId,
          Account.Language_Preference__c,
          Account.Receipt_Type__c,
          Suffix,
          HomePhone,
          npe01__PreferredPhone__c,
          MailingStreet,
          MailingCity,
          MailingState,
          MailingPostalCode,
          MailingCountry
        FROM Contact
        WHERE Id IN :conIds.keySet()
      ];

      for (Donation_Form_Submission__c dfs : formSubmissions) {
        for (Contact con : contactQuery) {
          if (dfsIdToExistingContactIdMap.get(dfs.Id) == con.Id) {
            if (contactNeedsUpdated(con, conIds.get(con.Id))) {
              con = doContactUpdates(con, conIds.get(con.Id));
              contactsToUpdate.add(con);
            }
            matchedContactMap.put(dfs.Id, con);
            break;
          } else if (
            String.isNotBlank(con.FirstName) &&
            con.FirstName.equalsIgnoreCase(dfs.First_Name__c) &&
            String.isNotBlank(con.LastName) &&
            con.LastName.equalsIgnoreCase(dfs.Last_Name__c) &&
            ((String.isNotBlank(con.Email) &&
            con.Email.equalsIgnoreCase(dfs.Email__c)) ||
            (String.isNotBlank(con.npe01__WorkEmail__c) &&
            con.npe01__WorkEmail__c.equalsIgnoreCase(dfs.Email__c)) ||
            (String.isNotBlank(con.npe01__HomeEmail__c) &&
            con.npe01__HomeEmail__c.equalsIgnoreCase(dfs.Email__c)) ||
            (String.isNotBlank(con.npe01__AlternateEmail__c) &&
            con.npe01__AlternateEmail__c.equalsIgnoreCase(dfs.Email__c)))
          ) {
            if (contactNeedsUpdated(con, conIds.get(con.Id))) {
              con = doContactUpdates(con, conIds.get(con.Id));
              contactsToUpdate.add(con);
            }
            matchedContactMap.put(dfs.Id, con);
            break;
          }
        }
      }
    }
    if (!contactsToUpdate.isEmpty()) {
      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.AllowSave = true;
      Database.update(contactsToUpdate, dml);
    }
    return matchedContactMap;
  }

  private Boolean contactNeedsUpdated(Contact oldCon, Contact newCon) {
    if (
      (String.isNotBlank(newCon.Email) && String.isBlank(oldCon.Email)) ||
      (String.isNotBlank(newCon.npe01__AlternateEmail__c) &&
      String.isBlank(oldCon.npe01__AlternateEmail__c)) ||
      (String.isNotBlank(newCon.npe01__HomeEmail__c) &&
      String.isBlank(oldCon.npe01__HomeEmail__c)) ||
      (String.isNotBlank(newCon.npe01__Preferred_Email__c) &&
      String.isBlank(oldCon.npe01__Preferred_Email__c)) ||
      (String.isNotBlank(newCon.npe01__WorkEmail__c) &&
      String.isBlank(oldCon.npe01__WorkEmail__c)) ||
      (String.isNotBlank(newCon.HomePhone) &&
      String.isBlank(oldCon.HomePhone)) ||
      (String.isNotBlank(newCon.npe01__PreferredPhone__c) &&
      String.isBlank(oldCon.npe01__PreferredPhone__c)) ||
      (String.isNotBlank(newCon.MailingStreet) &&
      String.isBlank(oldCon.MailingStreet)) ||
      (String.isNotBlank(newCon.MailingCity) &&
      String.isBlank(oldCon.MailingCity)) ||
      (String.isNotBlank(newCon.MailingState) &&
      String.isBlank(oldCon.MailingState)) ||
      (String.isNotBlank(newCon.MailingPostalCode) &&
      String.isBlank(oldCon.MailingPostalCode)) ||
      (String.isNotBlank(newCon.MailingCountry) &&
      String.isBlank(oldCon.MailingCountry))
    ) {
      return true;
    } else {
      return false;
    }
  }

  private Contact doContactUpdates(Contact oldCon, Contact newCon) {
    oldCon.Email = String.isBlank(oldCon.Email) ? newCon.Email : oldCon.Email;
    oldCon.npe01__AlternateEmail__c = String.isBlank(
        oldCon.npe01__AlternateEmail__c
      )
      ? newCon.npe01__AlternateEmail__c
      : oldCon.npe01__AlternateEmail__c;
    oldCon.npe01__HomeEmail__c = String.isBlank(oldCon.npe01__HomeEmail__c)
      ? newCon.npe01__HomeEmail__c
      : oldCon.npe01__HomeEmail__c;
    oldCon.npe01__Preferred_Email__c = String.isBlank(
        oldCon.npe01__Preferred_Email__c
      )
      ? newCon.npe01__Preferred_Email__c
      : oldCon.npe01__Preferred_Email__c;
    oldCon.npe01__WorkEmail__c = String.isBlank(oldCon.npe01__WorkEmail__c)
      ? newCon.npe01__WorkEmail__c
      : oldCon.npe01__WorkEmail__c;
    oldCon.HomePhone = String.isBlank(oldCon.HomePhone)
      ? newCon.HomePhone
      : oldCon.HomePhone;
    oldCon.npe01__PreferredPhone__c = String.isBlank(
        oldCon.npe01__PreferredPhone__c
      )
      ? newCon.npe01__PreferredPhone__c
      : oldCon.npe01__PreferredPhone__c;
    oldCon.MailingStreet = String.isBlank(oldCon.MailingStreet)
      ? newCon.MailingStreet
      : oldCon.MailingStreet;
    oldCon.MailingCity = String.isBlank(oldCon.MailingCity)
      ? newCon.MailingCity
      : oldCon.MailingCity;
    oldCon.MailingState = String.isBlank(oldCon.MailingState)
      ? newCon.MailingState
      : oldCon.MailingState;
    oldCon.MailingPostalCode = String.isBlank(oldCon.MailingPostalCode)
      ? newCon.MailingPostalCode
      : oldCon.MailingPostalCode;
    oldCon.MailingCountry = String.isBlank(oldCon.MailingCountry)
      ? newCon.MailingCountry
      : oldCon.MailingCountry;
    return oldCon;
  }

  private Map<Id, Account> matchAccounts(
    List<Donation_Form_Submission__c> formSubmissions
  ) {
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.AllowSave = true;
    Map<Id, Account> matchedAccountMap = new Map<Id, Account>();
    Set<Id> accIds = new Set<Id>();
    List<String> names = new List<String>();
    for (Donation_Form_Submission__c dfs : formSubmissions) {
      if (dfs.Organization_Donation__c && dfs.Account__c != null) {
        accIds.add(dfs.Account__c);
      } else if (
        dfs.Organization_Donation__c &&
        String.isNotBlank(dfs.Organization_Name__c)
      ) {
        names.add(dfs.Organization_Name__c);
      }
    }

    List<Account> accountQuery = [
      SELECT Id, Name
      FROM Account
      WHERE Id IN :accIds OR Name IN :names
    ];

    List<Account> accountsToInsert = new List<Account>();
    for (Donation_Form_Submission__c dfs : formSubmissions) {
      if (dfs.Organization_Donation__c) {
        Boolean foundMatch = false;
        for (Account acc : accountQuery) {
          if (dfs.Account__c != null && acc.Id == dfs.Account__c) {
            matchedAccountMap.put(dfs.Id, acc);
            break;
          } else if (
            String.isNotBlank(acc.Name) &&
            acc.Name.equalsIgnoreCase(dfs.Organization_Name__c)
          ) {
            matchedAccountMap.put(dfs.Id, acc);
            break;
          }
        }
        if (!foundMatch) {
          Account a = new Account();
          a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Organization').getRecordTypeId();
          a.Name = dfs.Organization_Name__c;
          a.Region_Category__c = this.relatedCampaignMap.get(dfs.Id)?.Region_Category__c;
          accountsToInsert.add(a);
        }
      }
    }

    if (!accountsToInsert.isEmpty()) {
      Database.insert(accountsToInsert, dml);
      for (Donation_Form_Submission__c dfs : formSubmissions) {
        if (
          dfs.Organization_Donation__c && matchedAccountMap.get(dfs.Id) == null
        ) {
          for (Account acc : accountsToInsert) {
            if (
              String.isNotBlank(acc.Name) &&
              acc.Name.equalsIgnoreCase(dfs.Organization_Name__c)
            ) {
              matchedAccountMap.put(dfs.Id, acc);
              break;
            }
          }
        }
      }
    }
    return matchedAccountMap;
  }

  private Id findExistingAccount(Account acc) {
    Id existingAccountId = null;
    List<Datacloud.FindDuplicatesResult> results = Datacloud.FindDuplicates.findDuplicates(
      new List<Account>{acc}
    );
    for (Datacloud.FindDuplicatesResult findDupeResult : results) {
      for (
        Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()
      ) {
        for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
          for (
            Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()
          ) {
            System.debug(matchRecord);
            System.debug(matchRecord.getRecord());
            existingAccountId = matchRecord.getRecord().Id;
          }
        }
      }
    }
    return existingAccountId;
  }

  private Map<Id, Account> matchAccountsWithDuplicateRules(
    List<Donation_Form_Submission__c> formSubmissions
  ) {
    Map<Id, Account> matchedAccountMap = new Map<Id, Account>();
    Map<Id, Id> dfsIdToExistingAccIdMap = new Map<Id, Id>();
    Set<Id> accIds = new Set<Id>();
    List<Account> accountsToInsert = new List<Account>();
    for (Donation_Form_Submission__c dfs : formSubmissions) {
      if (dfs.Organization_Donation__c && dfs.Account__c != null) {
        accIds.add(dfs.Account__c);
        dfsIdToExistingAccIdMap.put(dfs.Id, dfs.Account__c);
      }
      if (
        dfs.Organization_Donation__c &&
        String.isNotBlank(dfs.Organization_Name__c)
      ) {
        Account a = new Account();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Organization').getRecordTypeId();
        a.Name = dfs.Organization_Name__c;
        a.Region_Category__c = this.relatedCampaignMap.get(dfs.Id)?.Region_Category__c;
        Id existingAccountId = findExistingAccount(a);
        if (existingAccountId == null) {
          accountsToInsert.add(a);
        } else {
          accIds.add(existingAccountId);
          dfsIdToExistingAccIdMap.put(dfs.Id, existingAccountId);
        }
      }
    }

    if (!accountsToInsert.isEmpty()) {
      insert accountsToInsert;
      for (Account a : accountsToInsert) {
        accIds.add(a.Id);
      }
    }

    List<Account> accountQuery = [
      SELECT Id, Name
      FROM Account
      WHERE Id IN :accIds
    ];

    for (Donation_Form_Submission__c dfs : formSubmissions) {
      for (Account acc : accountQuery) {
        if (dfsIdToExistingAccIdMap.get(dfs.Id) == acc.Id) {
          matchedAccountMap.put(dfs.Id, acc);
          break;
        } else if (
          String.isNotBlank(acc.Name) &&
          acc.Name.equalsIgnoreCase(dfs.Organization_Name__c)
        ) {
          matchedAccountMap.put(dfs.Id, acc);
          break;
        }
      }
    }
    return matchedAccountMap;
  }

  private void updateAccountPreferences() {
    List<Account> accountsToUpdate = new List<Account>();
    for (Donation_Form_Submission__c dfs : this.formSubmissions) {
      if (this.contactMap.get(dfs.Id) != null) {
        Contact mapContact = this.contactMap.get(dfs.Id);
        // Update contact account
        List<Contact> updateContact = [
          SELECT Id, AccountId
          FROM Contact
          WHERE Id = :mapContact.Id
        ];
        System.debug(updateContact[0]);
        List<Account> households = [
          SELECT Id, Language_Preference__c, Receipt_Type__c
          FROM Account
          WHERE Id = :updateContact[0].AccountId
        ];
        Account updateHousehold = households[0];
        if (dfs.Language_Preference__c == null) {
          updateHousehold.Language_Preference__c = 'English';
        } else {
          updateHousehold.Language_Preference__c = dfs.Language_Preference__c;
        }
        if (updateHousehold.Receipt_Type__c == null) {
          updateHousehold.Receipt_Type__c = 'Email';
        }
        System.debug(updateHousehold);
        accountsToUpdate.add(updateHousehold);
      } else {
        // Update account
        Account updateAccount = this.accountMap.get(dfs.Id);
        if (dfs.Language_Preference__c != null) {
          updateAccount.Language_Preference__c = 'English';
        } else {
          updateAccount.Language_Preference__c = dfs.Language_Preference__c;
        }
        if (updateAccount.Receipt_Type__c == null) {
          updateAccount.Receipt_Type__c = 'Email';
        }
        accountsToUpdate.add(updateAccount);
      }
    }
    if (!accountsToUpdate.isEmpty()) {
      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.AllowSave = true;
      Database.update(accountsToUpdate, dml);
    }
  }

  private void createAffiliations(
    List<Donation_Form_Submission__c> formSubmissions
  ) {
    List<npe5__Affiliation__c> affiliationsToInsert = new List<npe5__Affiliation__c>();
    Set<Id> conIds = new Set<Id>();
    Set<Id> accIds = new Set<Id>();
    for (Donation_Form_Submission__c dfs : formSubmissions) {
      if (
        dfs.Organization_Donation__c &&
        this.contactMap.get(dfs.Id) != null &&
        this.accountMap.get(dfs.Id) != null
      ) {
        conIds.add(this.contactMap.get(dfs.Id).Id);
        accIds.add(this.accountMap.get(dfs.Id).Id);
      }
    }

    List<npe5__Affiliation__c> existingAffiliations = [
      SELECT Id, npe5__Contact__c, npe5__Organization__c
      FROM npe5__Affiliation__c
      WHERE
        npe5__Contact__c IN :conIds
        AND npe5__Organization__c IN :accIds
        AND npe5__Status__c = 'Current'
    ];

    for (Donation_Form_Submission__c dfs : formSubmissions) {
      Boolean affiliationExists = false;
      if (
        dfs.Organization_Donation__c &&
        this.contactMap.get(dfs.Id) != null &&
        this.accountMap.get(dfs.Id) != null
      ) {
        for (npe5__Affiliation__c af : existingAffiliations) {
          if (
            af.npe5__Contact__c == this.contactMap.get(dfs.Id).Id &&
            af.npe5__Organization__c == this.accountMap.get(dfs.Id).Id
          ) {
            affiliationExists = true;
            break;
          }
        }
        if (!affiliationExists) {
          //create affiliation between this account and contact
          npe5__Affiliation__c affil = new npe5__Affiliation__c();
          affil.npe5__Contact__c = this.contactMap.get(dfs.Id).Id;
          affil.npe5__Organization__c = this.accountMap.get(dfs.Id).Id;
          affil.npe5__Role__c = 'Donor';
          affil.npe5__StartDate__c = Date.today();
          affil.npe5__Status__c = 'Current';
          affiliationsToInsert.add(affil);
        }
      }
    }
    if (!affiliationsToInsert.isEmpty()) {
      insert affiliationsToInsert;
    }
  }

  private Map<Id, List<Donation_Option_Selection__c>> buildDonOptSelectionMap(
    List<Donation_Form_Submission__c> formSubmissions
  ) {
    Map<Id, List<Donation_Option_Selection__c>> donOptSelMap = new Map<Id, List<Donation_Option_Selection__c>>();
    Set<Id> formSubmissionIds = new Set<Id>();
    for (Donation_Form_Submission__c dfs : formSubmissions) {
      formSubmissionIds.add(dfs.Id);
    }
    for (Donation_Option_Selection__c dos : [
      SELECT
        Id,
        Donation_Option__c,
        Donation_Option__r.Fund__c,
        Donation_Form_Submission__c,
        Amount__c,
        Original_Amount__c,
        Original_Currency__c,
        Frequency__c,
        Subscription_Id__c
      FROM Donation_Option_Selection__c
      WHERE Donation_Form_Submission__c IN :formSubmissionIds
    ]) {
      if (donOptSelMap.get(dos.Donation_Form_Submission__c) == null) {
        donOptSelMap.put(
          dos.Donation_Form_Submission__c,
          new List<Donation_Option_Selection__c>()
        );
      }
      donOptSelMap.get(dos.Donation_Form_Submission__c).add(dos);
    }
    return donOptSelMap;
  }

  private Map<Id, Opportunity> createOpportunities(
    List<Donation_Form_Submission__c> formSubmissions
  ) {
    Map<Id, Opportunity> createdOpportunityMap = new Map<Id, Opportunity>();
    for (Donation_Form_Submission__c dfs : formSubmissions) {
      if (dfs.Frequency__c == 'One-time') {
        Opportunity opp = new Opportunity();
        if (
          dfs.Organization_Donation__c && this.accountMap.get(dfs.Id) != null
        ) {
          opp.AccountId = this.accountMap.get(dfs.Id).Id;
          opp.Name =
            dfs.Organization_Name__c +
            ' - ' +
            '$' +
            dfs.Total_Amount__c +
            ' Donation - ' +
            dfs.Submission_Date__c.format();
        } else {
          opp.AccountId = this.contactMap.get(dfs.Id).AccountId;
          opp.Name =
            dfs.First_Name__c +
            ' ' +
            dfs.Last_Name__c +
            ' - ' +
            '$' +
            dfs.Total_Amount__c +
            ' Donation - ' +
            dfs.Submission_Date__c.format();
        }
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
          .get('Donation')
          .getRecordTypeId();
        opp.npsp__Primary_Contact__c = this.contactMap.get(dfs.Id).Id;
        opp.Amount = dfs.Total_Amount__c;
        opp.CloseDate = dfs.Submission_Date__c;
        opp.Transaction_Id__c = dfs.Payment_Processor_Transaction_Id__c;
        opp.LeadSource = 'Donation Page';
        opp.Donation_Source__c = dfs.Donation_Page_Source__c;
        opp.Payment_Method__c = dfs.Payment_Method__c;
        if (opp.Payment_Method__c == 'EFT') {
          opp.Payment_Method__c = 'Bank Account';
        }
        opp.Credit_Card_Type__c = dfs.Credit_Card_Type__c;
        opp.Credit_Card_Exp_Date__c = dfs.Credit_Card_Exp_Date__c;
        if (dfs.Credit_Card_Last_Four__c != null) {
          opp.Credit_Card_Last_Four__c = Integer.valueof(
            dfs.Credit_Card_Last_Four__c
          );
        }
        opp.Credit_Card_No_Hash__c = dfs.Credit_Card_Hash__c;
        opp.CampaignId = dfs.Campaign__c;
        opp.Honor_Memorial_Address_1__c = dfs.Notify_Street_Address__c;
        opp.Honor_Memorial_City__c = dfs.Notify_City__c;
        opp.Honor_Memorial_State__c = dfs.Notify_State__c;
        opp.Honor_Memorial_Zip_Code__c = dfs.Notify_Postal_Code__c;
        opp.Honor_Memorial_Country__c = dfs.Selected_Notify_Country__c;
        opp.Honor_Memorial_Message__c = dfs.Tribute_Message__c;
        opp.npsp__Honoree_Name__c = dfs.Honoree_Name__c;
        opp.Honoree_From__c = dfs.Tribute_From__c;
        opp.npsp__Tribute_Type__c = dfs.Donation_Tribute_Type__c;
        opp.Honor_Memorial_Type__c = dfs.Donation_Tribute_Type__c;
        opp.Honor_Memorial_Notify_First_Name__c = dfs.Notify_First_Name__c;
        opp.Honor_Memorial_Notify_Last_Name__c = dfs.Notify_Last_Name__c;
        opp.Honor_Memorial_Notification_Email__c = dfs.Notify_Email__c;
        opp.Original_Amount__c = dfs.Original_Amount_with_Fees__c;
        opp.Original_Currency__c = dfs.Original_Currency__c;
        opp.Override_Currency_Conversion__c = dfs.Original_Currency__c == 'USD'
          ? false
          : true;
        opp.Email_Receipt_Date__c = Date.today();
        if (
          this.contactMap.get(dfs.Id).Account.Language_Preference__c != null
        ) {
          opp.Language_Preference__c = this
            .contactMap.get(dfs.Id)
            .Account.Language_Preference__c;
        } else {
          opp.Language_Preference__c = 'English';
        }
        if (this.contactMap.get(dfs.Id).Account.Receipt_Type__c != null) {
          opp.Receipt_Type__c = this
            .contactMap.get(dfs.Id)
            .Account.Receipt_Type__c;
        } else {
          opp.Receipt_Type__c = 'Both';
        }
        if (dfs.Payment_Method__c == 'Check') {
          opp.StageName = 'Pending';
        } else {
          opp.StageName = 'Posted';
        }
        if (dfs.Test_Mode_Submission__c) {
          opp.StageName = 'Test Mode';
        }
        opp.Utm_Campaign__c = dfs.utm_campaign__c;
        opp.Utm_Source__c = dfs.utm_source__c;
        opp.Utm_Medium__c = dfs.utm_medium__c;
        // if (this.recDonMap.get(dfs.Id) != null) {
        //   opp.npe03__Recurring_Donation__c = this.recDonMap.get(dfs.Id).Id;
        // }
        opp.Historical_Transaction__c = dfs.Historical_Transaction__c;
        opp.Donation_Form_Submission__c = dfs.Id;
        opp.Donation_Summary__c = dfs.Donation_Summary__c;

        if (relatedCampaignMap.get(dfs.Id) != null) {
          Campaign camp = relatedCampaignMap.get(dfs.Id);
          opp.Donation_Page_Email_Message__c = camp.Donation_Page_Settings__r.Email_Receipt_Message__c;
          opp.Region_Category__c = camp.Region_Category__c;
        }
        createdOpportunityMap.put(dfs.Id, opp);
      }
    }

    if (!createdOpportunityMap.values().isEmpty()) {
      insert createdOpportunityMap.values();
      List<Donation_Form_Submission__c> submissionsToUpdate = new List<Donation_Form_Submission__c>();
      for (Opportunity opp : createdOpportunityMap.values()) {
        Donation_Form_Submission__c dfs = new Donation_Form_Submission__c();
        dfs.Id = opp.Donation_Form_Submission__c;
        dfs.Opportunity__c = opp.Id;
        // dfs.Total_Amount__c = opp.Amount;
        submissionsToUpdate.add(dfs);
      }
      if (!submissionsToUpdate.isEmpty()) {
        update submissionsToUpdate;
      }
    }
    return createdOpportunityMap;
  }

  private void createGAUAllocations(
    List<Donation_Form_Submission__c> formSubmissions
  ) {
    Donation_Form_Settings__c dfSettings = Donation_Form_Settings__c.getOrgDefaults();
    List<npsp__Allocation__c> allocationsToInsert = new List<npsp__Allocation__c>();
    Map<String, Id> utmValToCampaignId = buildUtmCampaignMap(formSubmissions);

    for (Donation_Form_Submission__c dfs : formSubmissions) {
      if (
        this.opportunityMap.get(dfs.Id) != null &&
        this.donOptSelectionMap.get(dfs.Id) != null
      ) {
        Id purposeCodeGauId;
        if (String.isNotBlank(dfs.GAU_Purpose_Code__c)) {
          npsp__General_Accounting_Unit__c gau = DonationPageController.findMatchingGAU(
            dfs.GAU_Purpose_Code__c
          );
          if (gau != null) {
            purposeCodeGauId = gau.Id;
          }
        }
        Map<Id, Decimal> gauAllocAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> gauAllocOrigAmountMap = new Map<Id, Decimal>();
        for (
          Donation_Option_Selection__c dos : this.donOptSelectionMap.get(dfs.Id)
        ) {
          System.debug(dos);

          Id gauId = dos.Donation_Option__r.Fund__c;
          if (purposeCodeGauId != null) {
            gauId = purposeCodeGauId;
          }

          if (gauAllocAmountMap.get(gauId) == null) {
            gauAllocAmountMap.put(gauId, 0);
          }
          Decimal amt = gauAllocAmountMap.get(gauId);
          amt += dos.Amount__c;
          gauAllocAmountMap.put(gauId, amt);
          if (gauAllocOrigAmountMap.get(gauId) == null) {
            gauAllocOrigAmountMap.put(gauId, 0);
          }
          Decimal origAmt = gauAllocOrigAmountMap.get(gauId);
          origAmt += dos.Original_Amount__c;
          gauAllocOrigAmountMap.put(gauId, origAmt);
        }
        if (dfs.Will_Cover_Processing_Fees__c) {
          if (
            gauAllocAmountMap.get(dfSettings.Coverage_Fees_Fund_Id__c) == null
          ) {
            gauAllocAmountMap.put(dfSettings.Coverage_Fees_Fund_Id__c, 0);
          }
          Decimal amt = gauAllocAmountMap.get(
            dfSettings.Coverage_Fees_Fund_Id__c
          );
          amt += (dfs.Total_Amount__c - dfs.Donation_Amount__c);
          gauAllocAmountMap.put(dfSettings.Coverage_Fees_Fund_Id__c, amt);
          if (
            gauAllocOrigAmountMap.get(dfSettings.Coverage_Fees_Fund_Id__c) ==
            null
          ) {
            gauAllocOrigAmountMap.put(dfSettings.Coverage_Fees_Fund_Id__c, 0);
          }
          Decimal origAmt = gauAllocOrigAmountMap.get(
            dfSettings.Coverage_Fees_Fund_Id__c
          );
          origAmt += (dfs.Original_Amount_with_Fees__c -
          dfs.Original_Amount__c);
          gauAllocOrigAmountMap.put(
            dfSettings.Coverage_Fees_Fund_Id__c,
            origAmt
          );
        }
        for (Id gauIdKey : gauAllocAmountMap.keySet()) {
          npsp__Allocation__c alloc = new npsp__Allocation__c();
          alloc.npsp__General_Accounting_Unit__c = gauIdKey;
          alloc.npsp__Opportunity__c = this.opportunityMap.get(dfs.Id).Id;
          alloc.npsp__Amount__c = gauAllocAmountMap.get(gauIdKey);
          alloc.Original_Amount__c = gauAllocOrigAmountMap.get(gauIdKey) != null
            ? gauAllocOrigAmountMap.get(gauIdKey)
            : null;
          alloc.Original_Currency__c = dfs.Original_Currency__c;
          alloc.Override_Currency_Conversion__c = dfs.Original_Currency__c ==
            'USD'
            ? false
            : true;
          if (
            String.isNotBlank(dfs.Campaign_Input__c) &&
            this.campaignInputMap.get(dfs.Campaign_Input__c) != null
          ) {
            alloc.Campaign__c = this
              .campaignInputMap.get(dfs.Campaign_Input__c)
              .Id;
          } else if (utmValToCampaignId.get(dfs.utm_campaign__c) != null) {
            alloc.Campaign__c = utmValToCampaignId.get(dfs.utm_campaign__c);
          } else {
            alloc.Campaign__c = dfs.Campaign__c;
          }
          allocationsToInsert.add(alloc);
        }
      }
    }

    if (!allocationsToInsert.isEmpty()) {
      insert allocationsToInsert;
    }
  }

  public static Map<String, Id> buildUtmCampaignMap(
    List<Donation_Form_Submission__c> formSubmissions
  ) {
    Set<String> utmCampaignValues = new Set<String>();
    for (Donation_Form_Submission__c dfs : formSubmissions) {
      if (String.isNotBlank(dfs.utm_campaign__c)) {
        utmCampaignValues.add(dfs.utm_campaign__c);
      }
    }
    Map<String, Id> utmValToCampaignId = new Map<String, Id>();
    for (Campaign camp : [
      SELECT Id, Code__c
      FROM Campaign
      WHERE Code__c IN :utmCampaignValues AND Code__c != null
    ]) {
      utmValToCampaignId.put((camp.Code__c).toLowerCase(), camp.Id);
    }

    return utmValToCampaignId;
  }

  public class DP_SendEmailQueueable implements Queueable {
    List<Donation_Form_Submission__c> formSubmissions;
    Map<Id, Contact> contactMap;
    Map<Id, Opportunity> opportunityMap;

    public DP_SendEmailQueueable(
      List<Donation_Form_Submission__c> formSubmissions,
      Map<Id, Contact> contactMap,
      Map<Id, Opportunity> opportunityMap
    ) {
      this.formSubmissions = formSubmissions;
      this.contactMap = contactMap;
      this.opportunityMap = opportunityMap;
    }

    public void execute(QueueableContext qc) {
      Donation_Form_Settings__c dfSettings = Donation_Form_Settings__c.getOrgDefaults();
      List<OrgWideEmailAddress> orgWideEmail = [
        SELECT Id
        FROM OrgWideEmailAddress
        WHERE
          DisplayName = :dfSettings.Receipt_From_Email_Address__c
          OR Address = :dfSettings.Receipt_From_Email_Address__c
      ];

      List<Notification__c> notifications = new List<Notification__c>();
      for (Donation_Form_Submission__c dfs : formSubmissions) {
        if (
          dfs.Send_Email_Receipt__c && this.opportunityMap.get(dfs.Id) != null
        ) {
          Notification__c notification = new Notification__c();
          notification.Contact__c = this.contactMap.get(dfs.Id).Id;
          notification.Template_Id__c = dfSettings.Recurring_Donation_Email_Template_Id__c;
          notification.Opportunity_Id__c = this.opportunityMap.get(dfs.Id).Id;
          notification.Org_Wide_Address__c = !orgWideEmail.isEmpty()
            ? orgWideEmail[0].Id
            : null;
          notification.Is_Donation_Page_Receipt__c = true;
          notification.Email__c = true;
          notification.Label__c = 'Donation Page Receipt';
          notification.Message__c =
            'Donation Page Message for Contact (' +
            this.contactMap.get(dfs.Id).Id +
            ') for their Donation (' +
            this.opportunityMap.get(dfs.Id).Id +
            ') on ' +
            String.valueOf(Date.today());

          notifications.add(notification);
        }
      }
      if (!notifications.isEmpty()) {
        insert notifications;
      }
    }
  }

  public Map<String, Campaign> buildCampaignInputMap(
    List<Donation_Form_Submission__c> formSubmissions
  ) {
    Map<String, Campaign> campInputMap = new Map<String, Campaign>();
    Set<String> campCodes = new Set<String>();
    for (Donation_Form_Submission__c dfs : formSubmissions) {
      if (String.isNotBlank(dfs.Campaign_Input__c)) {
        campCodes.add(dfs.Campaign_Input__c);
      }
    }
    if (!campCodes.isEmpty()) {
      for (Campaign camp : [
        SELECT Id, Name, Code__c
        FROM Campaign
        WHERE Code__c IN :campCodes
      ]) {
        campInputMap.put(camp.Code__c, camp);
      }
    }
    return campInputMap;
  }

  private void createCustomerProfiles(
    List<Donation_Form_Submission__c> formSubmissions
  ) {
    List<Customer_Profile__c> cpList = new List<Customer_Profile__c>();
    for (Donation_Form_Submission__c dfs : formSubmissions) {
      if (dfs.Frequency__c != 'One-time') {
        if (this.contactMap.get(dfs.Id) != null) {
          Customer_Profile__c cp = new Customer_Profile__c();
          cp.Contact__c = this.contactMap.get(dfs.Id).Id;
          cp.Customer_Profile_Id__c = dfs.Payment_Processor_Customer_Id__c;
          cp.Payment_Profile_Id__c = dfs.Payment_Profile_Id__c;
          cpList.add(cp);
        }
      }
    }
    if (!cpList.isEmpty()) {
      insert cpList;
    }
  }

  private Map<Id, Campaign> buildRelatedCampaignMap(
    List<Donation_Form_Submission__c> formSubmissions
  ) {
    Map<Id, Campaign> campaignMap = new Map<Id, Campaign>();
    Set<Id> campaignIds = new Set<Id>();

    for (Donation_Form_Submission__c dfs : formSubmissions) {
      if (dfs.Campaign__c != null) {
        campaignIds.add(dfs.Campaign__c);
      }
    }

    Map<Id, Campaign> relatedCampaigns = new Map<Id, Campaign>(
      [
        SELECT
          Id,
          Donation_Page_Settings__c,
          Donation_Page_Settings__r.Email_Receipt_Message__c,
          Region_Category__c
        FROM Campaign
        WHERE Id IN :campaignIds
      ]
    );

    for (Donation_Form_Submission__c dfs : formSubmissions) {
      if (relatedCampaigns.get(dfs.Campaign__c) != null) {
        campaignMap.put(dfs.Id, relatedCampaigns.get(dfs.Campaign__c));
      }
    }

    return campaignMap;
  }

  public void run() {
    Donation_Form_Settings__c dfSettings = Donation_Form_Settings__c.getOrgDefaults();
    this.relatedCampaignMap = buildRelatedCampaignMap(this.formSubmissions);
    if (dfSettings.Use_Lead_Duplicate_Rules__c) {
      //currently no lead dupe rules
      this.leadMap = matchLeadsWithDuplicateRules(this.formSubmissions);
    } else {
      this.leadMap = matchLeads(this.formSubmissions);
    }
    if (dfSettings.Use_Contact_Duplicate_Rules__c) {
      this.contactMap = matchContactsWithDuplicateRules(this.formSubmissions);
    } else {
      this.contactMap = matchContacts(this.formSubmissions);
    }

    // update dfs records with matched contacts
    List<Donation_Form_Submission__c> submissionsToUpdate = new List<Donation_Form_Submission__c>();
    for (Id dfsId : this.contactMap.keySet()) {
      if (this.contactMap.get(dfsId) != null) {
        Donation_Form_Submission__c dfs = new Donation_Form_Submission__c();
        dfs.Id = dfsId;
        dfs.Contact__c = this.contactMap.get(dfsId).Id;
        submissionsToUpdate.add(dfs);
      }
    }
    if (!submissionsToUpdate.isEmpty()) {
      update submissionsToUpdate;
    }

    if (dfSettings.Use_Account_Duplicate_Rules__c) {
      this.accountMap = matchAccountsWithDuplicateRules(this.formSubmissions);
    } else {
      this.accountMap = matchAccounts(this.formSubmissions);
    }
    updateAccountPreferences();
    createCustomerProfiles(this.formSubmissions);
    createAffiliations(this.formSubmissions);
    this.campaignInputMap = buildCampaignInputMap(this.formSubmissions);
    this.donOptSelectionMap = buildDonOptSelectionMap(this.formSubmissions);
    // this.recDonMap = createRecurringDonations(this.formSubmissions);
    this.opportunityMap = createOpportunities(this.formSubmissions);
    System.debug(opportunityMap);
    if (!this.opportunityMap.values().isEmpty()) {
      createGAUAllocations(this.formSubmissions);
    }
    if (!Test.isRunningTest()) {
      System.enqueueJob(
        new DP_SendEmailQueueable(
          this.formSubmissions,
          this.contactMap,
          this.opportunityMap
        )
      );
    } else {
      new DP_SendEmailQueueable(
          this.formSubmissions,
          this.contactMap,
          this.opportunityMap
        )
        .execute(null);
    }
  }
}