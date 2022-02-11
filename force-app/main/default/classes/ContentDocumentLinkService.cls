/**
 * Created by rsiepelinga on 11/05/2020.
 */

public without sharing class ContentDocumentLinkService {

  public static void setShareType(List<ContentDocumentLink> links) {
    String prefix = Quarterly_Report__c.SObjectType.getDescribe().getKeyPrefix();
    for(ContentDocumentLink link : links){
      if (String.valueOf(link.LinkedEntityId).substring(0, 3) == prefix){
        link.Visibility = 'AllUsers';
        link.ShareType = 'V';
      }
    }
  }
}