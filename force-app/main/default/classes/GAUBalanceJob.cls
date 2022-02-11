/**
 * @description This batch job calculates the Current Balance field on GAU records.
 */
public without sharing class GAUBalanceJob implements Database.Batchable<SObject>, Schedulable {
  private Set<Id> inputGAUIds;

  /**
   * @description Constructor
   * @param inputGAUIds A set of GAU Ids to run the job against
   */
  public GAUBalanceJob(Set<Id> inputGAUIds) {
    this.inputGAUIds = inputGAUIds;
  }

  /**
   * @description Constructor
   */
  public GAUBalanceJob() {
    this(null);
  }

  /**
   * @description This method contains the logic that will be run during each scheduled run of the job.
   * @param sc Required parameter for scheduled job
   */
  public void execute(SchedulableContext sc) {
    Database.executeBatch(new GAUBalanceJob(), 1);
  }

  /**
   * @description This method collects the GAU records to run through the batch job.
   * @param bc Required parameter for batch job
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    String query = 'SELECT Id FROM npsp__General_Accounting_Unit__c';

    if (inputGAUIds != null) {
      Set<Id> gauIdsForQuery = inputGAUIds;
      query += ' WHERE Id IN :gauIdsForQuery';
    }

    return Database.getQueryLocator(query);
  }

  /**
   * @description This method calculates the current balance for each GAU in the batch.
   * @param bc Required parameter for batch job
   * @param gaus The list of GAUs in the batch
   */
  public void execute(
    Database.BatchableContext bc,
    List<npsp__General_Accounting_Unit__c> gaus
  ) {
    Set<Id> gauIds = new Map<Id, npsp__General_Accounting_Unit__c>(gaus)
      .keyset();
    Map<Id, GAU_Balance__c> balanceMap = new Map<Id, GAU_Balance__c>();
    Map<Id, List<Expense__c>> expenseMap = new Map<Id, List<Expense__c>>();
    Map<Id, List<Transfer__c>> transferMap = new Map<Id, List<Transfer__c>>();
    Map<Id, List<npsp__Allocation__c>> allocationMap = new Map<Id, List<npsp__Allocation__c>>();

    // Query and map all Balance records by GAU.
    for (GAU_Balance__c balance : [
      SELECT Id, Date__c, GP_Balance__c, General_Accounting_Unit__c
      FROM GAU_Balance__c
      WHERE General_Accounting_Unit__c IN :gauIds
      ORDER BY Date__c ASC
    ]) {
      balanceMap.put(balance.General_Accounting_Unit__c, balance);
    }

    // Query and map all Expense records by GAU.
    for (Expense__c exp : [
      SELECT Id, Date__c, Amount__c, General_Accounting_Unit__c
      FROM Expense__c
      WHERE General_Accounting_Unit__c IN :gauIds
      ORDER BY Date__c DESC
    ]) {
      if (expenseMap.get(exp.General_Accounting_Unit__c) == null) {
        expenseMap.put(exp.General_Accounting_Unit__c, new List<Expense__c>());
      }

      expenseMap.get(exp.General_Accounting_Unit__c).add(exp);
    }

    // Query and map all Transfer__ccords by GAU.
    for (Transfer__c trans : [
      SELECT Id, Date__c, Balance_Amount__c, Primary_General_Accounting_Unit__c
      FROM Transfer__c
      WHERE
        Primary_General_Accounting_Unit__c IN :gauIds
        AND Status__c = 'Complete'
      ORDER BY Date__c DESC
    ]) {
      if (transferMap.get(trans.Primary_General_Accounting_Unit__c) == null) {
        transferMap.put(
          trans.Primary_General_Accounting_Unit__c,
          new List<Transfer__c>()
        );
      }

      transferMap.get(trans.Primary_General_Accounting_Unit__c).add(trans);
    }

    // Query and map all Donation Allocation records by GAU.
    for (npsp__Allocation__c alloc : [
      SELECT
        Id,
        Close_Date__c,
        Balance_Amount__c,
        npsp__General_Accounting_Unit__c
      FROM npsp__Allocation__c
      WHERE
        npsp__General_Accounting_Unit__c IN :gauIds
        AND npsp__Opportunity__c != null
      ORDER BY Close_Date__c DESC
    ]) {
      if (allocationMap.get(alloc.npsp__General_Accounting_Unit__c) == null) {
        allocationMap.put(
          alloc.npsp__General_Accounting_Unit__c,
          new List<npsp__Allocation__c>()
        );
      }

      allocationMap.get(alloc.npsp__General_Accounting_Unit__c).add(alloc);
    }

    for (npsp__General_Accounting_Unit__c gau : gaus) {
      Decimal gpBalance = 0.0;
      GAU_Balance__c balance = balanceMap.get(gau.Id);

      if (balance != null) {
        gpBalance = balance.GP_Balance__c;
      }

      if (expenseMap.get(gau.Id) != null) {
        for (Expense__c exp : expenseMap.get(gau.Id)) {
          if (balance == null || exp.Date__c >= balance.Date__c) {
            gpBalance -= exp.Amount__c;
          }
        }
      }

      if (transferMap.get(gau.Id) != null) {
        for (Transfer__c trans : transferMap.get(gau.Id)) {
          if (balance == null || trans.Date__c >= balance.Date__c) {
            gpBalance += trans.Balance_Amount__c;
          }
        }
      }

      if (allocationMap.get(gau.Id) != null) {
        for (npsp__Allocation__c alloc : allocationMap.get(gau.Id)) {
          if (balance == null || alloc.Close_Date__c >= balance.Date__c) {
            gpBalance += alloc.Balance_Amount__c;
          }
        }
      }

      gau.Current_Balance__c = gpBalance;
    }

    update gaus;
  }

  /**
   * @description This method runs after each batch has completed.
   * @param bc Required parameter for batch job
   */
  public void finish(Database.BatchableContext bc) {
  }
}