// System.schedule('Household Greeting', '0 0 23 1/1 * ? *', new householdGreetingsJob());
global without sharing class householdGreetingsJob implements Database.Batchable<AggregateResult>, Schedulable {
  private String query;

  global void execute(System.SchedulableContext sc) {
    Database.executebatch(new householdGreetingsJob(null));
  }

  global householdGreetingsJob(String query) {
    this.query = query;
  }

  global Iterable<AggregateResult> start(Database.BatchableContext bc) {
    return new HouseholdGreetingsIterable(query);
  }

  global void execute(Database.BatchableContext bc, List<AggregateResult> results) {
    HouseholdGreetingsService.updateNamingOrder(results);
  }

  global void finish(Database.BatchableContext bc) {
  }
}