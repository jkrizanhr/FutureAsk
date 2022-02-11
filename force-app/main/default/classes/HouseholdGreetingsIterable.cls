global class HouseholdGreetingsIterable implements Iterable<AggregateResult> {
  private String query;

  global HouseholdGreetingsIterable(String query) {
    this.query = query;
  }

  global Iterator<AggregateResult> Iterator() {
    return new HouseholdGreetingIterator(this.query);
  }
}