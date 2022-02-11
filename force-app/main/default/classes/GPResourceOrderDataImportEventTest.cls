@IsTest
private class GPResourceOrderDataImportEventTest {
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
        Contact__c,
        Currency__c,
        GP_Order_Total__c,
        Id,
        Name,
        Order_Id__c,
        RecordType.Name,
        Status__c,
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
        Quantity__c,
        Status__c
      FROM Resource_Order_Item__c
    ];
  }

  /**
   * Utility method to retrieve platform event error results
   */
  private static List<Platform_Event_Error__c> fetchPlatformEventErrors() {
    return [SELECT Data__c, Error__c, Origin__c FROM Platform_Event_Error__c];
  }

  /**
   * Test for all new customer data
   * Test for IN-GR Grant Order
   */
  @IsTest
  static void testNewCustomer() {
    Resource__c resource = new Resource__c();
    resource.Name = 'Test Resource';
    resource.Resource_Id__c = '123-9876';
    resource.ISBN__c = '1234';
    insert resource;

    GP_Resource_Order_Data_Import_Event__e event = new GP_Resource_Order_Data_Import_Event__e();
    event.Data__c = '{"Customer Name":"Test Organization","Billing Contact First Name":"Test","Billing Contact Last Name":"Contact","Email":"test@example.com","Phone":"1231231234","Billing Street":"123 Test St","Billing City":"Test City","Billing State":"NY","Billing Postal Code":"12345","Billing Country":"United States","Customer ID":"123-456","Transaction ID":"IN-GR12345","Transaction Date":"2019-11-27T00:00:00.000Z","Order Total":1000.000,"Item Amount":10.000,"Item Name":"Test Item","Item ID":"123-9876","Item Quantity":100.000,"Payment Method":"Check","Check Number":"9876","Currency":"USD"}';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Account> accounts = fetchAccounts();
    List<Contact> contacts = fetchContacts();
    List<Resource_Order__c> resourceOrders = fetchResourceOrders();
    List<Resource_Order_Item__c> resourceOrderItems = fetchResourceOrderItems();
    List<Platform_Event_Error__c> platformEventErrors = fetchPlatformEventErrors();

    System.assertEquals(2, accounts.size());
    System.assertEquals(1, contacts.size());
    System.assertEquals(1, resourceOrders.size());
    System.assertEquals(1, resourceOrderItems.size());
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

    System.assertEquals(accounts[0].Id, resourceOrders[0].Account__c);
    System.assertEquals(contacts[0].Id, resourceOrders[0].Contact__c);
    System.assertEquals('USD', resourceOrders[0].Currency__c);
    System.assertEquals(1000, resourceOrders[0].GP_Order_Total__c);
    // System.assertEquals('Test Organization - 11/27/2019', resourceOrders[0].Name); // Set by a workflow
    System.assertEquals('IN-GR12345', resourceOrders[0].Order_Id__c);
    System.assertEquals('Standard Order', resourceOrders[0].RecordType.Name);
    System.assertEquals('Final Invoice and Payment', resourceOrders[0].Status__c);
    System.assertEquals(Date.newInstance(2019, 11, 27), resourceOrders[0].Submitted_Date__c);

    System.assertEquals(10, resourceOrderItems[0].Amount__c);
    System.assertEquals('Test Item', resourceOrderItems[0].GP_Item_Name__c);
    System.assertEquals('IN-GR12345:123-9876', resourceOrderItems[0].Order_Item_Id__c);
    System.assertEquals(resource.Id, resourceOrderItems[0].Resource__c);
    System.assertEquals(resourceOrders[0].Id, resourceOrderItems[0].Resource_Order__c);
    System.assertEquals(100, resourceOrderItems[0].Quantity__c);
    System.assertEquals('Shipped', resourceOrderItems[0].Status__c);
  }

  @IsTest
  static void testContactAccountNameMatch() {
    Resource__c resource = new Resource__c();
    resource.Name = 'Test Resource';
    resource.Resource_Id__c = '123-9876';
    resource.ISBN__c = '1234';
    insert resource;

    GP_Resource_Order_Data_Import_Event__e event = new GP_Resource_Order_Data_Import_Event__e();
    event.Data__c = '{"Customer Name":"Test Organization","Billing Contact First Name":"Test","Billing Contact Last Name":"Organization","Email":"test@example.com","Phone":"1231231234","Billing Street":"123 Test St","Billing City":"Test City","Billing State":"NY","Billing Postal Code":"12345","Billing Country":"United States","Customer ID":"123-456","Transaction ID":"IN-GR12345","Transaction Date":"2019-11-27T00:00:00.000Z","Order Total":1000.000,"Item Amount":10.000,"Item Name":"Test Item","Item ID":"123-9876","Item Quantity":100.000,"Payment Method":"Check","Check Number":"9876","Currency":"USD"}';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Account> accounts = fetchAccounts();
    List<Contact> contacts = fetchContacts();
    List<Resource_Order__c> resourceOrders = fetchResourceOrders();
    List<Resource_Order_Item__c> resourceOrderItems = fetchResourceOrderItems();
    List<Platform_Event_Error__c> platformEventErrors = fetchPlatformEventErrors();

    System.assertEquals(1, accounts.size());
    System.assertEquals(0, contacts.size());
    System.assertEquals(1, resourceOrders.size());
    System.assertEquals(1, resourceOrderItems.size());
    System.assertEquals(0, platformEventErrors.size());

    System.assertEquals('Organization', accounts[0].RecordType.Name);
    System.assertEquals('Great Plains', accounts[0].AccountSource);
    System.assertEquals('Test Organization', accounts[0].Name);
    System.assertEquals('123 Test St', accounts[0].BillingStreet);
    System.assertEquals('Test City', accounts[0].BillingCity);
    System.assertEquals('NY', accounts[0].BillingState);
    System.assertEquals('12345', accounts[0].BillingPostalCode);
    System.assertEquals('1231231234', accounts[0].Phone);
    System.assertEquals(null, accounts[0].npe01__One2OneContact__c);

    System.assertEquals(accounts[0].Id, resourceOrders[0].Account__c);
    System.assertEquals(null, resourceOrders[0].Contact__c);
    System.assertEquals('USD', resourceOrders[0].Currency__c);
    System.assertEquals(1000, resourceOrders[0].GP_Order_Total__c);
    // System.assertEquals('Test Organization - 11/27/2019', resourceOrders[0].Name); // Set by a workflow
    System.assertEquals('IN-GR12345', resourceOrders[0].Order_Id__c);
    System.assertEquals('Standard Order', resourceOrders[0].RecordType.Name);
    System.assertEquals('Final Invoice and Payment', resourceOrders[0].Status__c);
    System.assertEquals(Date.newInstance(2019, 11, 27), resourceOrders[0].Submitted_Date__c);

    System.assertEquals(10, resourceOrderItems[0].Amount__c);
    System.assertEquals('Test Item', resourceOrderItems[0].GP_Item_Name__c);
    System.assertEquals('IN-GR12345:123-9876', resourceOrderItems[0].Order_Item_Id__c);
    System.assertEquals(resource.Id, resourceOrderItems[0].Resource__c);
    System.assertEquals(resourceOrders[0].Id, resourceOrderItems[0].Resource_Order__c);
    System.assertEquals(100, resourceOrderItems[0].Quantity__c);
    System.assertEquals('Shipped', resourceOrderItems[0].Status__c);
  }

  /**
   * Test for existing customer order
   * Test for IN-SL Order
   */
  @IsTest
  static void testExistingCustomerOrder() {
    Resource__c resource = new Resource__c();
    resource.Name = 'Test Resource';
    resource.Resource_Id__c = '123-9876';
    resource.ISBN__c = '1234';
    insert resource;

    Account account = new Account();
    account.Name = 'Test Organization';
    account.RecordTypeId = Utils.getRecordTypeId('Account', 'Organization');
    account.GP_Customer_Id__c = '123-456';
    insert account;

    Contact contact = new Contact();
    Contact.LastName = 'Contact';
    contact.GP_Customer_Id__c = '123-456';
    insert contact;

    Resource_Order__c resourceOrder = new Resource_Order__c();
    resourceOrder.Account__c = account.Id;
    resourceOrder.Order_Id__c = 'IN-SL12345';
    resourceOrder.RecordTypeId = Utils.getRecordTypeId('Resource_Order__c', 'Standard Order');
    resourceOrder.Submitted_Date__c = Date.today();
    insert resourceOrder;

    Resource_Order_Item__c resourceOrderItem = new Resource_Order_Item__c();
    resourceOrderItem.Amount__c = 10;
    resourceOrderItem.Quantity__c = 90;
    resourceOrderItem.GP_Item_Name__c = 'Test Item';
    resourceOrderItem.Order_Item_Id__c = 'IN-SL12345:123-9876';
    resourceOrderItem.Resource__c = resource.Id;
    resourceOrderItem.Resource_Order__c = resourceOrder.Id;
    insert resourceOrderItem;

    resourceOrder.Advance_without_Roles__c = true;
    resourceOrder.Status__c = 'Final Invoice and Payment';
    update resourceOrder;

    GP_Resource_Order_Data_Import_Event__e event = new GP_Resource_Order_Data_Import_Event__e();
    event.Data__c = '{"Customer Name":"Test Organization","Billing Contact First Name":"Test","Billing Contact Last Name":"Contact","Email":"test@example.com","Phone":"1231231234","Billing Street":"123 Test St","Billing City":"Test City","Billing State":"NY","Billing Postal Code":"12345","Billing Country":"United States","Customer ID":"123-456","Transaction ID":"IN-SL12345","Transaction Date":"2019-11-27T00:00:00.000Z","Order Total":1000.000,"Item Amount":10.000,"Item Name":"Test Item","Item ID":"123-9876","Item Quantity":100.000,"Payment Method":"Check","Check Number":"9876","Currency":"USD"}';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Account> accounts = fetchAccounts();
    List<Contact> contacts = fetchContacts();
    List<Resource_Order__c> resourceOrders = fetchResourceOrders();
    List<Resource_Order_Item__c> resourceOrderItems = fetchResourceOrderItems();
    List<Platform_Event_Error__c> platformEventErrors = fetchPlatformEventErrors();

    System.assertEquals(2, accounts.size());
    System.assertEquals(1, contacts.size());
    System.assertEquals(1, resourceOrders.size());
    System.assertEquals(1, resourceOrderItems.size());
    System.assertEquals(0, platformEventErrors.size());

    System.assertEquals('Organization', accounts[0].RecordType.Name);
    System.assertEquals('Test Organization', accounts[0].Name);
    System.assertNotEquals('Great Plains', accounts[0].AccountSource);
    System.assertEquals('123 Test St', accounts[0].BillingStreet);
    System.assertEquals('Test City', accounts[0].BillingCity);
    System.assertEquals('NY', accounts[0].BillingState);
    System.assertEquals('12345', accounts[0].BillingPostalCode);
    System.assertEquals('1231231234', accounts[0].Phone);
    System.assertEquals('Household Account', accounts[1].RecordType.Name);
    System.assertEquals(contacts[0].Id, accounts[0].npe01__One2OneContact__c);
    System.assertEquals(contacts[0].Id, accounts[1].npe01__One2OneContact__c);

    System.assertEquals(accounts[1].Id, contacts[0].AccountId);
    System.assertEquals(accounts[0].Id, contacts[0].npsp__Primary_Affiliation__c);
    System.assertEquals('Test', contacts[0].FirstName);
    System.assertEquals('Contact', contacts[0].LastName);
    System.assertNotEquals('Great Plains', contacts[0].LeadSource);
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

    System.assertEquals(resourceOrder.Id, resourceOrders[0].Id);
    System.assertEquals(accounts[0].Id, resourceOrders[0].Account__c);
    System.assertEquals(contacts[0].Id, resourceOrders[0].Contact__c);
    System.assertEquals('USD', resourceOrders[0].Currency__c);
    // System.assertEquals('Test Organization - 11/27/2019', resourceOrders[0].Name); // Set by a workflow
    System.assertEquals(1000, resourceOrders[0].GP_Order_Total__c);
    System.assertEquals('IN-SL12345', resourceOrders[0].Order_Id__c);
    System.assertEquals('Standard Order', resourceOrders[0].RecordType.Name);
    System.assertEquals('Final Invoice and Payment', resourceOrders[0].Status__c);
    System.assertEquals(Date.newInstance(2019, 11, 27), resourceOrders[0].Submitted_Date__c);

    System.assertEquals(resourceOrderItem.Id, resourceOrderItems[0].Id);
    System.assertEquals(10, resourceOrderItems[0].Amount__c);
    System.assertEquals('Test Item', resourceOrderItems[0].GP_Item_Name__c);
    System.assertEquals('IN-SL12345:123-9876', resourceOrderItems[0].Order_Item_Id__c);
    System.assertEquals(resource.Id, resourceOrderItems[0].Resource__c);
    System.assertEquals(resourceOrders[0].Id, resourceOrderItems[0].Resource_Order__c);
    System.assertEquals(100, resourceOrderItems[0].Quantity__c);
  }

  /**
   * Test that the Id is cleared if the existing account record found in the duplicate matching
   * already has a GP Customer Id that does not match what is being imported. This is to ensure
   * that existing GP Customer Ids are not overwritten on accounts and contacts.
   *
   * Also test that the phone number is cleaned up and the additional four zeroes are removed.
   */
  @IsTest
  static void testExistingAccount() {
    Resource__c resource = new Resource__c();
    resource.Name = 'Test Resource';
    resource.Resource_Id__c = '123-9876';
    resource.ISBN__c = '1234';
    insert resource;

    Account account = new Account();
    account.Name = 'Test Organization';
    account.RecordTypeId = Utils.getRecordTypeId('Account', 'Organization');
    account.GP_Customer_Id__c = '321-456';
    account.BillingStreet = '123 Test St';
    insert account;

    GP_Resource_Order_Data_Import_Event__e event = new GP_Resource_Order_Data_Import_Event__e();
    event.Data__c = '{"Customer Name":"Test Organization","Billing Contact First Name":"Test","Billing Contact Last Name":"Contact","Email":"test@example.com","Phone":"12312312340000","Billing Street":"123 Test St","Billing City":"Test City","Billing State":"NY","Billing Postal Code":"12345","Billing Country":"United States","Customer ID":"123-456","Transaction ID":"IN-SL12345","Transaction Date":"2019-11-27T00:00:00.000Z","Order Total":1000.000,"Item Amount":10.000,"Item Name":"Test Item","Item ID":"123-9876","Item Quantity":100.000,"Payment Method":"Check","Check Number":"9876","Currency":"USD"}';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Account> accounts = fetchAccounts();
    List<Contact> contacts = fetchContacts();
    List<Resource_Order__c> resourceOrders = fetchResourceOrders();
    List<Resource_Order_Item__c> resourceOrderItems = fetchResourceOrderItems();
    List<Platform_Event_Error__c> platformEventErrors = fetchPlatformEventErrors();

    System.assertEquals(3, accounts.size());
    System.assertEquals(1, contacts.size());
    System.assertEquals(1, resourceOrders.size());
    System.assertEquals(1, resourceOrderItems.size());
    System.assertEquals(0, platformEventErrors.size());

    System.assertEquals(account.Id, accounts[0].Id);

    System.assertEquals('Organization', accounts[1].RecordType.Name);
    System.assertEquals('Test Organization', accounts[1].Name);
    System.assertEquals('Great Plains', accounts[1].AccountSource);
    System.assertEquals('123 Test St', accounts[1].BillingStreet);
    System.assertEquals('Test City', accounts[1].BillingCity);
    System.assertEquals('NY', accounts[1].BillingState);
    System.assertEquals('12345', accounts[1].BillingPostalCode);
    System.assertEquals('1231231234', accounts[1].Phone);
    System.assertEquals('Household Account', accounts[2].RecordType.Name);
    System.assertEquals(contacts[0].Id, accounts[1].npe01__One2OneContact__c);
    System.assertEquals(contacts[0].Id, accounts[2].npe01__One2OneContact__c);

    System.assertEquals(accounts[2].Id, contacts[0].AccountId);
    System.assertEquals(accounts[1].Id, contacts[0].npsp__Primary_Affiliation__c);
    System.assertEquals('Test', contacts[0].FirstName);
    System.assertEquals('Contact', contacts[0].LastName);
    System.assertEquals('Great Plains', contacts[0].LeadSource);
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

    System.assertEquals(accounts[1].Id, resourceOrders[0].Account__c);
    System.assertEquals(contacts[0].Id, resourceOrders[0].Contact__c);
    System.assertEquals('USD', resourceOrders[0].Currency__c);
    // System.assertEquals('Test Organization - 11/27/2019', resourceOrders[0].Name); // Set by a workflow
    System.assertEquals(1000, resourceOrders[0].GP_Order_Total__c);
    System.assertEquals('IN-SL12345', resourceOrders[0].Order_Id__c);
    System.assertEquals('Standard Order', resourceOrders[0].RecordType.Name);
    System.assertEquals('Production and Delivery', resourceOrders[0].Status__c);
    System.assertEquals(Date.newInstance(2019, 11, 27), resourceOrders[0].Submitted_Date__c);

    System.assertEquals(10, resourceOrderItems[0].Amount__c);
    System.assertEquals('Test Item', resourceOrderItems[0].GP_Item_Name__c);
    System.assertEquals('IN-SL12345:123-9876', resourceOrderItems[0].Order_Item_Id__c);
    System.assertEquals(resourceOrders[0].Id, resourceOrderItems[0].Resource_Order__c);
    System.assertEquals(100, resourceOrderItems[0].Quantity__c);
  }

  /*
    Test that the account and contact are created but the resource order and resource order item
    are not created because the transaction id does not start with 'in'
  */
  @IsTest
  static void testInvalidTransactionId() {
    Resource__c resource = new Resource__c();
    resource.Name = 'Test Resource';
    resource.Resource_Id__c = '123-9876';
    resource.ISBN__c = '1234';
    insert resource;

    GP_Resource_Order_Data_Import_Event__e event = new GP_Resource_Order_Data_Import_Event__e();
    event.Data__c = '{"Customer Name":"Test Organization","Billing Contact First Name":"Test","Billing Contact Last Name":"Contact","Email":"test@example.com","Phone":"1231231234","Billing Street":"123 Test St","Billing City":"Test City","Billing State":"NY","Billing Postal Code":"12345","Billing Country":"United States","Customer ID":"123-456","Transaction ID":"OR-GR12345","Transaction Date":"2019-11-27T00:00:00.000Z","Order Total":1000.000,"Item Amount":10.000,"Item Name":"Test Item","Item ID":"123-9876","Item Quantity":100.000,"Payment Method":"Check","Check Number":"9876","Currency":"USD"}';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Account> accounts = fetchAccounts();
    List<Contact> contacts = fetchContacts();
    List<Resource_Order__c> resourceOrders = fetchResourceOrders();
    List<Resource_Order_Item__c> resourceOrderItems = fetchResourceOrderItems();
    List<Platform_Event_Error__c> platformEventErrors = fetchPlatformEventErrors();

    System.assertEquals(2, accounts.size());
    System.assertEquals(1, contacts.size());
    System.assertEquals(0, resourceOrders.size());
    System.assertEquals(0, resourceOrderItems.size());
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
  }

  /**
   * Test IN-SL order
   */
  @IsTest
  static void testNewOrder() {
    Resource__c resource = new Resource__c();
    resource.Name = 'Test Resource';
    resource.Resource_Id__c = '123-9876';
    resource.ISBN__c = '1234';
    insert resource;

    GP_Resource_Order_Data_Import_Event__e event = new GP_Resource_Order_Data_Import_Event__e();
    event.Data__c = '{"Customer Name":"Test Organization","Billing Contact First Name":"Test","Billing Contact Last Name":"Contact","Email":"test@example.com","Phone":"1231231234","Billing Street":"123 Test St","Billing City":"Test City","Billing State":"NY","Billing Postal Code":"12345","Billing Country":"United States","Customer ID":"123-456","Transaction ID":"IN-SL12345","Transaction Date":"2019-11-27T00:00:00.000Z","Order Total":1000.000,"Item Amount":10.000,"Item Name":"Test Item","Item ID":"123-9876","Item Quantity":100.000,"Payment Method":"Check","Check Number":"9876","Currency":"USD"}';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Account> accounts = fetchAccounts();
    List<Contact> contacts = fetchContacts();
    List<Resource_Order__c> resourceOrders = fetchResourceOrders();
    List<Resource_Order_Item__c> resourceOrderItems = fetchResourceOrderItems();
    List<Platform_Event_Error__c> platformEventErrors = fetchPlatformEventErrors();

    System.assertEquals(2, accounts.size());
    System.assertEquals(1, contacts.size());
    System.assertEquals(1, resourceOrders.size());
    System.assertEquals(1, resourceOrderItems.size());
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

    System.assertEquals(accounts[0].Id, resourceOrders[0].Account__c);
    System.assertEquals(contacts[0].Id, resourceOrders[0].Contact__c);
    System.assertEquals('USD', resourceOrders[0].Currency__c);
    System.assertEquals(1000, resourceOrders[0].GP_Order_Total__c);
    // System.assertEquals('Test Organization - 11/27/2019', resourceOrders[0].Name); // Set by a workflow
    System.assertEquals('IN-SL12345', resourceOrders[0].Order_Id__c);
    System.assertEquals('Standard Order', resourceOrders[0].RecordType.Name);
    System.assertEquals('Production and Delivery', resourceOrders[0].Status__c);
    System.assertEquals(Date.newInstance(2019, 11, 27), resourceOrders[0].Submitted_Date__c);

    System.assertEquals(10, resourceOrderItems[0].Amount__c);
    System.assertEquals('Test Item', resourceOrderItems[0].GP_Item_Name__c);
    System.assertEquals('IN-SL12345:123-9876', resourceOrderItems[0].Order_Item_Id__c);
    System.assertEquals(resource.Id, resourceOrderItems[0].Resource__c);
    System.assertEquals(resourceOrders[0].Id, resourceOrderItems[0].Resource_Order__c);
    System.assertEquals(100, resourceOrderItems[0].Quantity__c);
    System.assertEquals('Shipped', resourceOrderItems[0].Status__c);
  }
}