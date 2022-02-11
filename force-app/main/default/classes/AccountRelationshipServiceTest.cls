@isTest
private class AccountRelationshipServiceTest {
  @isTest static void testInsert() {
    Account acct1 = new Account();
    acct1.Name = 'Test 1';
    insert acct1;

    Account acct2 = new Account();
    acct2.Name = 'Test 2';
    insert acct2;

    Test.startTest();

    Account_Relationship__c rel = new Account_Relationship__c();
    rel.Account__c = acct1.Id;
    rel.Related_Account__c = acct2.Id;
    rel.Status__c = 'Current';
    rel.Type__c = 'Coalition';
    rel.Start_Date__c = Date.today();
    insert rel;

    List<Account_Relationship__c> rels = [SELECT Id, Account__c, Related_Account__c, Status__c, Type__c FROM Account_Relationship__c];
    System.assertEquals(2, rels.size());

    Test.stopTest();
  }

  @isTest static void testUpdate() {
    Account acct1 = new Account();
    acct1.Name = 'Test 1';
    insert acct1;

    Account acct2 = new Account();
    acct2.Name = 'Test 2';
    insert acct2;

    Account_Relationship__c rel = new Account_Relationship__c();
    rel.Account__c = acct1.Id;
    rel.Related_Account__c = acct2.Id;
    rel.Status__c = 'Current';
    rel.Type__c = 'Coalition';
    rel.Start_Date__c = Date.today();
    insert rel;

    Test.startTest();

    rel.Status__c = 'Former';
    update rel;

    List<Account_Relationship__c> rels = [SELECT Id, Account__c, Related_Account__c, Status__c, Type__c FROM Account_Relationship__c];
    System.assertEquals(2, rels.size());
    for (Account_Relationship__c r : rels) {
      System.assertEquals('Former', r.Status__c);
    }

    rel.Related_Account__c = null;
    update rel;
    rels = [SELECT Id, Account__c, Related_Account__c, Status__c, Type__c FROM Account_Relationship__c];
    System.assertEquals(0, rels.size());

    Test.stopTest();
  }

  @isTest static void testDelete() {
    Account acct1 = new Account();
    acct1.Name = 'Test 1';
    insert acct1;

    Account acct2 = new Account();
    acct2.Name = 'Test 2';
    insert acct2;

    Account_Relationship__c rel = new Account_Relationship__c();
    rel.Account__c = acct1.Id;
    rel.Related_Account__c = acct2.Id;
    rel.Status__c = 'Current';
    rel.Type__c = 'Coalition';
    rel.Start_Date__c = Date.today();
    insert rel;

    Test.startTest();

    delete rel;
    List<Account_Relationship__c> rels = [SELECT Id, Account__c, Related_Account__c, Status__c, Type__c FROM Account_Relationship__c];
    System.assertEquals(0, rels.size());

    Test.stopTest();
  }
}