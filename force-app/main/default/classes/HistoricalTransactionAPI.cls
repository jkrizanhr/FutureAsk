public interface HistoricalTransactionAPI {
  // This should be called initially to bootstrap API to make authorized calls.
  // It may or may not be needed.
  Boolean authenticate();
  void setMode(String mode);
  HistoricalTransactionModel.TransactionsResponse getTransactions(Datetime startTime, Datetime endTime, String nextId, Integer count);
  Historical_Transaction__c completeTransactionDetails(Historical_Transaction__c ht);
}