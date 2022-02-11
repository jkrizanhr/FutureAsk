public class CAND_Default_CMS_Service {

  @TestVisible
  private class MdtDesiredCMS {
    public String campaignRtName {get; set;}
    public Boolean isDefault {get; set;}
    public Boolean hasResponded {get; set;}
    public Integer sortOrder {get; set;}
    public String statusLabel {get; set;}
  }

  /**************************************************************************/
  // The process requires recordtypes as well as record types whose names match those
  // in the custom metadata type so we initialize the process by querying them.
  public static void initSetDefaultCMStatuses(Map<Id, Campaign> campaign_Map) {

    List<RecordType> rtList = getCampaignRecordTypes();
    Map<Id, String> rt_Map = new Map<Id, String>();
    for (RecordType rt : rtList) {
      rt_Map.put(rt.Id, rt.Name);
    }

    if (rt_Map.isEmpty()) {
      return;
    }

    Set<String> rtName_Set = new Set<String>();
    for (Campaign campaign : campaign_Map.values()) {
      String rtName = rt_Map.get(campaign.RecordTypeId);
      if (rtName != null) {
        rtName_Set.add(rtName);
      } else {
        campaign_Map.remove(campaign.Id);
      }
    }
    // Select the Campaign Member Statuses from the custom metadata type
    List<MdtDesiredCMS> desiredCMSList = getMetadataCMStatuses(rtName_Set);

    createDefaultCMStatuses(campaign_Map, rt_Map, rtName_Set, desiredCMSList);
  }

  /**************************************************************************/
  @TestVisible
  private static void createDefaultCMStatuses(Map<Id, Campaign> campaign_Map, Map<Id, String> rt_Map, Set<String> rtName_Set, List<MdtDesiredCMS> desiredCMSList) {

    if (rt_Map.isEmpty() || desiredCMSList.isEmpty()) {
      return;
    }

    // Select all of the Campaign Member Statuses associated with the current list of Campaigns
    List<CampaignMemberStatus> allStatuses = getCurrentCMStatuses(campaign_Map.keySet());

    // Create Map of desired Campaign Member Statuses from the Custom Metadata Type
    Map<String, Map<String, MdtDesiredCMS>> desiredCMS_Map = new Map<String, Map<String, MdtDesiredCMS>>();
    // Key: Campaign_RecordType_Name__c, Value: Map (Key: Status__c, Value: MdtDesiredCMS)

    for (MdtDesiredCMS desiredCMS : desiredCMSList) {
      if (desiredCMS.campaignRtName != null && desiredCMS_Map.get(desiredCMS.campaignRtName) == null) {
        Map<String, MdtDesiredCMS> desiredCMS_SubMap = new Map<String, MdtDesiredCMS>();
        desiredCMS_SubMap.put(desiredCMS.statusLabel, desiredCMS);
        desiredCMS_Map.put(desiredCMS.campaignRtName, desiredCMS_SubMap);
      } else if (desiredCMS.campaignRtName != null && desiredCMS.statusLabel != null) {
        desiredCMS_Map.get(desiredCMS.campaignRtName).put(desiredCMS.statusLabel, desiredCMS);
      }
    }

    // Initialize Campaign Member Status lists
    List<CampaignMemberStatus> statusesToDelete = new List<CampaignMemberStatus>();
    List<CampaignMemberStatus> statusesToUpsert = new List<CampaignMemberStatus>();

    // Loop through the current Campaign Member Statuses
    for (CampaignMemberStatus cms : allStatuses) {
      Campaign campaign = campaign_Map.get(cms.CampaignId);

      if (campaign.RecordTypeId != null) {
        Id rtId = campaign_Map.get(cms.CampaignId).RecordTypeId;
        String rtName = rt_Map.get(rtId);

        if (!desiredCMS_Map.isEmpty() && desiredCMS_Map.get(rtName) != null) {

          MdtDesiredCMS desiredStatus = desiredCMS_Map.get(rtName).get(cms.Label); // Matching Status in Custom Metadata Type

          if (desiredStatus == null) {
            // cms was not found in the custom metadata type
            statusesToDelete.add(cms);
          } else {
            // cms was found in the custom metadata type, check for differences and update the current cms
            if ((desiredStatus.isDefault != null && cms.IsDefault != desiredStatus.isDefault) || (desiredStatus.hasResponded != null && cms.HasResponded != desiredStatus.hasResponded)) {
              // NOTE: Setting the Sort Order field seems to break things...
              cms.IsDefault = desiredStatus.isDefault;
              cms.HasResponded = desiredStatus.hasResponded;
              statusesToUpsert.add(cms);
            }
            // Remove from the map to decrease the Map Size to help with the performance for the inner loop at the end
            desiredCMS_Map.get(rtName).remove(cms.Label);
          }
        }
      }
    }

    statusesToUpsert = createAndMapCMStatusesToCampaigns(campaign_Map.values(), rt_Map, statusesToUpsert, desiredCMS_Map);

    Boolean didUpsertFail = false;
    try {
      upsert statusesToUpsert;
    } catch (DmlException e) {
      didUpsertFail = true;
    }

    if (!didUpsertFail && !statusesToUpsert.isEmpty() && !statusesToDelete.isEmpty()) {
      List<CampaignMember> cmList = getCampaignMembers(campaign_Map.keySet());
      // If no Campaign Members are associated with the Campaigns, then it is okay to delete the statuses
      // this is particularly useful when testing this function alone in the test class
      if (cmList.isEmpty()) {
        delete statusesToDelete;
      } else {
        reassignAndDeleteStatuses(campaign_Map.keySet(), statusesToDelete, statusesToUpsert, cmList);
      }
    }
  }

  /**************************************************************************/
  public static List<RecordType> getCampaignRecordTypes() {
    return [
      SELECT
        Id,
        Name
      FROM RecordType
      WHERE SObjectType = 'Campaign'
      AND IsActive = true
    ];
  }

  /**************************************************************************/
  public static List<MdtDesiredCMS> getMetadataCMStatuses(Set<String> rtNames) {
    List<Default_Campaign_Member_Statuses__mdt> mdtList = [
      SELECT
        Campaign_RecordType_Name__c,
        Default__c,
        Responded__c,
        Sort_Order__c,
        Status__c
      FROM Default_Campaign_Member_Statuses__mdt
      WHERE Campaign_RecordType_Name__c IN :rtNames
      ORDER BY Campaign_RecordType_Name__c, Sort_Order__c
    ];

    List<MdtDesiredCMS> desiredCMSList = new List<MdtDesiredCMS>();
    Map<String, Boolean> isDefaultFound_Map = new Map<String, Boolean>();
    Map<String, Boolean> hasRespondedFound_Map = new Map<String, Boolean>();

    for (Default_Campaign_Member_Statuses__mdt mdt : mdtList) {
      // NOTE: If a new Campaign RecordType Name is found, then it is a new subset of statuses
      MdtDesiredCMS mdtCMS = new MdtDesiredCMS();
      mdtCMS.campaignRtName = mdt.Campaign_RecordType_Name__c;
      mdtCMS.isDefault = mdt.Default__c;
      mdtCMS.hasResponded = mdt.Responded__c;
      mdtCMS.sortOrder = Integer.valueOf(mdt.Sort_Order__c);
      mdtCMS.statusLabel = mdt.Status__c;

      if (mdtCMS.isDefault && mdtCMS.campaignRtName != null) {
        // At least 1 status has isDefault equal to true for the particular Campaign Record Type
        isDefaultFound_Map.put(mdtCMS.campaignRtName, true);
      }

      if (mdtCMS.hasResponded && mdtCMS.campaignRtName != null) {
        // At least 1 status has isDefault equal to true for the particular Campaign Record Type
        hasRespondedFound_Map.put(mdtCMS.campaignRtName, true);
      }

      if (mdtCMS.campaignRtName != null && mdtCMS.statusLabel != null) {
        desiredCMSList.add(mdtCMS);
      }
    }

    // Ensure at least 1 isDefault and hasResponded Status exist for each Campaign RecordType
    desiredCMSList = forceHasDefault(desiredCMSList, isDefaultFound_Map);
    desiredCMSList = forceHasResponded(desiredCMSList, hasRespondedFound_Map);

    return desiredCMSList;
  }

  /**************************************************************************/
  public static List<CampaignMemberStatus> getCurrentCMStatuses(Set<Id> campaignIds) {
    return [
      SELECT
        CampaignId,
        HasResponded,
        Id,
        IsDefault,
        Label,
        SortOrder
      FROM CampaignMemberStatus
      WHERE CampaignId IN :campaignIds
      ORDER BY CampaignId, SortOrder
    ];
  }

  /**************************************************************************/
  public static List<MdtDesiredCMS> forceHasDefault(List<MdtDesiredCMS> desiredCMSList, Map<String, Boolean> defaultFound_Map) {
    // If no desired statuses are marked as default, then set the first status for that RecordType as the Default
    for (Integer i = 0; i < desiredCMSList.size(); i++) {
      if (desiredCMSList[i].campaignRtName != null && defaultFound_Map.get(desiredCMSList[i].campaignRtName) == null) {
        // Even if desiredCMSList[i].Default__c = false, we'll make the CMS.IsDefault that matches true
        defaultFound_Map.put(desiredCMSList[i].campaignRtName, true);
        desiredCMSList[i].isDefault = true;
      }
    }
    return desiredCMSList;
  }

  /**************************************************************************/
  public static List<MdtDesiredCMS> forceHasResponded(List<MdtDesiredCMS> desiredCMSList, Map<String, Boolean> hasRespondedFound_Map) {
    // If no desired statuses are marked as responded, then set the last status for that RecordType as Responded
    for (Integer i = desiredCMSList.size()-1; i >= 0; i--) {
      if (desiredCMSList[i].campaignRtName != null && hasRespondedFound_Map.get(desiredCMSList[i].campaignRtName) == null) {
        // Even if desiredCMSList[i].Default__c = false, we'll make the CMS.IsDefault that matches true
        hasRespondedFound_Map.put(desiredCMSList[i].campaignRtName, true);
        desiredCMSList[i].hasResponded = true;
      }
    }
    return desiredCMSList;
  }

  /**************************************************************************/
  public static List<CampaignMemberStatus> createAndMapCMStatusesToCampaigns(List<Campaign> campaignList, Map<Id, String> rt_Map, List<CampaignMemberStatus> statusesToUpsert, Map<String, Map<String, MdtDesiredCMS>> desiredCMS_Map) {
    // Assign Campaign Member Statuses to each Campaign accordingly
    for (Campaign campaign : campaignList) {
      if (campaign.RecordTypeId != null && rt_Map.get(campaign.RecordTypeId) != null) {
        String rtName = rt_Map.get(campaign.RecordTypeId);

        if (desiredCMS_Map.get(rtName) != null) {
          Map<String, MdtDesiredCMS> desiredStatusMap = desiredCMS_Map.get(rtName);
          for (MdtDesiredCMS desiredCMS : desiredStatusMap.values()) {
            CampaignMemberStatus newCMS = new CampaignMemberStatus();
            newCMS.CampaignId = campaign.Id;
            newCMS.Label = desiredCMS.statusLabel;
            newCMS.IsDefault = desiredCMS.isDefault;
            newCMS.HasResponded = desiredCMS.hasResponded;
            statusesToUpsert.add(newCMS);
          }
        }
      }
    }
    return statusesToUpsert;
  }

  /**************************************************************************/
  public static List<CampaignMember> getCampaignMembers(Set<Id> campaignIds) {
    // TODO: Add limit or possibly even create a batch job to reassign the campaign members
    return [
      SELECT
        Id,
        CampaignId,
        HasResponded,
        Status
      FROM CampaignMember
      WHERE CampaignId IN :campaignIds
    ];
  }

  /**************************************************************************/
  // Check if there are any campaign members with a status that needs to be deleted.
  @TestVisible
  private static void reassignAndDeleteStatuses(Set<Id> campaignIds, List<CampaignMemberStatus> statusesToDelete, List<CampaignMemberStatus> upsertedStatuses, List<CampaignMember> cmList) {

    Map<String, CampaignMemberStatus> campId_delete_cms_map = new Map<String, CampaignMemberStatus>();

    for (CampaignMemberStatus cms : statusesToDelete) {
      String key = cms.CampaignId + cms.Label;
      campId_delete_cms_map.put(key, cms);
    }

    // Create maps
    Map<String, CampaignMemberStatus> hasResponded_cms_map = new Map<String, CampaignMemberStatus>();
    Map<String, CampaignMemberStatus> isDefault_cms_map = new Map<String, CampaignMemberStatus>();
    Map<String, CampaignMemberStatus> sameLabel_cms_map = new Map<String, CampaignMemberStatus>();
    Map<String, CampaignMemberStatus> else_cms_map = new Map<String, CampaignMemberStatus>();

    for (CampaignMemberStatus cms : upsertedStatuses) {
      if (cms.HasResponded) {
        hasResponded_cms_map.put(cms.CampaignId, cms);
      }
      if (cms.IsDefault) {
        isDefault_cms_map.put(cms.CampaignId, cms);
      }
      if (else_cms_map.get(cms.CampaignId) == null) {
        else_cms_map.put(cms.CampaignId, cms);
      }
      sameLabel_cms_map.put(cms.CampaignId + cms.Label + cms.HasResponded, cms);
    }

    // New list to update specific Campaign Members
    List<CampaignMember> cmUpdateList = new List<CampaignMember>();

    // Loop through Campaign Members and update the statuses accordingly and if the status needs to be reassigned, then
    // add the Campaign Member to the cmUpdateList
    for (CampaignMember cm : cmList) {
      String key = cm.CampaignId + cm.Status;
      CampaignMemberStatus cms = campId_delete_cms_map.get(key);

      if (cms != null) { // The status needs to be reassigned because it is currently one that is not available for the Campaign
        // Check if there is a matching status label that is also "hasResponded" matching
        if (sameLabel_cms_map.get(cm.CampaignId + cm.Status + cm.HasResponded) != null) {
          campId_delete_cms_map.remove(key); // Only here for testing
        } else
        if (cms.HasResponded) {
          // Same thing for those marked with 'Responded"
          CampaignMemberStatus newCms = hasResponded_cms_map.get(cms.CampaignId);
          cm.Status = newCms.Label;
        } else if (cms.IsDefault) {
          // Campaign Members with the status marked as default, change to the new record type's default status
          CampaignMemberStatus newCms = isDefault_cms_map.get(cms.CampaignId);
          cm.Status = newCms.Label;
        } else if (cm.Status == cms.Label) {
          // Change the rest to something so that it won't blow up
          CampaignMemberStatus newCms = else_cms_map.get(cms.CampaignId);
          cm.Status = newCms.Label;
        }
        cmUpdateList.add(cm);
      }
    }

    // Update Campaign Members
    update cmUpdateList;

    // Delete the statuses
    try {
      delete campId_delete_cms_map.values();
    } catch (DmlException e) {
      System.debug(e);
    }
  }
}