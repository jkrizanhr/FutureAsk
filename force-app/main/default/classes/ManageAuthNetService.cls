/**
 * This class handles some common code for both the ManageAuthNetSubscriptionController and the
 * ManageAuthNetRefundsController.
 */
public class ManageAuthNetService {
  public class AuthNetServiceException extends Exception {
  }

  /**
   * TODO: document
   * @param ANetApiResponse
   */
  public static Boolean isResponseValid(
    AuthorizeNetModels.ANetApiResponse response
  ) {
    return (response != null &&
    response.messages != null &&
    response.messages.message != null &&
    response.messages.message.code == 'I00001');
  }

  /**
   * getAuthorizeNetService
   * @param  recordId recordId Salesforce Id for the npe03__Recurring_Donation__c
   * @return          return AuthorizeNetService configured for use
   */
  public static AuthorizeNetService getAuthorizeNetService(
    Id recordId,
    String recordType
  ) {
    Donation_Page_Auth_net_Settings__c authNetSettings;
    Boolean testModeSubmission = true;
    Donation_Form_Submission__c dfs;
    try {
      if (recordType == 'npe03__Recurring_Donation__c') {
        npe03__Recurring_Donation__c recurringDonation = [
          SELECT Id, Donation_Form_Submission__c
          FROM npe03__Recurring_Donation__c
          WHERE Id = :recordId
        ];
        dfs = [
          SELECT Id, Test_Mode_Submission__c
          FROM Donation_Form_Submission__c
          WHERE Id = :recurringDonation.Donation_Form_Submission__c
        ];
      } else if (recordType == 'Opportunity') {
        dfs = [
          SELECT Id, Test_Mode_Submission__c
          FROM Donation_Form_Submission__c
          WHERE Opportunity__c = :recordId
        ];
      } else {
        dfs = null;
      }
    } catch (System.QueryException err) {
      dfs = null;
    }

    if (dfs == null || !dfs.Test_Mode_Submission__c) {
      authNetSettings = Donation_Page_Auth_net_Settings__c.getInstance(
        'Production'
      );
      testModeSubmission = false;
    } else {
      authNetSettings = Donation_Page_Auth_net_Settings__c.getInstance(
        'Sandbox'
      );
    }
    AuthorizeNetService authNetService = new AuthorizeNetService(
      authNetSettings.API_Login_Id__c,
      authNetSettings.Transaction_Key__c,
      testModeSubmission
    );
    return authNetService;
  }

  /**
   * Takes user input from the Aura component and formats for use in the Authorize.net API.
   *
   * @param installment see Class def
   *
   * @return paymentScheduleTypeInterval
   */
  public static AuthorizeNetModels.paymentScheduleTypeInterval resolveInterval(
    Installment installment
  ) {
    AuthorizeNetModels.paymentScheduleTypeInterval interval = new AuthorizeNetModels.paymentScheduleTypeInterval();
    if (installment.period == 'Weekly') {
      interval.length = 7 * installment.frequency;
      interval.unit = 'days';
    } else if (installment.period == 'Monthly') {
      interval.length = installment.frequency;
      interval.unit = 'months';
    } else if (installment.period == 'Yearly') {
      interval.length = 12 * installment.frequency;
      interval.unit = 'months';
    } else {
      throw new AuthNetServiceException(
        'Invalid installment period. Expecting: Weekly, Monthly, Yearly.'
      );
    }
    return interval;
  }

  public static Installment resolveInstallment(
    AuthorizeNetModels.paymentScheduleTypeInterval interval
  ) {
    Installment installment = new Installment();

    if (interval.Unit == 'months') {
      if (Math.mod(interval.Length, 12) == 0) {
        installment.Period = 'Yearly';
        installment.Frequency = interval.Length / 12;
      } else {
        installment.Period = 'Monthly';
        installment.Frequency = interval.Length;
      }
    } else if (interval.Unit == 'days') {
      installment.Period = 'Weekly';
      installment.Frequency = interval.Length / 7;
    } else {
      throw new AuthNetServiceException(
        'Invalid interval unit. Expecting: months, days.'
      );
    }
    return installment;
  }

  public static SubscriptionDates resolveSubscriptionDates(
    AuthorizeNetModels.paymentScheduleType schedule
  ) {
    SubscriptionDates dates = new SubscriptionDates();
    //Parse start date
    dates.startDate = Date.valueOf(schedule.startDate);
    if (
      schedule.totalOccurrences == 9999 //Open-ended
    ) {
      dates.endDate = null;
    } else {
      dates.endDate = dates.startDate.addDays(
        schedule.totalOccurrences *
        (schedule.interval.unit == 'months' ? 30 : 1) *
        schedule.interval.length
      );
    }
    return dates;
  }

  public static Integer resolveTotalOccurrences(
    SubscriptionDates dates,
    AuthorizeNetModels.paymentScheduleTypeInterval interval
  ) {
    if (dates.endDate == null) {
      return 9999;
    } else {
      return dates.startDate.daysBetween(dates.endDate) /
        ((interval.unit == 'months' ? 30 : 1) * interval.length);
    }
  }

  public class SubscriptionDates {
    public Date startDate { get; set; }
    public Date endDate { get; set; }
  }

  public class Installment {
    public String period { get; set; } //Weekly, Monthly, Yearly
    public Integer frequency { get; set; }
  }
}