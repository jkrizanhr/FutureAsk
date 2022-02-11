@isTest
private class DP_CampaignServiceTest {
  /*
    This is the test class for the DP_CampaignService Apex class
  */

  @isTest
  static void testCreateDonationPageSettings() {
    Campaign camp = new Campaign();
    camp.Name = 'Test Donation Page';
    camp.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Donation_Page').getRecordTypeId();

    Test.startTest();
    insert camp;
    Test.stopTest();

    List<Donation_Page_Settings__c> settingsQuery = [
      SELECT Id, Name, Donation_Page_Title__c, Test_Mode__c
      FROM Donation_Page_Settings__c
      WHERE Campaign__c = :camp.Id
    ];
    System.assert(settingsQuery.size() == 1);
    Donation_Page_Settings__c settings = settingsQuery[0];
    System.assertEquals(camp.Name + ' Settings', settings.Name);
    System.assertEquals(camp.Name, settings.Donation_Page_Title__c);
    System.assertEquals(true, settings.Test_Mode__c);

    camp = [SELECT Id, Donation_Page_Settings__c FROM Campaign WHERE Id = :camp.Id][0];
    System.assertEquals(settings.Id, camp.Donation_Page_Settings__c);
  }

  @isTest
  static void testCreateDonationPageSettingsWithLongCampaignName() {
    Campaign camp = new Campaign();
    camp.Name = 'Test Donation Page with a name that is 80 characters so we can test naming code';
    camp.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Donation_Page').getRecordTypeId();
    insert camp;

    Test.startTest();
    Test.stopTest();

    List<Donation_Page_Settings__c> settingsQuery = [
      SELECT Id, Name, Donation_Page_Title__c, Test_Mode__c
      FROM Donation_Page_Settings__c
      WHERE Campaign__c = :camp.Id
    ];
    System.assert(settingsQuery.size() == 1);
    Donation_Page_Settings__c settings = settingsQuery[0];
    System.assertEquals(camp.Name, settings.Name);
    System.assertEquals(camp.Name, settings.Donation_Page_Title__c);
    System.assertEquals(true, settings.Test_Mode__c);

    camp = [SELECT Id, Donation_Page_Settings__c FROM Campaign WHERE Id = :camp.Id][0];
    System.assertEquals(settings.Id, camp.Donation_Page_Settings__c);
  }
}