public without sharing class DonationPageSettingsService {
  /*
    This class handles all trigger logic for the Donation_Page_Settings__c object
  */

  /*
    This method is used by the Donation Page iFrame code component to pull the necessary information from the campaign
    and generate the iFrame code on the record page
  */
  @AuraEnabled
  public static CampaignMergeFields retrieveCampaignRecordType(
    String settingsId
  ) {
    CampaignMergeFields cmf = new CampaignMergeFields();
    List<Campaign> campaigns = [
      SELECT
        Id,
        RecordTypeId,
        DP_Link_To_Donation_Form__c,
        RecordType.Name,
        Donation_Page_Settings__r.VisualForce_Page__c
      FROM Campaign
      WHERE Donation_Page_Settings__c = :settingsId
      LIMIT 1
    ];
    if (!campaigns.isEmpty()) {
      Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1]
      .IsSandbox;
      cmf.campaign = campaigns[0];
      cmf.baseUrl = isSandbox
        ? Donation_Form_Settings__c.getOrgDefaults().Base_URL__c
        : 'https://biblica.secure.force.com/donate';
      return cmf;
    }
    return null;
  }
  public class CampaignMergeFields {
    @AuraEnabled
    public Campaign campaign;
    @AuraEnabled
    public String baseUrl;
  }
}