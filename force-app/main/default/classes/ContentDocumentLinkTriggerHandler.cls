/**
 * Created by rsiepelinga on 11/5/2020.
*/

public without sharing class ContentDocumentLinkTriggerHandler extends TriggerHandler {
  public override void beforeInsert() {
      ContentDocumentLinkService.setShareType(Trigger.new);
  }
}