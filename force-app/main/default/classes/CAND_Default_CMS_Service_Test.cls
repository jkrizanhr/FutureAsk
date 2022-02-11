@isTest
private class CAND_Default_CMS_Service_Test {

  /* Tests for individual methods to ensure more code coverage
    We don't need an individual test for the initSetDefaultCMStatuses method
    because it is fired from the after insert trigger
  */

  @isTest
  static void testCreateDefaultCMStatuses() {

    List<RecordType> recordTypes = [
      SELECT
        Id,
        Name
      FROM RecordType
      WHERE SObjectType = 'Campaign'
      LIMIT 1 // Just in case there is an abnormal amount of Record Types
    ];

    Campaign testCampaign = new Campaign();
    testCampaign.Name = 'Test Campaign';

    Map<Id, String> rt_Map = new Map<Id, String>();
    Set<String> rtName_Set = new Set<String>();

    List<CAND_Default_CMS_Service.MdtDesiredCMS> desiredCMSList = new List<CAND_Default_CMS_Service.MdtDesiredCMS>();
    CAND_Default_CMS_Service.MdtDesiredCMS mdt = new CAND_Default_CMS_Service.MdtDesiredCMS();
    mdt.isDefault = true;
    mdt.hasResponded = true;
    mdt.sortOrder = 1;
    mdt.statusLabel = 'TestStatus';
    desiredCMSList.add(mdt);

    if (!recordTypes.isEmpty()) {
      testCampaign.RecordTypeId = recordTypes[0].Id;
      mdt.campaignRtName = recordTypes[0].Name;
      rt_Map.put(recordTypes[0].Id, recordTypes[0].Name);
      rtName_Set.add(recordTypes[0].Name);
    }

    insert testCampaign;

    CampaignMemberStatus cms = new CampaignMemberStatus();
    cms.CampaignId = testCampaign.Id;
    cms.Label = 'TestStatus';
    insert cms;

    Map<Id, Campaign> campaign_Map = new Map<Id, Campaign>();
    campaign_Map.put(testCampaign.Id, testCampaign);


    Test.startTest();
      CAND_Default_CMS_Service.createDefaultCMStatuses(campaign_Map, rt_Map, rtName_Set, desiredCMSList);
    Test.stopTest();

    // Nothing to assert because there is nothing returned
  }

  @isTest
  static void testGetCampaignRecordTypes() {

    List<String> recordTypes = new List<String>();

    for (RecordTypeInfo rtInfo : Schema.SObjectType.Campaign.getRecordTypeInfos()) {
      if (rtInfo.isAvailable()) {
        recordTypes.add(rtInfo.getName());
      }
    }

    Test.startTest();
      List<RecordType> resultList = CAND_Default_CMS_Service.getCampaignRecordTypes();
    Test.stopTest();

    System.assertEquals(recordTypes.isEmpty(), resultList.isEmpty());
  }

  @isTest
  static void testGetMetadataCMStatuses() {

    List<RecordType> recordTypes = [
      SELECT
       Id,
       Name
      FROM RecordType
      WHERE SObjectType = 'Campaign'
    ];

    Map<String, Id> rt_Map = new Map<String, Id>();

    for (RecordType rt : recordTypes) {
      rt_Map.put(rt.Name, rt.Id);
    }

    Test.startTest();
      List<CAND_Default_CMS_Service.MdtDesiredCMS> resultList = CAND_Default_CMS_Service.getMetadataCMStatuses(rt_Map.keySet());
    Test.stopTest();

    // No point in asserting because we can't be sure that the custom metadata type object
    // will have been created in the UI
  }

  @isTest
  static void testGetCMStatuses() {

    Set<Id> testSet = new Set<Id>();

    Campaign testCampaign = new Campaign();
    testCampaign.Name = 'Test Campaign';
    insert testCampaign;

    testSet.add(testCampaign.Id);

    CampaignMemberStatus testCMS = new CampaignMemberStatus();
    testCMS.CampaignId = testCampaign.Id;
    testCMS.Label = 'Test';
    insert testCMS;

    Test.startTest();
      List<CampaignMemberStatus> result = CAND_Default_CMS_Service.getCurrentCMStatuses(testSet);
    Test.stopTest();

    System.assertEquals(testCMS.CampaignId, result[0].CampaignId);
    System.assertEquals(testCMS.Label, result[0].Label);
  }

  @isTest
  static void testForceHasDefault() {

    List<CAND_Default_CMS_Service.MdtDesiredCMS> desiredCMSList = new List<CAND_Default_CMS_Service.MdtDesiredCMS>();
    Map<String, Boolean> defaultFound_Map = new Map<String, Boolean>();

    CAND_Default_CMS_Service.MdtDesiredCMS cms1 = new CAND_Default_CMS_Service.MdtDesiredCMS();
    cms1.campaignRtName = 'Event';
    cms1.statusLabel = 'Label1';
    desiredCMSList.add(cms1);

    CAND_Default_CMS_Service.MdtDesiredCMS cms2 = new CAND_Default_CMS_Service.MdtDesiredCMS();
    cms2.campaignRtName = 'Event';
    cms2.statusLabel = 'Label2';
    desiredCMSList.add(cms2);

    CAND_Default_CMS_Service.MdtDesiredCMS cms3 = new CAND_Default_CMS_Service.MdtDesiredCMS();
    cms3.campaignRtName = 'Event';
    cms3.statusLabel = 'Label3';
    desiredCMSList.add(cms3);

    Test.startTest();
      List<CAND_Default_CMS_Service.MdtDesiredCMS> resultList = CAND_Default_CMS_Service.forceHasDefault(desiredCMSList, defaultFound_Map);
    Test.stopTest();

    System.assertEquals(cms1.campaignRtName, resultList[0].campaignRtName);
    System.assertEquals(true, resultList[0].isDefault);
  }

  @isTest
  static void testForceHasResponded() {

    List<CAND_Default_CMS_Service.MdtDesiredCMS> desiredCMSList = new List<CAND_Default_CMS_Service.MdtDesiredCMS>();
    Map<String, Boolean> hasRespondedFound_Map = new Map<String, Boolean>();

    CAND_Default_CMS_Service.MdtDesiredCMS cms1 = new CAND_Default_CMS_Service.MdtDesiredCMS();
    cms1.campaignRtName = 'Event';
    cms1.statusLabel = 'Label1';
    desiredCMSList.add(cms1);

    CAND_Default_CMS_Service.MdtDesiredCMS cms2 = new CAND_Default_CMS_Service.MdtDesiredCMS();
    cms2.campaignRtName = 'Event';
    cms2.statusLabel = 'Label2';
    desiredCMSList.add(cms2);

    CAND_Default_CMS_Service.MdtDesiredCMS cms3 = new CAND_Default_CMS_Service.MdtDesiredCMS();
    cms3.campaignRtName = 'Event';
    cms3.statusLabel = 'Label3';
    desiredCMSList.add(cms3);

    Test.startTest();
      List<CAND_Default_CMS_Service.MdtDesiredCMS> resultList = CAND_Default_CMS_Service.forceHasResponded(desiredCMSList, hasRespondedFound_Map);
    Test.stopTest();

    System.assertEquals(cms3.campaignRtName, resultList[2].campaignRtName);
    System.assertEquals(true, resultList[2].hasResponded);
  }

  @isTest
  static void testCreateAndMapCMStatusesToCampaigns() {

    List<RecordType> recordTypes = [
      SELECT
        Id,
        Name
      FROM RecordType
      WHERE SObjectType = 'Campaign'
      LIMIT 1 // Just in case there is an abnormal amount of Record Types
    ];

    Map<Id, String> rt_Map = new Map<Id, String>();

    CAND_Default_CMS_Service.MdtDesiredCMS mdtCMS = new CAND_Default_CMS_Service.MdtDesiredCMS();
    mdtCMS.campaignRtName = 'Event'; // Hardcode this so at least the mdtCMS_Map won't be empty even if there are no recordTypes
    mdtCMS.statusLabel = 'Invited';
    mdtCMS.isDefault = true;
    mdtCMS.hasResponded = true;

    Campaign testCampaign = new Campaign();
    testCampaign.Name = 'Test Campaign';

    if (!recordTypes.isEmpty()) {
      testCampaign.RecordTypeId = recordTypes[0].Id;
      rt_Map.put(recordTypes[0].Id, recordTypes[0].Name);
      mdtCMS.campaignRtName = recordTypes[0].Name;
    }
    insert testCampaign;

    List<Campaign> testCampaignList = new List<Campaign>();
    testCampaignList.add(testCampaign);

    Map<String, CAND_Default_CMS_Service.MdtDesiredCMS> mdtCMS_Map = new Map<String, CAND_Default_CMS_Service.MdtDesiredCMS>();
    mdtCMS_Map.put(mdtCMS.statusLabel, mdtCMS);

    List<CampaignMemberStatus> statusesToUpsert = new List<CampaignMemberStatus>();

    Map<String, Map<String, CAND_Default_CMS_Service.MdtDesiredCMS>> desiredCMS_Map = new Map<String, Map<String, CAND_Default_CMS_Service.MdtDesiredCMS>>();
    desiredCMS_Map.put(mdtCMS.campaignRtName, mdtCMS_Map);

    Test.startTest();
      List<CampaignMemberStatus> resultList = CAND_Default_CMS_Service.createAndMapCMStatusesToCampaigns(testCampaignList, rt_Map, statusesToUpsert, desiredCMS_Map);
    Test.stopTest();

    if (recordTypes.isEmpty()) {
      System.assertEquals(true, resultList.isEmpty());
    } else {
      System.assertEquals(testCampaign.Id, resultList[0].CampaignId);
      System.assertEquals(mdtCMS.statusLabel, resultList[0].Label);
      System.assertEquals(mdtCMS.isDefault, resultList[0].IsDefault);
      System.assertEquals(mdtCMS.hasResponded, resultList[0].HasResponded);
    }
  }

  @isTest
  static void testGetCampaignMembers() {

    Campaign testCampaign = new Campaign();
    testCampaign.Name = 'Test Campaign';
    insert testCampaign;

    Set<Id> testSet = new Set<Id>();
    testSet.add(testCampaign.Id);

    CampaignMemberStatus cms = new CampaignMemberStatus();
    cms.CampaignId = testCampaign.Id;
    cms.Label = 'Test';
    insert cms;

    Contact testContact = new Contact();
    testContact.LastName = 'Test Contact';
    insert testContact;

    CampaignMember testCM = new CampaignMember();
    testCM.CampaignId = testCampaign.Id;
    testCM.ContactId = testContact.Id;
    testCM.Status = cms.Label;
    insert testCM;

    Test.startTest();
      List<CampaignMember> result = CAND_Default_CMS_Service.getCampaignMembers(testSet);
    Test.stopTest();

    System.assertEquals(testCM.CampaignId, result[0].CampaignId);
    System.assertEquals(testCM.Status, result[0].Status);
  }

  @isTest
  static void testReassignAndDeleteStatuses() {
    // Set up test data
    Set<Id> testCampaignIds = new Set<Id>();
    Campaign testCampaign = new Campaign();
    testCampaign.Name = 'Test Campaign';
    insert testCampaign;

    testCampaignIds.add(testCampaign.Id);

    // Create test Contacts to use as test Campaign Members
    List<Contact> testContactList = new List<Contact>();

    Contact testContact1 = new Contact();
    testContact1.LastName = 'Test Contact1';
    testContactList.add(testContact1);

    Contact testContact2 = new Contact();
    testContact2.LastName = 'Test Contact2';
    testContactList.add(testContact2);

    Contact testContact3 = new Contact();
    testContact3.LastName = 'Test Contact3';
    testContactList.add(testContact3);

    Contact testContact4 = new Contact();
    testContact4.LastName = 'Test Contact4';
    testContactList.add(testContact4);

    insert testContactList;

    // Create Campaign Member Statuses
    List<CampaignMemberStatus> cmStatusList = new List<CampaignMemberStatus>();
    List<CampaignMemberStatus> cmsDeleteList = new List<CampaignMemberStatus>();
    List<CampaignMemberStatus> cmsUpsertList = new List<CampaignMemberStatus>();

    // Test reassions to the same CampaignId + Status + HasResponded
    // Don't really care if it is the Default
    CampaignMemberStatus CMS1 = new CampaignMemberStatus();
    CMS1.CampaignId = testCampaign.Id;
    CMS1.Label = 'CMS1';
    cmStatusList.add(CMS1);
    cmsDeleteList.add(CMS1);
    cmsUpsertList.add(CMS1);

    // Test reassigns to hasResponded
    CampaignMemberStatus CMS2 = new CampaignMemberStatus();
    CMS2.CampaignId = testCampaign.Id;
    CMS2.Label = 'CMS2';
    CMS2.HasResponded = true;
    cmStatusList.add(CMS2);
    cmsDeleteList.add(CMS2);

    CampaignMemberStatus CMS3 = new CampaignMemberStatus();
    CMS3.CampaignId = testCampaign.Id;
    CMS3.Label = 'CMS3';
    CMS3.HasResponded = true;
    cmStatusList.add(CMS3);
    cmsUpsertList.add(CMS3);

    // Test reassigns to isDefault
    CampaignMemberStatus CMS4 = new CampaignMemberStatus();
    CMS4.CampaignId = testCampaign.Id;
    CMS4.Label = 'CMS4';
    CMS4.IsDefault = true;
    cmStatusList.add(CMS4);
    cmsDeleteList.add(CMS4);

    CampaignMemberStatus CMS5 = new CampaignMemberStatus();
    CMS5.CampaignId = testCampaign.Id;
    CMS5.Label = 'CMS5';
    CMS5.IsDefault = true;
    cmStatusList.add(CMS5);
    cmsUpsertList.add(CMS5);

    // Test reassigning as a last resort to prevent an error
    CampaignMemberStatus CMS6 = new CampaignMemberStatus();
    CMS6.CampaignId = testCampaign.Id;
    CMS6.Label = 'CMS6';
    cmStatusList.add(CMS6);
    cmsDeleteList.add(CMS6);

    insert cmStatusList;

    // Create Campaign Members
    List<CampaignMember> cmList = new List<CampaignMember>();
    for (Integer i = 0; i < cmsDeleteList.size(); i++) { // Create 4 Campaign Members
      CampaignMember testCM = new CampaignMember();
      testCM.ContactId = testContactList[i].Id;
      testCM.CampaignId = testCampaign.Id;
      testCM.Status = cmsDeleteList[i].Label;
      cmList.add(testCM);
    }

    insert cmList;

    /**************************************************************************/
    Test.startTest();
      CAND_Default_CMS_Service.reassignAndDeleteStatuses(testCampaignIds, cmsDeleteList, cmsUpsertList, cmList);
    Test.stopTest();

    List<CampaignMemberStatus> resultCMStatusList = [
      SELECT
        CampaignId,
        HasResponded,
        IsDefault,
        Label,
        SortOrder
      FROM CampaignMemberStatus
      ORDER BY Label
    ];

    List<CampaignMember> resultCMList = [
      SELECT
        ContactId,
        Contact.Name,
        HasResponded,
        Status
      FROM CampaignMember
      ORDER BY ContactId
    ];

    // Assert that statuses have been deleted
    System.assertEquals(cmsUpsertList.size(), resultCMStatusList.size());
    System.assertEquals(resultCMStatusList.size(), resultCMStatusList.size());

    // Assert that Campaign Members have been updated with the appropriate Campaign Member Status
    for (Integer i = 0; i < resultCMStatusList.size(); i++) {
      System.assertEquals(cmsUpsertList[i].Label, resultCMStatusList[i].Label);
      System.assertEquals(cmsUpsertList[i].HasResponded, resultCMStatusList[i].HasResponded);
    }

    // Contact 1 - Campaign Member 1
    System.assertEquals('CMS1',resultCMList[0].Status); // Started with CMS1
    System.assertEquals(false, resultCMList[0].HasResponded);
    // Contact 2 - Campaign Member 2
    System.assertEquals('CMS3',resultCMList[1].Status); // Started with CMS2
    System.assertEquals(true, resultCMList[1].HasResponded);
    // Contact 3 - Campaign Member 3
    System.assertEquals('CMS5',resultCMList[2].Status); // Started with CMS4
    System.assertEquals(false, resultCMList[2].HasResponded);
    // Contact 4 - Campaign Member 4
    System.assertEquals('CMS1',resultCMList[3].Status); // Started with CMS6
    System.assertEquals(false, resultCMList[3].HasResponded);
  }

   /* Tests for trigger scenarios */

  @isTest
  static void testAfterInsert() {
    // Query record types and create test data
    List<RecordType> recordTypes = [
      SELECT
        Id,
        Name
      FROM RecordType
      WHERE SObjectType = 'Campaign'
      LIMIT 5 // Just in case there is an abnormal amount of Record Types
    ];

    Map<String, Id> rt_CampaignId_Map = new Map<String, Id>();

    Set<Id> testCampaignIds = new Set<Id>();
    List<Campaign> testCampaignList = new List<Campaign>();

    for (RecordType rt : recordTypes) {
      Campaign testCampaign = new Campaign();
      testCampaign.Name = 'Test Campaign ' + rt.Name;
      testCampaign.RecordTypeId = rt.Id;

      rt_CampaignId_Map.put(rt.Name, testCampaign.Id);
      testCampaignIds.add(testCampaign.Id);
      testCampaignList.add(testCampaign);
    }

    Test.startTest();
      insert testCampaignList;
    Test.stopTest();

    List<CampaignMemberStatus> resultCMSList = [
      SELECT
        CampaignId,
        HasResponded,
        IsDefault,
        Label,
        SortOrder
      FROM CampaignMemberStatus
      WHERE CampaignId IN :testCampaignIds
      ORDER BY Label
    ];

    List<Default_Campaign_Member_Statuses__mdt> metadataStatuses = [
      SELECT
        Campaign_RecordType_Name__c,
        Default__c,
        Responded__c,
        Sort_Order__c,
        Status__c
      FROM Default_Campaign_Member_Statuses__mdt
      WHERE Campaign_RecordType_Name__c IN :rt_CampaignId_Map.keySet()
      ORDER BY Status__c
    ];

    // Assertions
    for (Integer i = 0; i < resultCMSList.size(); i++) {
      if (metadataStatuses[i].Campaign_RecordType_Name__c != null && i < metadataStatuses.size() && rt_CampaignId_Map.get(metadataStatuses[i].Campaign_RecordType_Name__c) == resultCMSList[i].CampaignId) {
        System.assertEquals(metadataStatuses[i].Status__c, resultCMSList[i].Label);
      }
    }
  }

  @isTest
  static void testAfterUpdate() {

   List<RecordType> recordTypes = [
     SELECT
      Id,
      Name
     FROM RecordType
     WHERE SObjectType = 'Campaign'
   ];

   Map<String, Id> rt_Map = new Map<String, Id>();

   for (RecordType rt : recordTypes) {
     rt_Map.put(rt.Name, rt.Id);
   }

   Campaign testCampaign = new Campaign();
   testCampaign.Name = 'Test Campaign';
   if (!recordTypes.isEmpty()) {
     testCampaign.RecordTypeId = recordTypes[0].Id;
   }
   insert testCampaign;

   Contact testContact = new Contact();
   testContact.LastName = 'Test Contact';
   insert testContact;

   CampaignMemberStatus testCMStatus = new CampaignMemberStatus();
   testCMStatus.CampaignId = testCampaign.Id;
   testCMStatus.Label = 'Sent';

   CampaignMember testCM = new CampaignMember();
   testCM.ContactId = testContact.Id;
   testCM.CampaignId = testCampaign.Id;
   testCM.Status = 'Sent';
   insert testCM;

   if (recordTypes.size() > 1) {
     testCampaign.RecordTypeId = recordTypes[1].Id;
   }

   List<Default_Campaign_Member_Statuses__mdt> testMdtStatusList = [
     SELECT
      Campaign_RecordType_Name__c,
      Default__c,
      Responded__c,
      Sort_Order__c,
      Status__c
     FROM Default_Campaign_Member_Statuses__mdt
     WHERE Campaign_RecordType_Name__c = :recordTypes[1].Name
     ORDER BY Status__c
   ];

   Map<String, Default_Campaign_Member_Statuses__mdt> mdt_Map = new Map<String, Default_Campaign_Member_Statuses__mdt>();

   for (Default_Campaign_Member_Statuses__mdt mdt : testMdtStatusList) {
     mdt_Map.put(mdt.Status__c, mdt);
   }

   Test.startTest();
     update testCampaign;
   Test.stopTest();

   List<CampaignMemberStatus> resultCMSList = [
     SELECT
      CampaignId,
      HasResponded,
      IsDefault,
      Label,
      SortOrder
     FROM CampaignMemberStatus
     WHERE CampaignId = :testCampaign.Id
     ORDER BY Label
   ];

   List<CampaignMember> resultCampMemberList = [
     SELECT Status
     FROM CampaignMember
     WHERE Id = :testCM.Id
     AND Status IN :mdt_Map.keySet()
   ];

   // Assert that statuses have been deleted
   for (CampaignMemberStatus cms : resultCMSList) {
     if (mdt_Map.get(cms.Label) != null) {
       System.assertEquals(testMdtStatusList.size(), resultCMSList.size());
       Default_Campaign_Member_Statuses__mdt mdt = mdt_Map.get(cms.Label);
       System.assertEquals(mdt.Status__c, cms.Label);
       // Assert that a campaign member's status has been reassigned accordingly
       System.assertEquals(1, resultCampMemberList.size());
     }
   }
  }
}