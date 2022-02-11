trigger AccountRelationshipTrigger on Account_Relationship__c (after insert, after update, after delete) {
  if (Trigger.isAfter) {
    if (Trigger.isInsert) {
      AccountRelationshipService.handleInsert(Trigger.new);
    } else if (Trigger.isUpdate) {
      AccountRelationshipService.handleUpdate(Trigger.new, (Map<Id, Account_Relationship__c>)Trigger.oldMap);
    } else if (Trigger.isDelete) {
      AccountRelationshipService.handleDelete(Trigger.old);
    }
  }
}