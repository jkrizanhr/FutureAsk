public inherited sharing class GPDataImportHelper {
  /**
   * Retrieve the batch size for the platform event trigger.
   * @param salesforceObject
   * @return Integer The batch size
   */
  public static Integer getBatchSize(String salesforceObject) {
    List<SQL_Data_Sync_Setting__mdt> mdt = [
      SELECT Batch_Size__c
      FROM SQL_Data_Sync_Setting__mdt
      WHERE
        Salesforce_Object__c = :salesforceObject
        AND Sync_Direction__c = 'Import'
        AND Batch_Size__c != NULL
        AND Batch_Size__c > 0
    ];
    return !mdt.isEmpty() ? (Integer) mdt[0].Batch_Size__c : 200;
  }

  /**
   * Map the deserialized untyped data to an instance of an account record.
   * First try to match to an existing record on GP_Customer_Id__c, and if none are found,
   * then try to match to an existing record using duplicate rules.
   * Finally, insert or update the account.
   * @param dataMap
   * @return Account
   */
  public static Account importAccount(Map<String, Object> dataMap) {
    Account account = buildAccount(dataMap);
    String customerId = getStringVal(dataMap, 'Customer ID');
    if (String.isNotBlank(customerId)) {
      List<Account> accounts = GPDataImportHelper.fetchAccounts(customerId);
      if (!accounts.isEmpty()) {
        account.Id = accounts[0].Id;
      }
    }

    // Use duplicate rules to check for an existing account
    if (account.Id == null) {
      DuplicateCheckService.duplicateCheck(new List<SObject>{ account });
      if (account.Id != null) {
        List<Account> accounts = [
          SELECT Id, GP_Customer_Id__c
          FROM Account
          WHERE Id = :account.Id
        ];
        if (String.isNotBlank(accounts[0].GP_Customer_Id__c)) {
          account.Id = null;
        }
      }
    }

    // Insert or update account
    if (account.Id == null) {
      account.AccountSource = 'Great Plains';
      // NOTE: The Customer Name will ALWAYS be for an organization.
      account.RecordTypeId = Utils.getRecordTypeId('Account', 'Organization');
      Database.insert(account, Utils.getDMLOptions());
    } else {
      Database.update(account, Utils.getDMLOptions());
    }

    return account;
  }

  /**
   * Compare the contact's first and last name to the organization's name and determine
   * if they match.
   * @param dataMap
   * @param contact
   * @return Boolean False if the name is invalid and therefore matches the organization's name.
   */
  private static Boolean validateName(
    Map<String, Object> dataMap,
    Contact contact
  ) {
    String accountName = getStringVal(dataMap, 'Customer Name');

    if (
      String.isNotBlank(contact.FirstName) &&
      String.isNotBlank(contact.LastName) &&
      String.isNotBlank(accountName) &&
      contact.FirstName + ' ' + contact.Lastname == accountName
    ) {
      return false;
    }
    return true;
  }

  /**
   * Map the deserialized untyped data to an instance of a contact record.
   * First try to match to an existing record on GP_Customer_Id__c, and if none are found,
   * then try to match to an existing record using duplicate rules.
   * Finally, insert or update the contact.
   * @param dataMap
   * @param accountId - The organization record's account id
   * @return Contact
   */
  public static Contact importContact(
    Map<String, Object> dataMap,
    Id accountId
  ) {
    Contact contact = buildContact(dataMap);
    String customerId = getStringVal(dataMap, 'Customer ID');
    if (String.isNotBlank(customerId)) {
      List<Contact> contacts = GPDataImportHelper.fetchContacts(customerId);
      if (!contacts.isEmpty()) {
        contact.Id = contacts[0].Id;
      }
    }

    // Use duplicate rules to check for an existing contact
    if (contact.Id == null) {
      DuplicateCheckService.duplicateCheck(new List<SObject>{ contact });
      if (contact.Id != null) {
        List<Contact> contacts = [
          SELECT Id, GP_Customer_Id__c
          FROM Contact
          WHERE Id = :contact.Id
        ];
        if (String.isNotBlank(contacts[0].GP_Customer_Id__c)) {
          contact.Id = null;
        }
      }
    }

    if (!validateName(dataMap, contact)) {
      return null;
    }

    // Insert or update contact
    if (contact.Id == null) {
      contact.LeadSource = 'Great Plains';
      contact.npsp__Primary_Affiliation__c = accountId;
      Database.insert(contact, Utils.getDMLOptions());
    } else {
      // Set the primary affiliation on the existing contact if it is null
      Contact existingContact = [
        SELECT npsp__Primary_Affiliation__c
        FROM Contact
        WHERE Id = :contact.Id
      ];
      if (existingContact.npsp__Primary_Affiliation__c == null) {
        contact.npsp__Primary_Affiliation__c = accountId;
      }
      Database.update(contact, Utils.getDMLOptions());
    }

    // Set the primary contact on the account if it is null
    Account account = [
      SELECT Id, npe01__One2OneContact__c
      FROM Account
      WHERE Id = :accountId
    ];
    if (account.npe01__One2OneContact__c == null) {
      account.npe01__One2OneContact__c = contact.Id;
      Database.update(account, Utils.getDMLOptions());
    }

    return contact;
  }

  private static String cleanPhone(String phoneNumber) {
    if (
      String.isNotBlank(phoneNumber) &&
      phoneNumber.length() > 10 &&
      phoneNumber.endsWith('0000')
    ) {
      phoneNumber = phoneNumber.substring(0, 10);
    }
    return phoneNumber;
  }

  /**
   * Map the Great Plains data a contact object
   * @param dataMap
   * @return Contact
   */
  private static Contact buildContact(Map<String, Object> dataMap) {
    Contact contact = new Contact();
    contact.FirstName = getStringVal(dataMap, 'Billing Contact First Name');
    contact.LastName = getStringVal(dataMap, 'Billing Contact Last Name');
    contact.npe01__WorkEmail__c = getStringVal(dataMap, 'Email');
    contact.npe01__WorkPhone__c = cleanPhone(getStringVal(dataMap, 'Phone'));
    contact.MailingStreet = getStringVal(dataMap, 'Billing Street');
    contact.MailingCity = getStringVal(dataMap, 'Billing City');
    contact.MailingState = getStringVal(dataMap, 'Billing State');
    contact.MailingPostalCode = getStringVal(dataMap, 'Billing Postal Code');
    contact.MailingCountry = getStringVal(dataMap, 'Billing Country');
    contact.npe01__Preferred_Email__c = 'Work';
    contact.npe01__PreferredPhone__c = 'Work';
    contact.GP_Customer_Id__c = getStringVal(dataMap, 'Customer ID');
    return contact;
  }

  /**
   * Map the Great Plains data an account object
   * @param dataMap
   * @return Account
   */
  private static Account buildAccount(Map<String, Object> dataMap) {
    Account account = new Account();
    account.Name = getStringVal(dataMap, 'Customer Name');
    account.Phone = cleanPhone(getStringVal(dataMap, 'Phone'));
    account.BillingStreet = getStringVal(dataMap, 'Billing Street');
    account.BillingCity = getStringVal(dataMap, 'Billing City');
    account.BillingState = getStringVal(dataMap, 'Billing State');
    account.BillingPostalCode = getStringVal(dataMap, 'Billing Postal Code');
    account.BillingCountry = getStringVal(dataMap, 'Billing Country');
    account.GP_Customer_Id__c = getStringVal(dataMap, 'Customer ID');
    return account;
  }

  /**
   * Map the Great Plains data that is similar across views to a resource order object
   * @param dataMap
   * @return Resource_Order__c
   */
  public static Resource_Order__c buildBaseResourceOrder(
    Map<String, Object> dataMap,
    Id accountId,
    Id contactId
  ) {
    Resource_Order__c resourceOrder = new Resource_Order__c();
    resourceOrder.Account__c = accountId;
    resourceOrder.Contact__c = contactId;
    String transactionDate = getStringVal(dataMap, 'Transaction Date');
    resourceOrder.Name = getStringVal(dataMap, 'Customer Name') + ' - ';
    if (String.isNotBlank(transactionDate)) {
      resourceOrder.Submitted_Date__c = Date.valueOf(transactionDate);
      resourceOrder.Name += resourceOrder.Submitted_Date__c.format();
    }
    resourceOrder.Order_Id__c = getStringVal(dataMap, 'Transaction ID');
    resourceOrder.Currency__c = getStringVal(dataMap, 'Currency');
    if (resourceOrder.Currency__c == 'Z-US$') {
      resourceOrder.Currency__c = 'USD';
    }
    return resourceOrder;
  }

  /**
   * Get the string value for the specified key from the deserialized Great Plains data.
   * @param dataMap
   * @param key
   */
  public static String getStringVal(Map<String, Object> dataMap, String key) {
    return dataMap.get(key) != null ? (String) dataMap.get(key) : null;
  }

  /**
   * Get the decimal value for the specified key from the deserialized Great Plains data.
   * @param dataMap
   * @param key
   */
  public static Decimal getDecimalVal(Map<String, Object> dataMap, String key) {
    return dataMap.get(key) != null ? (Decimal) dataMap.get(key) : null;
  }

  /**
   * Query for existing resource records
   * @param itemId - This comes from the Great Plains data
   * @return List<Resource__c>
   */
  public static List<Resource__c> fetchResources(String itemId) {
    return [
      SELECT
        Id,
        Biblica_Translation_Abbreviation__c,
        Cost__c,
        Description__c,
        GP_Resource_Name__c,
        ISBN__c,
        Language__c,
        Name,
        Resource_Id__c,
        U_of_M_Schedule_ID__c,
        Vendor_ID__c,
        Weight__c
      FROM Resource__c
      WHERE Resource_Id__c = :itemId
    ];
  }

  /**
   * Query for existing contact records
   * @param customerId - This comes from the Great Plains data
   * @return List<Contact>
   */
  private static List<Contact> fetchContacts(String customerId) {
    return [SELECT Id FROM Contact WHERE GP_Customer_Id__c = :customerId];
  }

  /**
   * Query for existing account records
   * @param customerId - This comes from the Great Plains data
   * @return List<Account>
   */
  private static List<Account> fetchAccounts(String customerId) {
    return [SELECT Id FROM Account WHERE GP_Customer_Id__c = :customerId];
  }
}