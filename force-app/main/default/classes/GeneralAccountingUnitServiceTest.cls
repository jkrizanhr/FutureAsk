@isTest
private class GeneralAccountingUnitServiceTest {
    
  @isTest
  public static void testGeneralAccountingUnitService() {
    
    Project__c p1 = new Project__c(
      Name = 'Test Project'
    );
    insert p1;

    Project__c p2 = new Project__c(
      Name = 'Test Project'
    );
    insert p2;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c(
      Name = 'Test GAU',
      Project__c = p1.Id,
      Purpose_Code__c = '123'
    );

    Test.startTest();
    // TEST ON INSERT OF GAU
    insert gau;
    Project__c res1 = [SELECT Id, General_Accounting_Unit__c FROM Project__c WHERE Id = :p1.Id];
    System.assertEquals(gau.Id, res1.General_Accounting_Unit__c, 'Should be set to match the General Accounting Unit.');

    // UPDATE THE PROJECT TO A DIFFERENT PROJECT
    gau.Project__c = p2.Id;
    update gau;
    Project__c res2 = [SELECT Id, General_Accounting_Unit__c FROM Project__c WHERE Id = :p1.Id];
    System.assertEquals(null, res2.General_Accounting_Unit__c, 'Should be set to null because the GAU lookup was changed.');
    Project__c res3 = [SELECT Id, General_Accounting_Unit__c FROM Project__c WHERE Id = :p2.Id];
    System.assertEquals(gau.Id, res3.General_Accounting_Unit__c, 'Should be set to the gau because the GAU lookup was changed.');
    
    // DELETE/UNDELETE THE PROJECT LOOKUP
    delete gau;
    Project__c res4 = [SELECT Id, General_Accounting_Unit__c FROM Project__c WHERE Id = :p2.Id];
    System.assertEquals(null, res4.General_Accounting_Unit__c, 'Should be set to null because the GAU was deleted.');
    undelete gau;
    Project__c res5 = [SELECT Id, General_Accounting_Unit__c FROM Project__c WHERE Id = :p2.Id];
    System.assertEquals(gau.Id, res5.General_Accounting_Unit__c, 'Should be set to the gau because the gau was undeleted.');

    // UPDATE THE PROJECT LOOKUP TO NULL
    gau.Project__c = null;
    update gau;
    Project__c res6 = [SELECT Id, General_Accounting_Unit__c FROM Project__c WHERE Id = :p2.Id];
    System.assertEquals(null, res6.General_Accounting_Unit__c, 'Should be set to null because the GAU lookup was blanked out.');
  }
}