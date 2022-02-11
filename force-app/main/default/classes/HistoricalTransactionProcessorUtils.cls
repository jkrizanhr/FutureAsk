public inherited sharing class HistoricalTransactionProcessorUtils {
  public static final Id ACCOUNT_ORGANIZATION_RT = Schema.SObjectType.Account
    .getRecordTypeInfosByDeveloperName()
    .get('Organization')
    .getRecordTypeId();
  public static final Id OPPORTUNITY_DONATION_RT = Schema.SObjectType.Opportunity
    .getRecordTypeInfosByDeveloperName()
    .get('Donation')
    .getRecordTypeId();
  public static final String CONTACT_QUERY_STRING =
    'SELECT Id,FirstName,LastName,MailingStreet,MailingCity,MailingState,' +
    'MailingPostalCode,MailingCountry,Phone,Email,AccountId,' +
    'Account.Name,Account.Language_Preference__c,' +
    'Account.Receipt_Type__c,Account.RecordTypeId FROM Contact';

  /*
   * Uses Salesforce's matching rules to find duplicates before a contact is created by the processor.
   *
   * @params: con - contact that salesforce should use duplicate matching rules to match on
   */
  public static Id salesforceContactDuplicateMatchingCheck(Contact con) {
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

  /*
   * Compares two contacts and builds a more complete contact out of the original.
   *
   * @params: htCreatedContact - contact made from mapped historical transaction fields
   *          existingSFContact - existing contact found in salesforce
   */
  public static Contact buildMoreCompleteContact(
    Contact htCreatedContact,
    Contact existingSFContact
  ) {
    if (existingSFContact.Phone == null) {
      existingSFContact.Phone = htCreatedContact.Phone;
    }

    if (existingSFContact.Email == null) {
      existingSFContact.Email = htCreatedContact.Email;
    }

    if (
      existingSFContact.MailingStreet == null &&
      existingSFContact.MailingCity == null &&
      existingSFContact.MailingState == null &&
      existingSFContact.MailingPostalCode == null
    ) {
      existingSFContact.MailingStreet = htCreatedContact.MailingStreet;
      existingSFContact.MailingCity = htCreatedContact.MailingCity;
      existingSFContact.MailingState = htCreatedContact.MailingState;
      existingSFContact.MailingPostalCode = htCreatedContact.MailingPostalCode;
      existingSFContact.MailingCountry = htCreatedContact.MailingCountry;
    }

    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.AllowSave = true;

    //SmartUpsert.go(new List<Contact>{existingSFContact});
    if (existingSFContact.Id != null) {
      Database.update(existingSFContact, dml);
    } else {
      Database.insert(existingSFContact, dml);
    }
    return existingSFContact;
  }

  public static Opportunity upsertDonation(
    Historical_Transaction__c ht,
    Contact relatedContact,
    Account relatedAccount,
    Opportunity donation,
    npe03__Recurring_Donation__c recurringDonation
  ) {
    System.debug('upsertDonation');
    Date settlementDate;

    if (ht.Settlement_Date__c != null) {
      settlementDate = Date.newInstance(
        ht.Settlement_Date__c.year(),
        ht.Settlement_Date__c.month(),
        ht.Settlement_Date__c.day()
      );
    } else {
      settlementDate = Date.newInstance(
        ht.Create_Time__c.year(),
        ht.Create_Time__c.month(),
        ht.Create_Time__c.day()
      );
    }

    if (donation == null) {
      donation = new Opportunity();
      if (
        relatedAccount != null &&
        relatedAccount.RecordTypeId == ACCOUNT_ORGANIZATION_RT
      ) {
        donation.Name =
          relatedAccount.Name +
          ' - $' +
          ht.Amount__c.setScale(2) +
          ' Donation - ' +
          settlementDate.format();
        donation.AccountId = relatedAccount.Id;
      } else {
        donation.Name =
          relatedContact.FirstName +
          ' ' +
          relatedContact.LastName +
          ' - $' +
          ht.Amount__c.setScale(2) +
          ' Donation - ' +
          settlementDate.format();
        donation.AccountId = relatedContact.AccountId;
        donation.Receipt_Type__c = String.isNotBlank(
            relatedContact.Account.Receipt_Type__c
          )
          ? relatedContact.Account.Receipt_Type__c
          : 'Both';
        donation.Language_Preference__c = String.isNotBlank(
            relatedContact.Account.Language_Preference__c
          )
          ? relatedContact.Account.Language_Preference__c
          : 'English';
      }

      donation.npsp__Primary_Contact__c = relatedContact.Id;
      donation.RecordTypeId = OPPORTUNITY_DONATION_RT;
      if (recurringDonation != null) {
        donation.npe03__Recurring_Donation__c = recurringDonation.Id;
      }
    }

    if (settlementDate != donation.CloseDate) {
      donation.Cash_Batch__c = null;
    }

    if (ht.Opportunity_Type_To_Process__c == 'FAILED'){
      donation.StageName = 'Declined';
    } else {
      donation.StageName = donation.StageName == 'Adjustment'
        ? 'Adjustment'
        : 'Posted';
    }
    donation.Donation_Source__c = String.isBlank(donation.Donation_Source__c)
      ? 'Online'
      : donation.Donation_Source__c;
    donation.Credit_Card_Last_Four__c = String.isNotBlank(
        donation.Donation_Source__c
      ) && ht.Credit_Card_Last_4__c != null
      ? Decimal.valueOf(ht.Credit_Card_Last_4__c)
      : null;
    donation.Credit_Card_Exp_Date__c = String.isNotBlank(
        ht.Credit_Card_Expiration_Month__c
      ) && String.isNotBlank(ht.Credit_Card_Expiration_Year__c)
      ? ht.Credit_Card_Expiration_Month__c +
        '/' +
        ht.Credit_Card_Expiration_Year__c
      : null;
    donation.Credit_Card_Type__c = ht.Payment_Type__c;
    donation.Amount = ht.Amount__c;
    donation.Original_Amount__c = ht.Amount__c;
    donation.Original_Currency__c = recurringDonation != null &&
      recurringDonation.Original_Currency__c != null
      ? ht.Currency__c
      : 'USD';
    donation.CloseDate = settlementDate;
    donation.LeadSource = String.isBlank(donation.LeadSource)
      ? 'Donation Page'
      : donation.LeadSource;
    donation.Historical_Transaction__c = ht.Id;
    donation.Transaction_Id__c = ht.Transaction_Id__c;
    donation.Payment_Method__c = translatePaymentMethodValue(ht);
    if (
      recurringDonation != null &&
      recurringDonation.Region_Category__c != null
    ) {
      donation.Region_Category__c = recurringDonation.Region_Category__c != null
        ? recurringDonation.Region_Category__c
        : ht.Region_Category__c;
    }

    //SmartUpsert.go(new List<Opportunity>{donation});
    upsert donation;
    return donation;
  }

  private static String translatePaymentMethodValue(
    Historical_Transaction__c ht
  ) {
    if (ht.Type__c == 'PayPal') {
      return 'PayPal';
    } else if (ht.Type__c == 'Stripe') {
      return ht.Payment_Type__c;
    } else if (ht.Type__c == 'Authorize.net') {
      if (ht.Payment_Type__c == 'eCheck') {
        return 'Bank Account';
      } else {
        return 'Credit Card';
      }
    } else {
      return null;
    }
  }

  public static npe03__Recurring_Donation__c upsertRecurringDonation(
    Historical_Transaction__c ht,
    npe03__Recurring_Donation__c recurringDonation,
    Contact relatedContact,
    Account relatedAccount,
    Customer_Profile__c customerProfile
  ) {
    Date startDate = Date.newInstance(
      ht.Create_Time__c.year(),
      ht.Create_Time__c.month(),
      ht.Create_Time__c.day()
    );

    if (recurringDonation == null) {
      recurringDonation = new npe03__Recurring_Donation__c();

      if (
        relatedAccount != null &&
        relatedAccount.RecordTypeId == ACCOUNT_ORGANIZATION_RT
      ) {
        recurringDonation.Name =
          relatedAccount.Name +
          ' - $' +
          ht.Amount__c.setScale(2) +
          ' Recurring Donation';
        recurringDonation.npe03__Organization__c = relatedAccount.Id;
      } else {
        recurringDonation.Name =
          relatedContact.FirstName +
          ' ' +
          relatedContact.LastName +
          ' - $' +
          ht.Amount__c.setScale(2) +
          ' Recurring Donation';
      }

      recurringDonation.npe03__Contact__c = relatedContact.Id;
      recurringDonation.Subscription_Id__c = ht.Subscription_Id__c;
      recurringDonation.npe03__Date_Established__c = startDate;
      recurringDonation.npsp__StartDate__c = startDate;
      recurringDonation.npsp__EndDate__c = null;
      recurringDonation.npsp__Status__c = 'Active';
      recurringDonation.Original_Currency__c = ht.Currency__c != null
        ? ht.Currency__c
        : 'USD';
      // TODO - Installment period should really be pulled from auth
    }

    if (recurringDonation.Region_Category__c == null) {
      recurringDonation.Region_Category__c = ht.Region_Category__c;
    }

    recurringDonation.npsp__InstallmentFrequency__c = recurringDonation.npsp__InstallmentFrequency__c ==
      null
      ? 1
      : recurringDonation.npsp__InstallmentFrequency__c;
    recurringDonation.npe03__Installment_Period__c = String.isBlank(
        recurringDonation.npe03__Installment_Period__c
      )
      ? 'Monthly'
      : recurringDonation.npe03__Installment_Period__c;
    recurringDonation.npsp__RecurringType__c = 'Open';
    recurringDonation.npsp__Day_of_Month__c = String.valueOf(startDate.day());
    recurringDonation.npe03__Amount__c = ht.Amount__c;
    recurringDonation.Original_Amount__c = ht.Amount__c;
    recurringDonation.npsp__PaymentMethod__c = translatePaymentMethodValue(ht);
    recurringDonation.Last_Transaction_Status__c = ht.Status__c;
    recurringDonation.Credit_Card_Expiration_Month__c = ht.Credit_Card_Expiration_Month__c;
    recurringDonation.Credit_Card_Expiration_Year__c = ht.Credit_Card_Expiration_Year__c;
    recurringDonation.Credit_Card_Last_4__c = ht.Credit_Card_Last_4__c;
    recurringDonation.Customer_Profile__c = customerProfile != null
      ? customerProfile.Id
      : recurringDonation.Customer_Profile__c;

    if (!recurringDonation.Historical_Transactions__r.isEmpty()) {
      Historical_Transaction__c mostRecentHT = recurringDonation.Historical_Transactions__r[0];
      if (mostRecentHT.Create_Time__c > ht.Create_Time__c) {
        recurringDonation.Last_Transaction_Status__c = mostRecentHT.Status__c;
        recurringDonation.Credit_Card_Expiration_Month__c = mostRecentHT.Credit_Card_Expiration_Month__c;
        recurringDonation.Credit_Card_Expiration_Year__c = mostRecentHT.Credit_Card_Expiration_Year__c;
        recurringDonation.Credit_Card_Last_4__c = mostRecentHT.Credit_Card_Last_4__c;
      }
    }
    //SmartUpsert.go(new List<npe03__Recurring_Donation__c>{recurringDonation});
    System.debug(recurringDonation);
    upsert recurringDonation;
    return recurringDonation;
  }

  public static Customer_Profile__c createCustomerProfile(
    Historical_Transaction__c ht,
    Contact con
  ) {
    if (
      String.isNotBlank(ht.Customer_Id__c) &&
      String.isNotBlank(ht.Payment_Profile_Id__c)
    ) {
      Customer_Profile__c cp = new Customer_Profile__c();
      cp.Contact__c = con.Id;
      cp.Customer_Profile_Id__c = ht.Customer_Id__c;
      cp.Payment_Profile_Id__c = ht.Payment_Profile_Id__c;
      insert cp;
      return cp;
    }
    return null;
  }
}