trigger DonationSubmissionEventTrigger on Donation_Submission_Event__e(
  after insert
) {
  Set<Id> dfsIds = new Set<Id>();
  for (Donation_Submission_Event__e event : Trigger.new) {
    if (String.isNotBlank(event.Donation_Form_Submission_Id__c)) {
      dfsIds.add(event.Donation_Form_Submission_Id__c);
    }
  }
  if (!dfsIds.isEmpty()) {
    Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Donation_Form_Submission__c.fields.getMap();
    List<String> fields = new List<String>();
    for (Schema.SObjectField sObjField : fieldMap.values()) {
      Schema.DescribeFieldResult dfr = sObjField.getDescribe();
      fields.add(dfr.getName());
    }
    String dfsFields = String.join(fields, ',');
    String dfsQuery =
      'SELECT ' +
      dfsFields +
      ' FROM Donation_Form_Submission__c WHERE ID IN :dfsIds';
    List<Donation_Form_Submission__c> donationQuery = Database.query(dfsQuery);
    System.enqueueJob(new DonationPageProcessor(donationQuery));
  }
}