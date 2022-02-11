public class CurrencyExchangeRateFetchJob implements Schedulable {

  // Execute method called when the scheduled job runs. This will call the fetcher class.
  public void execute(SchedulableContext sc) {
    System.enqueueJob(new CurrencyExchangeRateFetcher());
  }

  // Utility method for scheduling this apex job.
  public static String schedule(String jobName, String cron) {
    if (String.isBlank(jobName)) jobName = 'Currency Exchange Rate Fetch Job';
    if (String.isBlank(cron)) cron = '0 0 17 * * ?'; // Everyday @ 5 PM
    return System.schedule(jobName, cron, new CurrencyExchangeRateFetchJob());
  }
}