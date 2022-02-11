@isTest
private class HistoricalTransactionAPIFactoryTest {

  @isTest static void testFactory() {
    Test.startTest();

    HistoricalTransactionAPI api = HistoricalTransactionAPIFactory.getTransactionsAPIByType('Test');
    System.assert(api instanceof HistoricalTransactionTestAPI);

    api = HistoricalTransactionAPIFactory.getTransactionsAPIByType('INVALID');
    System.assertEquals(null, api);

    Test.stopTest();
  }

}