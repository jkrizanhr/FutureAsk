trigger DocumentTemplateQueryTrigger on Document_Template_Query__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  if (Trigger.isBefore) {
    if (Trigger.isInsert) {
      DocumentTemplateQueryService.validateNumPrimaryQueries(Trigger.new, 'insert');
      DocumentTemplateQueryService.buildQuery(Trigger.new);
    }
    if (Trigger.isUpdate) {
      DocumentTemplateQueryService.validateNumPrimaryQueries(Trigger.new, 'update');
      DocumentTemplateQueryService.buildQuery(Trigger.new);
    }
  } else if (Trigger.isAfter) {
    if (Trigger.isInsert || Trigger.isUpdate) {
      DocumentTemplateQueryService.assignPrimaryQuery(Trigger.new);
    }
  }
}