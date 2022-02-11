trigger CAND_Default_CMS_Trigger on Campaign (after insert, after update) {
  if (Trigger.isInsert && Trigger.isAfter) {
    CAND_Default_CMS_Service.initSetDefaultCMStatuses(Trigger.newMap);
  }

  if (Trigger.isUpdate && Trigger.isAfter) {
    Map<Id, Campaign> filteredCampaigns = new Map<Id, Campaign>();
    Map<Id, Campaign> oldCampaignMap = (Map<Id, Campaign>)Trigger.oldMap;

    for (Campaign newCampaign : (List<Campaign>)Trigger.new) {
      if (oldCampaignMap.get(newCampaign.Id) != null && oldCampaignMap.get(newCampaign.Id).RecordTypeId != newCampaign.RecordTypeId) {
        filteredCampaigns.put(newCampaign.Id, newCampaign);
      }
    }
    
    if (!filteredCampaigns.isEmpty()) {
      CAND_Default_CMS_Service.initSetDefaultCMStatuses(filteredCampaigns);
    }
  }
}