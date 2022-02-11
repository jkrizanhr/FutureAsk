global class HistoricalTransactionFetchJob implements Schedulable {
  global class HistoricalTransactionFetchJobException extends Exception {}
  global static final String CRON_EXP = '0 0 0/1 1/1 * ? *';
  global String type;

  global HistoricalTransactionFetchJob(String type) {
    this.type = type;
  }

  global static String schedule(String type, String jobName, String cron) {
    if (type == null) {
      throw new HistoricalTransactionFetchJobException('A type must be provided for this job.');
    }
    if (jobName == null) {
      jobName = 'Historical Transactions Fetch Job';
    }
    if (cron == null) {
      cron = HistoricalTransactionFetchJob.CRON_EXP;
    }
    return System.schedule(jobName, cron, new HistoricalTransactionFetchJob(type));
  }

  global static void run(String type) {
    System.enqueueJob(new HistoricalTransactionFetcher(type));
  }

  global void execute(SchedulableContext sc) {
    System.enqueueJob(new HistoricalTransactionFetcher(this.type));
  }
}

/*

HistoricalTransactionFetchJob.schedule('Paypal', 'Historical Transaction Fetch Job 0 min', '0 0 0/1 1/1 * ? *');
PaypalDetailsBatchJob.schedule('Paypal Details Batch Job 5 min', '0 5 0/1 1/1 * ? *');
HistoricalTransactionProcessingJob.schedule('Historical Transaction Processing Job 10 min', '0 10 0/1 1/1 * ? *');

HistoricalTransactionFetchJob.schedule('Paypal', 'Historical Transaction Fetch Job 20 min', '0 20 0/1 1/1 * ? *');
PaypalDetailsBatchJob.schedule('Paypal Details Batch Job 25 min', '0 25 0/1 1/1 * ? *');
HistoricalTransactionProcessingJob.schedule('Historical Transaction Processing Job 30 min', '0 30 0/1 1/1 * ? *');

HistoricalTransactionFetchJob.schedule('Paypal', 'Historical Transaction Fetch Job 40 min', '0 40 0/1 1/1 * ? *');
PaypalDetailsBatchJob.schedule('Paypal Details Batch Job 45 min', '0 45 0/1 1/1 * ? *');
HistoricalTransactionProcessingJob.schedule('Historical Transaction Processing Job 50 min', '0 50 0/1 1/1 * ? *');

*/