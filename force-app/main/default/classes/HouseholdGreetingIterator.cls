global class HouseholdGreetingIterator implements Iterator<AggregateResult> {
  String query {get; set;}
  AggregateResult[] results { get; set; }
  Integer index { get; set; }

  global HouseholdGreetingIterator(String query) {
    this.query = query;
    if (this.query == null) {
      query = 'SELECT AccountId, count(Id) FROM Contact WHERE Gender__c != null OR Salutation IN (\'Mr.\', \'Mrs.\', \'Ms.\', \'Miss\') GROUP BY AccountId HAVING count(Id) > 1';
    }
    results = Database.query(query);
    index = 0;
  }

  global boolean hasNext() {
    return results != null && !results.isEmpty() && index < results.size();
  }

  global AggregateResult next() {
    return results[index++];
  }
}