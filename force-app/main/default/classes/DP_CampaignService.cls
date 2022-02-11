public class DP_CampaignService {
  /*
    This class handles all trigger logic around Donation Page Campaign records
  */

  /*
    This method creates a Donation Page Settings record on insert of a Donation Page Campaign or if the
    RecordType of a Campaign is changed to Donation Page
  */
  public static void createDonationPageSettings(
    Map<Id, Campaign> olds,
    Map<Id, Campaign> campaigns
  ) {
    Id donationPageRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName()
      .get('Donation_Page')
      .getRecordTypeId();
    List<Campaign> campaignsToProcess = new List<Campaign>();
    for (Id campId : campaigns.keyset()) {
      Campaign oldCampaign = olds == null ? null : olds.get(campId);
      Campaign newCampaign = campaigns.get(campId);
      if (
        (oldCampaign == null ||
        oldCampaign.RecordTypeId != newCampaign.RecordTypeId) &&
        newCampaign.RecordTypeId == donationPageRecordTypeId &&
        newCampaign.Donation_Page_Settings__c == null
      ) {
        campaignsToProcess.add(newCampaign);
      }
    }
    if (!campaignsToProcess.isEmpty()) {
      List<Donation_Page_Settings__c> settingsToInsert = new List<Donation_Page_Settings__c>();
      for (Campaign camp : campaignsToProcess) {
        Donation_Page_Settings__c settings = new Donation_Page_Settings__c();
        settings.Name = camp.Name + ' Settings';
        if (settings.Name.length() > 80) {
          settings.Name = camp.Name;
        }
        settings.Campaign__c = camp.Id;
        settings.Donation_Page_Title__c = camp.Name;
        settings.Test_Mode__c = true;
        settings.Payment_Methods__c = 'Credit Card;EFT';
        settings.Recurring_Donation_Options__c = 'Monthly;One-time;Yearly';
        settings.Page_Contact_Email__c = 'donor.services@biblica.com';
        settingsToInsert.add(settings);
      }
      if (!settingsToInsert.isEmpty()) {
        insert settingsToInsert;
        List<Campaign> campaignsToUpdate = new List<Campaign>();
        for (Donation_Page_Settings__c settings : settingsToInsert) {
          Campaign camp = new Campaign();
          camp.Id = settings.Campaign__c;
          camp.Donation_Page_Settings__c = settings.Id;
          campaignsToUpdate.add(camp);
        }
        if (!campaignsToUpdate.isEmpty()) {
          update campaignsToUpdate;
        }
      }
    }
  }
}