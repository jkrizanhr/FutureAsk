global without sharing class ReceiptMessagesJob implements Database.Batchable<SObject> {
  String query;
  private Integer batchSize;
  List<Id> campaignIds;

  global ReceiptMessagesJob(String query) {
    this.query = query;
  }

  global ReceiptMessagesJob(List<Id> campaignIds) {
    this.campaignIds = campaignIds;
    this.query =
      'SELECT Id,Receipt_Message__c ' +
      'FROM npsp__Allocation__c ' +
      'WHERE Campaign__c != null AND ' +
      'npsp__General_Accounting_Unit__r.npsp__Active__c = true ' + 
      'AND ((Campaign__c IN :campaignIds) OR ' +
      '(Campaign__r.ParentId IN :campaignIds) OR ' +
      '(Campaign__r.Parent.ParentId IN :campaignIds) OR ' +
      '(Campaign__r.Parent.Parent.ParentId IN :campaignIds))';
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    List<Id> campaignIds = this.campaignIds;
    return Database.getQueryLocator(this.query);
  }

  global void execute(
    Database.BatchableContext BC,
    List<npsp__Allocation__c> scope
  ) {
    for (npsp__Allocation__c all : scope) {
      all.Receipt_Message__c = null;
    }
    update scope;
  }

  global void finish(Database.BatchableContext BC) {}
}