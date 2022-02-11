public inherited sharing class MonthlyGiverJobService {

  // Method is used to check if the amount on the recurring donation is greater than
  // seven dollars per month. Used in findMonthlyGiverStatus method.
  public static Boolean checkAmount(npe03__Recurring_Donation__c rd){
    switch on rd.npe03__Installment_Period__c {
      // Monthly: Is amount greater than seven?
      when 'Monthly' {
        return rd.npe03__Amount__c >= 7 ? true : false;
      }
      // Weekly: Is four (assume four weeks in a month) divided by the frequency (to get
      // the number of installments per month) times the amount greater than seven?
      when 'Weekly' {
        return 4 / rd.npsp__InstallmentFrequency__c * rd.npe03__Amount__c >= 7 ? true : false;
      }
      // 1st and 15th: Is amount times two greater than seven?
      when '1st and 15th' {
        return rd.npe03__Amount__c * 2 >= 7 ? true : false;
      } 
      // Else: Is amount greater than seven?
      when else {
        return rd.npe03__Amount__c >= 7 ? true : false;
      }
    }
  }
  
  // Method is used to check if the automatic payments are scheduled to be received
  // at least ten times per year. Used in findMonthlyGiverStatus method.
  public static Boolean checkFrequency(npe03__Recurring_Donation__c rd){
    switch on rd.npe03__Installment_Period__c {
      // Monthly: Do they give at least every month?
      when 'Monthly' {
        return rd.npsp__InstallmentFrequency__c < 2 ? true : false;
      }
      // Weekly: Do they give at least every five weeks?
      when 'Weekly' {
        return rd.npsp__InstallmentFrequency__c <= 5 ? true : false;
      }
      // 1st and 15th: Do they give twice a month at least every other month?
      when '1st and 15th' {
        return rd.npsp__InstallmentFrequency__c <= 2 ? true : false;
      } 
      // Else: Return false.
      when else {
        return false;
      }
    }
  }

  // Assumptions: This method is being run from the MonthlyGiverJob nightly. It is finding the "Monthly Giver"
  // category for each account that currently has an IsWon opp in the last 365 days.
  public static void findMonthlyGiverStatus(List<Account> accts) {
    Set<String> paymentMethods = new Set<String>{'Credit Card', 'EFT', 'Bank Account', 'ACH/EFT'};

    accts = [SELECT Id, Monthly_Giver__c, 
              (SELECT Id, Amount, Payment_Method__c FROM Opportunities WHERE CloseDate = LAST_N_DAYS:365 AND IsWon = true AND npe03__Recurring_Donation__c = null),
              (SELECT Id, npe03__Amount__c, npe03__Installment_Period__c, npsp__InstallmentFrequency__c, npsp__PaymentMethod__c FROM npe03__RecurringDonations__r WHERE npsp__Status__c = 'Active')
            FROM Account WHERE Id IN :accts];

    List<Account> acctsToUpdate = new List<Account>();

    for (Account acct : accts){
      Boolean amountGreaterThanSeven = false;   // store if recurring donation has an amount greater than seven
      Boolean givesTenTimesPerYear = false;     // store if donation frequency is in list of installment periods
      Boolean automaticDonor = false;           // store if payment method is credit card, eft, or bank account

      // Find if the donor has an active recurring donation that meets the criteria.
      if (!acct.npe03__RecurringDonations__r.isEmpty()){
        for (npe03__Recurring_Donation__c rd : acct.npe03__RecurringDonations__r){
          amountGreaterThanSeven = checkAmount(rd) ? true : amountGreaterThanSeven;
          givesTenTimesPerYear = checkFrequency(rd) ? true : givesTenTimesPerYear;
          automaticDonor = paymentMethods.contains(rd.npsp__PaymentMethod__c) ? true : automaticDonor;
          if (amountGreaterThanSeven && givesTenTimesPerYear && automaticDonor){
            break;
          }
        }
      }
      
      // Guardian: Donors who are set up on automatic payment and give at least 10 autopayments a year, for at least $7.00 a month.
      if (automaticDonor && amountGreaterThanSeven && givesTenTimesPerYear){
        if (acct.Monthly_Giver__c != 'Guardian'){
          acct.Monthly_Giver__c = 'Guardian';
          acctsToUpdate.add(acct);
        }
      } 
      // Auto-Giver: Donors who are set up on automatic payment that do not meet the criteria to be a guardian. They either give less 
      // than $7.00 a month, or less frequently than 10 times per year.
      else if (automaticDonor){
        if (acct.Monthly_Giver__c != 'Auto-Giver'){
          acct.Monthly_Giver__c = 'Auto-Giver';
          acctsToUpdate.add(acct);
        }
      }
      // Regular Donors: Donors who give at least 6 times per year but are not set up on automatic paymets.
      else if (!automaticDonor && !acct.Opportunities.isEmpty() && acct.Opportunities.size() >= 6) {
        if (acct.Monthly_Giver__c != 'Regular Donor'){
          acct.Monthly_Giver__c = 'Regular Donor';
          acctsToUpdate.add(acct);
        }
      }
      // Not applicable: Anyone who is not a Guardian, Auto-Giver or Regular Donor.
      else {
        if (acct.Monthly_Giver__c != 'Not applicable'){
          acct.Monthly_Giver__c = 'Not applicable';
          acctsToUpdate.add(acct);
        }
      }
    }

    // Update all accounts in the list of Accounts to Update.
    if (!acctsToUpdate.isEmpty()){
      update acctsToUpdate;
    }
  }
}