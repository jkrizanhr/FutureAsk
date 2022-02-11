@isTest
private class ProjectKeyIndicatorCtrlTest {
    
  @isTest
  static void testProjectKeyIndicatorCtrlTest() {

    Project__c proj = new Project__c(
      Name = 'Test Project',
      Strategic_Focus__c = 'Rising Generations'
    );
    insert proj;

    Test.startTest();
      Project__c res = ProjectKeyIndicatorsCtrl.fetchData(proj.Id);
    Test.stopTest();

    System.assertEquals(res.Id, proj.Id, 'The method should return the project given.');
  }
}