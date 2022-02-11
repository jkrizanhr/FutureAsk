public inherited sharing class RecalculateOpportunityRollupsJob implements Schedulable, Database.Batchable<SObject> {
  // Class Instance Variables
  String whereClause;

  // Execute method called when the scheduled job runs. This will call the batch job.
  public void execute(SchedulableContext sc) {
    Database.executeBatch(new RecalculateOpportunityRollupsJob());
  }

  // Utility method for scheduling this apex job.
  public static String schedule(String jobName, String cron, String criteria) {
    if (String.isBlank(jobName)) {
      jobName = 'Recalculate Opportunity Rollups Batch Job';
    }
    if (String.isBlank(cron)) {
      cron = '0 0 23 * * ?'; // Everyday @ 11 PM
    }
    return criteria != null
      ? System.schedule(jobName, cron, new RecalculateOpportunityRollupsJob(criteria))
      : System.schedule(jobName, cron, new RecalculateOpportunityRollupsJob());
  }

  // Constructors
  public RecalculateOpportunityRollupsJob() {
    this.whereClause = 'WHERE CreatedDate = TODAY';
    Database.executeBatch(this);
  }

  public RecalculateOpportunityRollupsJob(String criteria) {
    this.whereClause = criteria;
    Database.executeBatch(this);
  }

  // Start Method
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(
      'SELECT Id, Name, Sum_of_GAU_Allocations__c FROM Opportunity ' +
      this.whereClause
    );
  }

  // Execute Method
  public void execute(Database.BatchableContext bc, List<Opportunity> oppRecords) {
    // put opps in a map for processing
    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
    for (Opportunity opp : oppRecords) {
      opp.Sum_of_GAU_Allocations__c = 0;
      oppMap.put(opp.Id, opp);
    }

    // run agg query to get the sum of the amount of allocations
    for (AggregateResult ar : [
      SELECT sum(npsp__Amount__c) amt, npsp__Opportunity__c
      FROM npsp__Allocation__c
      WHERE npsp__Opportunity__c IN :oppMap.keySet()
      GROUP BY npsp__Opportunity__c
    ]) {
      Id oppId = String.valueOf(ar.get('npsp__Opportunity__c'));
      Double amt = Double.valueOf(ar.get('amt'));

      if (oppId != null) {
        Opportunity opp = oppMap.get(oppId);
        opp.Sum_of_GAU_Allocations__c = amt;
      }
    }
  
    // update oppMap values
    if (!oppMap.isEmpty()){
      update oppMap.values();
    }
  }

  public void finish(Database.BatchableContext bc) {}
}