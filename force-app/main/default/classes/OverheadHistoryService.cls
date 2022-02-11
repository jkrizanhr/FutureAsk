/**
 * @description This class handles all logic for Overhead History triggers.
 */
public without sharing class OverheadHistoryService {
  /**
   * @description This method runs after insert of an Overhead History record. It copies the
   * overhead percentages onto the related GAU record.
   * @param overheads Trigger.new
   */
  public static void copyOverheadPercentageToGAU(
    List<Overhead_History__c> overheads
  ) {
    Map<Id, npsp__General_Accounting_Unit__c> gausToUpdate = new Map<Id, npsp__General_Accounting_Unit__c>();

    for (Overhead_History__c oh : overheads) {
      npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
      gau.Id = oh.General_Accounting_Unit__c;
      gau.Global_Admin_Overhead__c = oh.Global_Admin_Overhead__c;
      gau.Program_Management_Overhead__c = oh.Program_Management_Overhead__c;
      gausToUpdate.put(gau.Id, gau);
    }

    update gausToUpdate.values();
  }
}