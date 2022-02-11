/**
 * @description This class tests the logic of the OverheadHistoryService class.
 */
@isTest
public without sharing class OverheadHistoryServiceTest {
  /**
   * @description This test evaluates the result when an overhead history record is inserted.
   * Expected outcome:
   * The overhead percentages are copied to the related GAU record.
   */
  @isTest
  public static void testInsert() {
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c(
      Name = 'Test GAU',
      Purpose_Code__c = '123'
    );
    insert gau;

    Overhead_History__c oh = new Overhead_History__c(
      General_Accounting_Unit__c = gau.Id,
      Global_Admin_Overhead__c = 10,
      Program_Management_Overhead__c = 5,
      Start_Date__c = Date.today()
    );

    Test.startTest();
    insert oh;
    Test.stopTest();

    gau = [
      SELECT Id, Global_Admin_Overhead__c, Program_Management_Overhead__c
      FROM npsp__General_Accounting_Unit__c
      WHERE Id = :gau.Id
    ][0];

    System.assertEquals(
      oh.Global_Admin_Overhead__c,
      gau.Global_Admin_Overhead__c,
      'Global Admin Overhead was not copied to the GAU.'
    );
    System.assertEquals(
      oh.Program_Management_Overhead__c,
      gau.Program_Management_Overhead__c,
      'Program Management Overhead was not copied to the GAU.'
    );
  }
}