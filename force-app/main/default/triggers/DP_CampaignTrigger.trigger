trigger DP_CampaignTrigger on Campaign(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  if (Trigger.isAfter) {
    if (Trigger.isInsert) {
      DP_CampaignService.createDonationPageSettings(null, (Map<Id, Campaign>) Trigger.newMap);
    }
    if (Trigger.isUpdate) {
      DP_CampaignService.createDonationPageSettings(
        (Map<Id, Campaign>) Trigger.oldMap,
        (Map<Id, Campaign>) Trigger.newMap
      );
    }
  }
}