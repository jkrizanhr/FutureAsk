public class HistoricalTransactionAPIFactory {
  public static HistoricalTransactionAPI getTransactionsAPIByType(String apiType) {
    Type t = null;
    if (apiType == 'Paypal') {
      t = Type.forName('PaypalSOAPAPI');
    } else if (apiType == 'Authorize.net') {
      t = Type.forName('HistoricalTransactionAuthNetAPI');
    } else if (apiType == 'Stripe') {
      t = Type.forName('HistoricalTransactionStripeAPI');
    } else if (apiType == 'eGiving') {
      t = Type.forName('HistoricalTransactionEGivingAPI');
    } else if (apiType == 'Test') {
      t = Type.forName('HistoricalTransactionTestAPI');
    }
    return (t != null ? (HistoricalTransactionAPI)t.newInstance() : null);
  }
}