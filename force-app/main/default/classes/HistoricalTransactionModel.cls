global class HistoricalTransactionModel {
  global class TransactionsResponse {
    public List<Historical_Transaction__c> transactions;
    public String nextId;
    public Boolean hasError;
    public String errorMessage;

    global TransactionsResponse(List<Historical_Transaction__c> transactions, String nextId) {
      this.transactions = transactions;
      this.nextId = nextId;
      this.hasError = false;
      this.errorMessage = null;
    }

    global TransactionsResponse(List<Historical_Transaction__c> transactions, String nextId, Boolean hasError, String errorMessage) {
      this.transactions = transactions;
      this.nextId = nextId;
      this.hasError = hasError;
      this.errorMessage = errorMessage;
    }
  }
}