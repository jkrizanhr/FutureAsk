/**
 * Service class for the Transfer__c object trigger.
 * Contains methods for creating reciprocal transfer records and keeping the statuses
 * between them in sync.
 */
public inherited sharing class TransferService {
  /**
   * Before insert method to default the Fund GL Account lookup using the Primary General
   * Accounting Unit's Default Fund GL Account.
   * @param transfers - Trigger.new
   */
  public static void defaultFundGLAccount(List<Transfer__c> transfers) {
    Set<Id> gauIds = new Set<Id>();
    for (Transfer__c transfer : transfers) {
      if (transfer.Fund_GL_Account__c == null) {
        gauIds.add(transfer.Primary_General_Accounting_Unit__c);
      }
    }

    if (!gauIds.isEmpty()) {
      Map<Id, npsp__General_Accounting_Unit__c> gauMap = new Map<Id, npsp__General_Accounting_Unit__c>(
        [
          SELECT Id, Default_Fund_GL_Account__c
          FROM npsp__General_Accounting_Unit__c
          WHERE Id IN :gauIds AND Default_Fund_GL_Account__c != NULL
        ]
      );

      for (Transfer__c transfer : transfers) {
        if (transfer.Fund_GL_Account__c == null) {
          npsp__General_Accounting_Unit__c gau = gauMap.get(
            transfer.Primary_General_Accounting_Unit__c
          );
          if (gau != null) {
            transfer.Fund_GL_Account__c = gau.Default_Fund_GL_Account__c;
          }
        }
      }
    }
  }
  /**
   * Utility method for mapping the fields from the original transfer record to it's reciprocal.
   * @param transfer - The original transfer record that was created
   * @return Transfer__c - The new transfer object that represents the reciprocal
   */
  private static Transfer__c buildReciprocal(Transfer__c transfer) {
    Transfer__c reciprocal = new Transfer__c();
    reciprocal.Amount__c = transfer.Amount__c;
    reciprocal.Date__c = transfer.Date__c;
    reciprocal.Primary_General_Accounting_Unit__c = transfer.Secondary_General_Accounting_Unit__c;
    reciprocal.Secondary_General_Accounting_Unit__c = transfer.Primary_General_Accounting_Unit__c;
    reciprocal.Status__c = transfer.Status__c;
    reciprocal.Type__c = transfer.Type__c == 'To' ? 'From' : 'To';
    reciprocal.Reciprocal_Transfer__c = transfer.Id;
    return reciprocal;
  }

  /**
   * After insert method to create reciprocal transfer records and then update the reciprocal
   * transfer lookup.
   * @param transfers - Trigger.new
   */
  public static void createReciprocal(List<Transfer__c> transfers) {
    Map<Id, Transfer__c> reciprocalMap = new Map<Id, Transfer__c>();
    for (Transfer__c transfer : transfers) {
      if (transfer.Reciprocal_Transfer__c == null) {
        reciprocalMap.put(transfer.Id, buildReciprocal(transfer));
      }
    }

    if (!reciprocalMap.isEmpty()) {
      insert reciprocalMap.values();

      List<Transfer__c> mutableTransfers = [
        SELECT Id, Reciprocal_Transfer__c
        FROM Transfer__c
        WHERE Id IN :reciprocalMap.keySet()
      ];

      for (Transfer__c transfer : mutableTransfers) {
        transfer.Reciprocal_Transfer__c = reciprocalMap.get(transfer.Id).Id;
      }

      update mutableTransfers;
    }
  }

  /**
   * After update method to update the status on the reciprocal transfer record when the status has
   * changed so that the transfer record and it's reciprocal match.
   * @param transfers - Trigger.new
   * @param oldMap - Trigger.oldMap
   */
  public static void handleUpdate(
    List<Transfer__c> transfers,
    Map<Id, Transfer__c> oldMap
  ) {
    Map<Id, String> reciprocalStatusMap = new Map<Id, String>();

    for (Transfer__c transfer : transfers) {
      if (transfer.Status__c != oldMap.get(transfer.Id).Status__c) {
        reciprocalStatusMap.put(
          transfer.Reciprocal_Transfer__c,
          transfer.Status__c
        );
      }
    }

    if (!reciprocalStatusMap.isEmpty()) {
      List<Transfer__c> reciprocalUpdateList = new List<Transfer__c>();

      List<Transfer__c> reciprocals = [
        SELECT Id, Status__c
        FROM Transfer__c
        WHERE Id IN :reciprocalStatusMap.keySet()
      ];

      for (Transfer__c reciprocal : reciprocals) {
        String newStatus = reciprocalStatusMap.get(reciprocal.Id);
        if (reciprocal.Status__c != newStatus) {
          reciprocal.Status__c = newStatus;
          reciprocalUpdateList.add(reciprocal);
        }
      }

      update reciprocalUpdateList;
    }
  }
}