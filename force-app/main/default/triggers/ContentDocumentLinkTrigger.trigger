/**
 * Created by rsiepelinga on 11/5/2020
 */

trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  new ContentDocumentLinkTriggerHandler().run();
}