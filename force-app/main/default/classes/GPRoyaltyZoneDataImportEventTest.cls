@IsTest
private class GPRoyaltyZoneDataImportEventTest {
  @TestSetup
  private static void makeData() {
    // Insert the default custom setting for all tests.
    Resource_Order_Name__c testResourceOrderName = new Resource_Order_Name__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      Counter__c = 0
    );
    insert testResourceOrderName;
  }

  /**
   * Utility method to retrieve account results
   */
  private static List<Account> fetchAccounts() {
    return [
      SELECT
        AccountSource,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingPostalCode,
        Id,
        Name,
        npe01__One2OneContact__c,
        Phone,
        RecordType.Name
      FROM Account
      ORDER BY Id
    ];
  }

  /**
   * Utility method to retrieve contact results
   */
  private static List<Contact> fetchContacts() {
    return [
      SELECT
        AccountId,
        Email,
        FirstName,
        Id,
        LastName,
        LeadSource,
        MailingStreet,
        MailingCity,
        MailingState,
        MailingPostalCode,
        npe01__WorkEmail__c,
        npe01__WorkPhone__c,
        npe01__Preferred_Email__c,
        npe01__PreferredPhone__c,
        npsp__Primary_Affiliation__c,
        Phone
      FROM Contact
    ];
  }

  /**
   * Utility method to retrieve resource order results
   */
  private static List<Resource_Order__c> fetchResourceOrders() {
    return [
      SELECT
        Account__c,
        Agreement__c,
        Contact__c,
        // Country__c,
        Currency__c,
        GP_Order_Total__c,
        Id,
        Invoice_Date__c,
        Invoice_Id__c,
        Name,
        Order_Id__c,
        RecordType.Name,
        Submitted_Date__c
      FROM Resource_Order__c
    ];
  }

  /**
   * Utility method to retrieve resource order item results
   */
  private static List<Resource_Order_Item__c> fetchResourceOrderItems() {
    return [
      SELECT
        Amount__c,
        GP_Item_Name__c,
        Id,
        Order_Item_Id__c,
        Resource__c,
        Resource_Order__c,
        Quantity__c
      FROM Resource_Order_Item__c
    ];
  }

  private static List<Country__c> fetchCountries() {
    return [SELECT Country__c, Id, Resource_Order_Item__c FROM Country__c];
  }

  /**
   * Utility method to retrieve platform event error results
   */
  private static List<Platform_Event_Error__c> fetchPlatformEventErrors() {
    return [SELECT Data__c, Error__c, Origin__c FROM Platform_Event_Error__c];
  }

  @IsTest
  static void testNewCustomer() {
    Resource__c resource = new Resource__c();
    resource.Name = 'Royalty Payment';
    resource.GP_Resource_Name__c = 'Royalty Payment';
    resource.ISBN__c = '1234';
    insert resource;

    Agreement__c agreement = new Agreement__c();
    agreement.RoyaltyZone_Agreement_Name__c = 'Test Agreement';
    insert agreement;

    GP_Royalty_Zone_Data_Import_Event__e event = new GP_Royalty_Zone_Data_Import_Event__e();
    event.Data__c = '{"Customer Name":"Test Organization","Billing Contact First Name":"Test","Billing Contact Last Name":"Contact","Email":"test@example.com","Phone":"1231231234","Billing Street":"123 Test St","Billing City":"Test City","Billing State":"NY","Billing Postal Code":"12345","Billing Country":"United States","Customer ID":"R-EEM","Agreement Name":"Test Agreement","Transaction ID":"123456","Invoice ID":"RZ-0001234","Transaction Date":"2019-11-27T00:00:00.000Z","Amount":1000.000,"Payment Method":"Check","Invoice Date":"2019-11-27T00:00:00.000Z","Currency":"USD","Country":"Austria"}';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Account> accounts = fetchAccounts();
    List<Contact> contacts = fetchContacts();
    List<Resource_Order__c> resourceOrders = fetchResourceOrders();
    List<Resource_Order_Item__c> resourceOrderItems = fetchResourceOrderItems();
    List<Country__c> countries = fetchCountries();
    List<Platform_Event_Error__c> platformEventErrors = fetchPlatformEventErrors();

    System.assertEquals(2, accounts.size());
    System.assertEquals(1, contacts.size());
    System.assertEquals(1, resourceOrders.size());
    System.assertEquals(1, resourceOrderItems.size());
    System.assertEquals(1, countries.size());
    System.assertEquals(0, platformEventErrors.size());

    System.assertEquals('Organization', accounts[0].RecordType.Name);
    System.assertEquals('Great Plains', accounts[0].AccountSource);
    System.assertEquals('Test Organization', accounts[0].Name);
    System.assertEquals('123 Test St', accounts[0].BillingStreet);
    System.assertEquals('Test City', accounts[0].BillingCity);
    System.assertEquals('NY', accounts[0].BillingState);
    System.assertEquals('12345', accounts[0].BillingPostalCode);
    System.assertEquals('1231231234', accounts[0].Phone);
    System.assertEquals('Household Account', accounts[1].RecordType.Name);
    System.assertEquals(contacts[0].Id, accounts[0].npe01__One2OneContact__c);
    System.assertEquals(contacts[0].Id, accounts[1].npe01__One2OneContact__c);

    System.assertEquals(accounts[0].Id, contacts[0].npsp__Primary_Affiliation__c);
    System.assertEquals(accounts[1].Id, contacts[0].AccountId);
    System.assertEquals('Great Plains', contacts[0].LeadSource);
    System.assertEquals('Test', contacts[0].FirstName);
    System.assertEquals('Contact', contacts[0].LastName);
    System.assertEquals('123 Test St', contacts[0].MailingStreet);
    System.assertEquals('Test City', contacts[0].MailingCity);
    System.assertEquals('NY', contacts[0].MailingState);
    System.assertEquals('12345', contacts[0].MailingPostalCode);
    System.assertEquals('1231231234', contacts[0].Phone);
    System.assertEquals('test@example.com', contacts[0].Email);
    System.assertEquals('Work', contacts[0].npe01__Preferred_Email__c);
    System.assertEquals('Work', contacts[0].npe01__PreferredPhone__c);
    System.assertEquals('test@example.com', contacts[0].npe01__WorkEmail__c);
    System.assertEquals('1231231234', contacts[0].npe01__WorkPhone__c);

    System.assertEquals(agreement.Id, resourceOrders[0].Agreement__c);
    System.assertEquals('RZ-0001234', resourceOrders[0].Invoice_Id__c);
    System.assertEquals(Date.newInstance(2019, 11, 27), resourceOrders[0].Invoice_Date__c);

    System.assertEquals(accounts[0].Id, resourceOrders[0].Account__c);
    System.assertEquals(contacts[0].Id, resourceOrders[0].Contact__c);
    System.assertEquals('USD', resourceOrders[0].Currency__c);
    System.assertEquals(1000, resourceOrders[0].GP_Order_Total__c);
    // System.assertEquals('Test Organization - 11/27/2019', resourceOrders[0].Name); // Set in a workflow
    System.assertEquals('123456', resourceOrders[0].Order_Id__c);
    System.assertEquals('Royalty Payment', resourceOrders[0].RecordType.Name);
    System.assertEquals(Date.newInstance(2019, 11, 27), resourceOrders[0].Submitted_Date__c);

    System.assertEquals(1000, resourceOrderItems[0].Amount__c);
    System.assertEquals(null, resourceOrderItems[0].GP_Item_Name__c);
    System.assertEquals('123456:RZ-0001234', resourceOrderItems[0].Order_Item_Id__c);
    System.assertEquals(resource.Id, resourceOrderItems[0].Resource__c);
    System.assertEquals(resourceOrders[0].Id, resourceOrderItems[0].Resource_Order__c);
    System.assertEquals(null, resourceOrderItems[0].Quantity__c);

    System.assertEquals(resourceOrderItems[0].Id, countries[0].Resource_Order_Item__c);
    System.assertEquals('Austria', countries[0].Country__c);
  }

  @IsTest
  static void testExistingCustomerOrder() {
    Resource__c resource = new Resource__c();
    resource.Name = 'Royalty Payment';
    resource.ISBN__c = '1234';
    insert resource;

    Agreement__c agreement = new Agreement__c();
    agreement.RoyaltyZone_Agreement_Name__c = 'Test Agreement';
    insert agreement;

    Account account = new Account();
    account.Name = 'Test Organization';
    account.RecordTypeId = Utils.getRecordTypeId('Account', 'Organization');
    account.GP_Customer_Id__c = 'R-EEM';
    insert account;

    Contact contact = new Contact();
    Contact.LastName = 'Contact';
    contact.GP_Customer_Id__c = 'R-EEM';
    insert contact;

    Resource_Order__c resourceOrder = new Resource_Order__c();
    resourceOrder.Account__c = account.Id;
    resourceOrder.Order_Id__c = '123456';
    resourceOrder.RecordTypeId = Utils.getRecordTypeId('Resource_Order__c', 'Royalty Payment');
    resourceOrder.Submitted_Date__c = Date.today();
    insert resourceOrder;

    GP_Royalty_Zone_Data_Import_Event__e event = new GP_Royalty_Zone_Data_Import_Event__e();
    event.Data__c = '{"Customer Name":"Test Organization","Billing Contact First Name":"Test","Billing Contact Last Name":"Contact","Email":"test@example.com","Phone":"1231231234","Billing Street":"123 Test St","Billing City":"Test City","Billing State":"NY","Billing Postal Code":"12345","Billing Country":"United States","Customer ID":"R-EEM","Agreement Name":"Test Agreement","Transaction ID":"123456","Invoice ID":"RZ-0001234","Transaction Date":"2019-11-27T00:00:00.000Z","Amount":1000.000,"Payment Method":"Check","Invoice Date":"2019-11-27T00:00:00.000Z","Currency":"USD","Country":"Austria"}';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Account> accounts = fetchAccounts();
    List<Contact> contacts = fetchContacts();
    List<Resource_Order__c> resourceOrders = fetchResourceOrders();
    List<Resource_Order_Item__c> resourceOrderItems = fetchResourceOrderItems();
    List<Country__c> countries = fetchCountries();
    List<Platform_Event_Error__c> platformEventErrors = fetchPlatformEventErrors();

    System.assertEquals(2, accounts.size());
    System.assertEquals(1, contacts.size());
    System.assertEquals(1, resourceOrders.size());
    System.assertEquals(1, resourceOrderItems.size());
    System.assertEquals(0, platformEventErrors.size());

    System.assertEquals('Organization', accounts[0].RecordType.Name);
    System.assertEquals('Test Organization', accounts[0].Name);
    System.assertEquals(null, accounts[0].AccountSource);
    System.assertEquals('123 Test St', accounts[0].BillingStreet);
    System.assertEquals('Test City', accounts[0].BillingCity);
    System.assertEquals('NY', accounts[0].BillingState);
    System.assertEquals('12345', accounts[0].BillingPostalCode);
    System.assertEquals('1231231234', accounts[0].Phone);
    System.assertEquals('Household Account', accounts[1].RecordType.Name);

    System.assertEquals(accounts[1].Id, contacts[0].AccountId);
    System.assertEquals(accounts[0].Id, contacts[0].npsp__Primary_Affiliation__c);
    System.assertEquals('Test', contacts[0].FirstName);
    System.assertEquals('Contact', contacts[0].LastName);
    System.assertEquals('123 Test St', contacts[0].MailingStreet);
    System.assertEquals('Test City', contacts[0].MailingCity);
    System.assertEquals('NY', contacts[0].MailingState);
    System.assertEquals('12345', contacts[0].MailingPostalCode);
    System.assertEquals('1231231234', contacts[0].Phone);
    System.assertEquals('test@example.com', contacts[0].Email);
    System.assertEquals('Work', contacts[0].npe01__Preferred_Email__c);
    System.assertEquals('Work', contacts[0].npe01__PreferredPhone__c);
    System.assertEquals('test@example.com', contacts[0].npe01__WorkEmail__c);
    System.assertEquals('1231231234', contacts[0].npe01__WorkPhone__c);

    System.assertEquals(agreement.Id, resourceOrders[0].Agreement__c);
    System.assertEquals('RZ-0001234', resourceOrders[0].Invoice_Id__c);
    System.assertEquals(Date.newInstance(2019, 11, 27), resourceOrders[0].Invoice_Date__c);

    System.assertEquals(resourceOrder.Id, resourceOrders[0].Id);
    System.assertEquals(accounts[0].Id, resourceOrders[0].Account__c);
    System.assertEquals(contacts[0].Id, resourceOrders[0].Contact__c);
    System.assertEquals('USD', resourceOrders[0].Currency__c);
    System.assertEquals(1000, resourceOrders[0].GP_Order_Total__c);
    // System.assertEquals('Test Organization - 11/27/2019', resourceOrders[0].Name); // Set in a workflow
    System.assertEquals('123456', resourceOrders[0].Order_Id__c);
    System.assertEquals('Royalty Payment', resourceOrders[0].RecordType.Name);
    System.assertEquals(Date.newInstance(2019, 11, 27), resourceOrders[0].Submitted_Date__c);

    System.assertEquals(1000, resourceOrderItems[0].Amount__c);
    System.assertEquals(null, resourceOrderItems[0].GP_Item_Name__c);
    System.assertEquals('123456:RZ-0001234', resourceOrderItems[0].Order_Item_Id__c);
    System.assertEquals(resource.Id, resourceOrderItems[0].Resource__c);
    System.assertEquals(resourceOrders[0].Id, resourceOrderItems[0].Resource_Order__c);
    System.assertEquals(null, resourceOrderItems[0].Quantity__c);

    System.assertEquals(resourceOrderItems[0].Id, countries[0].Resource_Order_Item__c);
    System.assertEquals('Austria', countries[0].Country__c);
  }

  @IsTest
  static void testRoyaltyPaymentResourceNotFound() {
    Resource__c resource = new Resource__c();
    resource.Name = 'Test Resource';
    resource.Resource_Id__c = '123-9876';
    resource.ISBN__c = '1234';
    insert resource;

    Agreement__c agreement = new Agreement__c();
    agreement.RoyaltyZone_Agreement_Name__c = 'Test Agreement';
    insert agreement;

    GP_Royalty_Zone_Data_Import_Event__e event = new GP_Royalty_Zone_Data_Import_Event__e();
    event.Data__c = '{"Customer Name":"Test Organization","Billing Contact First Name":"Test","Billing Contact Last Name":"Contact","Email":"test@example.com","Phone":"1231231234","Billing Street":"123 Test St","Billing City":"Test City","Billing State":"NY","Billing Postal Code":"12345","Billing Country":"United States","Customer ID":"R-EEM","Agreement Name":"Test Agreement","Transaction ID":"123456","Invoice ID":"RZ-0001234","Transaction Date":"2019-11-27T00:00:00.000Z","Amount":1000.000,"Payment Method":"Check","Invoice Date":"2019-11-27T00:00:00.000Z","Currency":"USD","Country":"Austria"}';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Account> accounts = fetchAccounts();
    List<Contact> contacts = fetchContacts();
    List<Resource_Order__c> resourceOrders = fetchResourceOrders();
    List<Resource_Order_Item__c> resourceOrderItems = fetchResourceOrderItems();
    List<Country__c> countries = fetchCountries();
    List<Platform_Event_Error__c> platformEventErrors = fetchPlatformEventErrors();

    System.assertEquals(0, accounts.size());
    System.assertEquals(0, contacts.size());
    System.assertEquals(0, resourceOrders.size());
    System.assertEquals(0, resourceOrderItems.size());
    System.assertEquals(0, countries.size());
    System.assertEquals(1, platformEventErrors.size());
    System.assertEquals(event.Data__c, platformEventErrors[0].Data__c);
    System.assert(platformEventErrors[0].Error__c.contains('Resource record not found.'));
    System.assertEquals('NJE_RoyaltyZone', platformEventErrors[0].Origin__c);
  }
}