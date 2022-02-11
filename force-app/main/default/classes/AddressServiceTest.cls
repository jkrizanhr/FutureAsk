@isTest
private class AddressServiceTest {
  
  @isTest
  static void testSetAddressOnAccount() {
    Account acct = new Account();
    acct.Name = 'Test Account';
    acct.BillingStreet = '123 Test Street';
    acct.BillingState = 'PA';
    acct.BillingCity = 'Annville';
    acct.BillingPostalCode = '17003';
    acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household Account').getRecordTypeId();
    insert acct;

    npsp__Address__c address = new npsp__Address__c();
    address.npsp__Household_Account__c = acct.Id;
    address.npsp__Default_Address__c = true;
    address.npsp__MailingCity__c = 'Annville';
    address.npsp__MailingCountry__c = 'USA';
    address.npsp__MailingState__c = 'PA';
    address.npsp__MailingStreet__c = '123 Test Street';
    address.npsp__MailingPostalCode__c = '17003';
    address.npsp__Verified__c = true;
    insert address;

    Contact c = new Contact();
    c.LastName = 'TestContact';
    c.AccountId = acct.Id;
    c.MailingStreet = '123 Test Street';
    c.MailingState = 'PA';
    c.MailingCity = 'Annville';
    c.MailingPostalCode = '17003';
    c.npsp__Current_Address__c = address.Id;
    insert c;

    Account res = [SELECT Id, Address__c FROM Account WHERE Id = :acct.Id];

    System.assertNotEquals(null, res.Address__c);
  }
}