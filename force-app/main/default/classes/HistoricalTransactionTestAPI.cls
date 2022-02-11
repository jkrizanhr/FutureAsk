@isTest
public class HistoricalTransactionTestAPI implements HistoricalTransactionAPI {
  private String mode = 'Sandbox';

  public void setMode(String mode) {
    this.mode = mode;
  }

  public Boolean authenticate() {
    return true;
  }

  public HistoricalTransactionModel.TransactionsResponse getTransactions(Datetime startTime, Datetime endTime, String nextId, Integer count) {
    HttpRequest req = new HttpRequest();
    req.setHeader('Content-Type', 'application/json');
    req.setEndpoint('');
    req.setBody('{}');
    Http http = new Http();
    HttpResponse res = http.send(req);
    return new HistoricalTransactionModel.TransactionsResponse(this.parseGetTransactionsJSON(res.getBody()), null);
  }

  private List<Historical_Transaction__c> parseGetTransactionsJSON(String transactionsJSON) {
    List<Historical_Transaction__c> htList = new List<Historical_Transaction__c>();
    TransactionsResponse res = (TransactionsResponse)JSON.deserialize(transactionsJSON, TransactionsResponse.class);
    for (TransactionResponse trans : res.transactions) {
      Historical_Transaction__c ht = new Historical_Transaction__c();
      ht.Transaction_Id__c = trans.transactionId;
      ht.Amount__c = trans.amount;
      ht.Create_Time__c = Datetime.newInstance(trans.createTime);
      ht.Status__c = trans.status;
      ht.Email__c = trans.email;
      ht.Transaction_Type__c = trans.type;
      ht.Type__c = 'Test';
      htList.add(ht);
    }
    return htList;
  }

  public Historical_Transaction__c completeTransactionDetails(Historical_Transaction__c ht) {
    return ht;
  }

  class TransactionsResponse {
    Boolean success;
    List<TransactionResponse> transactions;
  }

  class TransactionResponse {
    public String type;
    public String status;
    public String transactionId;
    public Decimal amount;
    public Long createTime;
    public String email;
  }
}