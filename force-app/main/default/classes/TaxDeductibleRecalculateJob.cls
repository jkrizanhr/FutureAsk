public without sharing class TaxDeductibleRecalculateJob implements Database.Batchable<sObject> {
    String whereClause;

    /**
    * Constructor
    * @param whereClause - SOQL query where clause for which records should the rollups be recalculated for
    */
    public TaxDeductibleRecalculateJob(String whereClause) {
      this.whereClause = whereClause;
    }
  
    public Database.QueryLocator start(Database.BatchableContext bc) {
      String query = 'SELECT Id,Tax_Deductible__c,npsp__Opportunity__c FROM npsp__Allocation__c ';
      if(whereClause != null) {
        query = query + whereClause;
      }
      return Database.getQueryLocator(query);
    }
  
    public void execute(Database.BatchableContext bc, List<SObject> sobjList) {
      GAUAllocationService.taxDeductibleRollupToOpp((List<npsp__Allocation__c>)sobjList, null);
    }
  
    public void finish(Database.BatchableContext bc) {}
  }