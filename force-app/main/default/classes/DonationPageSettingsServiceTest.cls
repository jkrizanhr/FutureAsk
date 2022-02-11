@isTest
public without sharing class DonationPageSettingsServiceTest {
  /*
    This is the test class for the DonationPageSettingsService Apex class
  */

  @isTest
  static void testRetrieveCampaignRecordType() {
    Campaign c = new Campaign();
    c.Name = 'Test Campaign';
    c.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName()
      .get('Donation_Page')
      .getRecordTypeId();
    insert c;
    List<Donation_Page_Settings__c> dpsQuery = [
      SELECT Id
      FROM Donation_Page_Settings__c
      WHERE Campaign__c = :c.Id
      LIMIT 1
    ];
    System.assert(dpsQuery.size() == 1);
    Donation_Page_Settings__c dps = dpsQuery[0];
    Test.startTest();
    DonationPageSettingsService.CampaignMergeFields result = DonationPageSettingsService.retrieveCampaignRecordType(dps.Id);
    Test.stopTest();
    System.assertEquals(c.Id, result.campaign.Id);
  }
}