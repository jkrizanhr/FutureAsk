trigger DocumentTemplateQuestionTrigger on Document_Template_Question__c (before insert, before update) {
  if (Trigger.isBefore) {
    if (Trigger.isInsert || Trigger.isUpdate) {
      DocumentTemplateQuestionService.setName(Trigger.new);
      DocumentTemplateQuestionService.validateDistinctFields(Trigger.new);
    }
  }
}