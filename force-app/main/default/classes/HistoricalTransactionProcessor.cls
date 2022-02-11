public without sharing class HistoricalTransactionProcessor {
  public class HTProcessorException extends Exception {
  }
  private Historical_Transaction__c ht;
  private Contact relatedContact;
  private Account relatedAccount;
  private Opportunity existingDonation;
  private Customer_Profile__c existingCustomerProfile;
  private npe03__Recurring_Donation__c recurringDonation;

  /*
   * Contructor
   *
   * @params: ht - Sets the primary historical transaction that will be processed
   * in the current instance of HistoricalTransactionProcessor.
   */
  public HistoricalTransactionProcessor(Historical_Transaction__c ht) {
    this.ht = ht;
  }

  /*
   * Main processing method for the class. Handles matching, inserting, and updating
   * of transaction information into Salesforce.
   */
  public virtual void run() {
    //Reset error messages in case this HT is being reprocessed
    this.ht.Error_Messages__c = null;

    try {
      if (String.isNotBlank(ht.Opportunity_Type_to_Process__c)) {
        findExistingRecurringDonation();
        findExistingCustomerProfile();
        findContactAndUpdateOrInsert();
        determineIfDonationsFromOrganization();
        findExistingOpp();
        processOpportunity();
      }

      if (this.ht.Needs_Review__c == false) {
        this.ht.Processed__c = true;
      }
    } catch (Exception e) {
      this.ht.Error_Messages__c =
        e.getLineNumber() +
        ': ' +
        e.getMessage() +
        ' \r\n' +
        e.getStackTraceString();
      this.ht.Needs_Review__c = true;

      if (Test.isRunningTest()) {
        throw new HTProcessorException(ht.Error_Messages__c);
      } else {
        System.debug(ht.Error_Messages__c);
      }
    }

    //SmartUpsert.go(new List<Historical_Transaction__c>{this.ht});
    update this.ht;
  }

  /*
   * Finds an existing recurring donation via the Subscription_Id__c on historical transaction
   */
  private void findExistingRecurringDonation() {
    if (ht.Subscription_Id__c == null) {
      return;
    }

    List<npe03__Recurring_Donation__c> recurringDonations = [
      SELECT
        Credit_Card_Expiration_Month__c,
        Credit_Card_Expiration_Year__c,
        Id,
        Last_Transaction_Status__c,
        Credit_Card_Last_4__c,
        npe03__Amount__c,
        npe03__Contact__c,
        npe03__Installment_Period__c,
        npsp__InstallmentFrequency__c,
        npe03__Organization__c,
        npe03__Organization__r.Language_Preference__c,
        npe03__Organization__r.Name,
        npe03__Organization__r.Receipt_Type__c,
        npe03__Organization__r.RecordTypeId,
        npe03__Recurring_Donation_Campaign__c,
        npsp__Day_of_Month__c,
        npsp__PaymentMethod__c,
        Original_Currency__c,
        Original_Amount__c,
        Subscription_Id__c,
        Customer_Profile__c,
        Region_Category__c,
        npsp__Status__c,
        npsp__EndDate__c,
        (
          SELECT
            Id,
            Status__c,
            Create_Time__c,
            Credit_Card_Expiration_Month__c,
            Credit_Card_Expiration_Year__c,
            Credit_Card_Last_4__c
          FROM Historical_Transactions__r
          ORDER BY Create_Time__c DESC
          LIMIT 1
        ),
        (
          SELECT
            Id,
            Name,
            AccountId,
            Amount,
            StageName,
            CampaignId,
            CloseDate,
            LeadSource,
            RecordTypeId,
            Historical_Transaction__c,
            Description,
            Donation_Source__c,
            npsp__Primary_Contact__c,
            Region_Category__c,
            Transaction_Id__c,
            Type
          FROM npe03__Donations__r
          WHERE isClosed = false
          ORDER BY CloseDate DESC
          LIMIT 1
        )
      FROM npe03__Recurring_Donation__c
      WHERE Subscription_Id__c = :ht.Subscription_Id__c
    ];

    if (!recurringDonations.isEmpty()) {
      this.recurringDonation = recurringDonations[0];
      this.ht.Recurring_Donation__c = recurringDonations[0].Id;
      System.debug(this.recurringDonation.npe03__Donations__r);
    }
  }

  /*
   * Finds an existing Customer_Profile__c record either based on the existing recurring donation
   * or the ids provided on the HT record
   */
  private void findExistingCustomerProfile() {
    if (
      this.recurringDonation != null &&
      this.recurringDonation.Customer_Profile__c != null
    ) {
      List<Customer_Profile__c> cpList = [
        SELECT Id
        FROM Customer_Profile__c
        WHERE Id = :this.recurringDonation.Customer_Profile__c
      ];
      if (!cpList.isEmpty()) {
        this.existingCustomerProfile = cpList[0];
      }
    } else if (
      String.isNotBlank(ht.Customer_Id__c) &&
      String.isNotBlank(ht.Payment_Profile_Id__c)
    ) {
      List<Customer_Profile__c> cpList = [
        SELECT Id
        FROM Customer_Profile__c
        WHERE
          Customer_Profile_Id__c = :ht.Customer_Id__c
          AND Payment_Profile_Id__c = :ht.Payment_Profile_Id__c
      ];
      if (!cpList.isEmpty()) {
        this.existingCustomerProfile = cpList[0];
      }
    }
  }

  /*
   * Maps the historical transaction's contact fields and attempts to match on an existing
   * contact before inserting a new contact into the system.
   */
  private void findContactAndUpdateOrInsert() {
    //Map a new contact record to be dupe matched against or inserted
    Contact htCreatedContact = new Contact();
    htCreatedContact.FirstName = ht.First_Name__c;
    htCreatedContact.LastName = ht.Last_Name__c;
    htCreatedContact.Last_Name_Dupe_Reference__c = String.isNotBlank(
        ht.Last_Name__c
      )
      ? ht.Last_Name__c.replace('-', '')
      : ht.Last_Name__c;
    htCreatedContact.Email = ht.Email__c;
    htCreatedContact.npe01__HomeEmail__c = ht.Email__c;
    htCreatedContact.npe01__Preferred_Email__c = 'Personal';
    htCreatedContact.Phone = ht.Phone__c;
    htCreatedContact.HomePhone = ht.Phone__c;
    htCreatedContact.npe01__PreferredPhone__c = 'Home';
    htCreatedContact.MailingStreet = ht.Billing_Street__c;
    htCreatedContact.MailingCity = ht.Billing_City__c;
    htCreatedContact.MailingState = ht.Billing_State_Province__c;
    htCreatedContact.MailingPostalCode = ht.Billing_Postal_Code__c;
    htCreatedContact.MailingCountry = ht.Billing_Country__c;

    // If the HT has a recurring donation, pull the contact from there
    if (
      this.recurringDonation != null &&
      this.recurringDonation.npe03__Contact__c != null
    ) {
      Id rdConId = this.recurringDonation.npe03__Contact__c;
      List<Contact> conList = Database.query(
        HistoricalTransactionProcessorUtils.CONTACT_QUERY_STRING +
        ' WHERE Id = :rdConId'
      );
      this
        .relatedContact = HistoricalTransactionProcessorUtils.buildMoreCompleteContact(
        htCreatedContact,
        conList[0]
      );
      return;
    }

    // Attempt to match the HT's provided contact info with an existing contact
    Id dupeMatcherResultContactId = HistoricalTransactionProcessorUtils.salesforceContactDuplicateMatchingCheck(
      htCreatedContact
    );
    if (dupeMatcherResultContactId != null) {
      List<Contact> dupeMatcherResultContacts = Database.query(
        HistoricalTransactionProcessorUtils.CONTACT_QUERY_STRING +
        ' WHERE Id = :dupeMatcherResultContactId'
      );
      this
        .relatedContact = HistoricalTransactionProcessorUtils.buildMoreCompleteContact(
        htCreatedContact,
        dupeMatcherResultContacts[0]
      );
    } else {
      Id conId;
      if (String.isBlank(htCreatedContact.LastName)) {
        if (ht.Donation_Form_Submission__c != null) {
          List<Donation_Form_Submission__c> dfsList = [
            SELECT Id, Opportunity__c, Opportunity__r.npsp__Primary_Contact__c
            FROM Donation_Form_Submission__c
            WHERE
              Id = :ht.Donation_Form_Submission__c
              AND Opportunity__c != null
          ];
          if (!dfsList.isEmpty()) {
            conId = dfsList[0].Opportunity__r.npsp__Primary_Contact__c;
          }
        }
      } else {
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        Database.insert(htCreatedContact, dml);
        conId = htCreatedContact.Id;
      }
      if (conId != null) {
        this.relatedContact = Database.query(
          HistoricalTransactionProcessorUtils.CONTACT_QUERY_STRING +
          ' WHERE Id = :conId'
        );
      } else {
        throw new HTProcessorException('No contact found for HT record');
      }
    }
  }

  /*
   * Looks at the matched recurring donation and sets relatedAccount if
   * recurring donation is from an organization
   */
  private void determineIfDonationsFromOrganization() {
    // If an existing recurring donation has an organization set, the account is
    // stored off so that the donation will be correctly linked to the org and not
    // the contact's household
    if (
      this.recurringDonation != null &&
      this.recurringDonation.npe03__Organization__c != null &&
      this.recurringDonation.npe03__Organization__r.RecordTypeId ==
      HistoricalTransactionProcessorUtils.ACCOUNT_ORGANIZATION_RT
    ) {
      this.relatedAccount = this.recurringDonation.npe03__Organization__r;
    }
  }

  /*
   * Searches for an existing opportunity by matching transaction id or if a
   * opportunity is already linked to the current HT. If no match, try to find
   * a open pledged opportunity on the related recurring donation and set that.
   */
  private void findExistingOpp() {
    List<Opportunity> opportunities = [
      SELECT
        Id,
        Name,
        AccountId,
        Amount,
        StageName,
        CampaignId,
        CloseDate,
        LeadSource,
        RecordTypeId,
        Historical_Transaction__c,
        Description,
        npsp__Primary_Contact__c,
        Transaction_Id__c,
        Type,
        Donation_Source__c
      FROM Opportunity
      WHERE
        Historical_Transaction__c = :ht.Id
        OR Transaction_Id__c = :ht.Transaction_Id__c
    ];
    this.existingDonation = opportunities.isEmpty() ? null : opportunities[0];

    if (this.existingDonation == null) {
      if (ht.Donation_Form_Submission__c != null) {
        List<Donation_Form_Submission__c> dfsList = [
          SELECT
            Id,
            (
              SELECT
                Id,
                Name,
                AccountId,
                Amount,
                StageName,
                CampaignId,
                CloseDate,
                LeadSource,
                RecordTypeId,
                Historical_Transaction__c,
                Description,
                npsp__Primary_Contact__c,
                Transaction_Id__c,
                Type,
                Donation_Source__c
              FROM Opportunities__r
            )
          FROM Donation_Form_Submission__c
          WHERE Id = :ht.Donation_Form_Submission__c
        ];
        if (!dfsList.isEmpty() && !dfsList[0].Opportunities__r.isEmpty()) {
          this.existingDonation = dfsList[0].Opportunities__r[0];
        }
      }
      if (
        this.existingDonation == null &&
        this.recurringDonation != null &&
        this.recurringDonation.npe03__Donations__r != null &&
        !this.recurringDonation.npe03__Donations__r.isEmpty()
      ) {
        this.existingDonation = this.recurringDonation.npe03__Donations__r[0];
      }
    }
  }

  /*
   * Maps the historical transaction's opportunity fields and then upserts them to
   * the opportunity record.
   */
  private void processOpportunity() {
    System.debug('processOpportunity');

    if (ht.Subscription_Id__c != null) {
      System.debug('Has existing donation? ' + existingDonation);
      if (this.existingCustomerProfile == null && this.relatedContact != null) {
        this
          .existingCustomerProfile = HistoricalTransactionProcessorUtils.createCustomerProfile(
          ht,
          this.relatedContact
        );
      }
      this
        .recurringDonation = HistoricalTransactionProcessorUtils.upsertRecurringDonation(
        ht,
        this.recurringDonation,
        this.relatedContact,
        this.relatedAccount,
        this.existingCustomerProfile
      );
      this.ht.Recurring_Donation__c = this.recurringDonation.Id;
    }

    this.existingDonation = HistoricalTransactionProcessorUtils.upsertDonation(
      ht,
      this.relatedContact,
      this.relatedAccount,
      this.existingDonation,
      this.recurringDonation
    );
  }
}