trigger AddressTrigger on npsp__Address__c (after insert, after update) {
  new AddressTriggerHandler().run();
}