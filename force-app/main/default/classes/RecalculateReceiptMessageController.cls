public without sharing class RecalculateReceiptMessageController {
  public class RecalculateReceiptMessageException extends Exception {}
    
  @AuraEnabled
  public static void calculateMessages(Id campaignId) {
      if(campaignId != null) {
	    List<Id> campaignIds = new List<Id>{ campaignId };
    	Database.executeBatch(new ReceiptMessagesJob(campaignIds), 15);
      } else {
          throw new RecalculateReceiptMessageException('No campaign Id specified');
      }
  }
}