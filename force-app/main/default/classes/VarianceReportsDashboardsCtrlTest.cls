@isTest
private class VarianceReportsDashboardsCtrlTest {
  @isTest
  static void fetchData() {
    Embedded_Dashboard__c ed = new Embedded_Dashboard__c(
      Name = 'Test Dashboard',
      iFrame_URL__c = 'http://test.url'
    );
    insert ed;

    Test.startTest();
    List<Embedded_Dashboard__c> res1 = VarianceReportsDashboardsCtrl.fetchData(null);
    List<Embedded_Dashboard__c> res2 = VarianceReportsDashboardsCtrl.fetchData('Search');
    Test.stopTest();

    System.assertEquals(1, res1.size());
    System.assert(res2.isEmpty());
  }
}