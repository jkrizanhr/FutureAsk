@IsTest
private class GPResourceInventoryDataImportEventTest {
  /**
   * Utility method to retrieve resource results
   */
  private static List<Resource__c> fetchResources() {
    return [
      SELECT
        Biblica_Translation_Abbreviation__c,
        Cost__c,
        Description__c,
        GP_Resource_Name__c,
        ISBN__c,
        Language__c,
        Name,
        Resource_Id__c,
        U_of_M_Schedule_ID__c,
        Vendor_ID__c,
        Weight__c
      FROM Resource__c
    ];
  }

  /**
   * Utility method to retrieve resource inventory location results
   */
  private static List<Resource_Inventory_Location__c> fetchResourceInventoryLocations() {
    return [
      SELECT Available_Inventory__c, Id, Resource__c, Warehouse__c
      FROM Resource_Inventory_Location__c
    ];
  }

  /**
   * Utility method to retrieve platform event error results
   */
  private static List<Platform_Event_Error__c> fetchPlatformEventErrors() {
    return [SELECT Data__c, Error__c, Origin__c FROM Platform_Event_Error__c];
  }

  @IsTest
  static void testNewResource() {
    GP_Resource_Inventory_Data_Import_Event__e event = new GP_Resource_Inventory_Data_Import_Event__e();
    event.Data__c = '{"Resource Name":"Test Resource","Resource ID":"124-123","ISBN":"1234","Translation":"NIV","Language":"English","Quantity Available":42.000,"Location":"DPI","Resource Description":"This is an example description for the resource.","Vendor ID":"BIBLAT","Item Shipping Weight":2.750000,"U Of M Schedule":"EACH","Standard Cost":0.49000}';
    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Resource__c> resources = fetchResources();
    List<Resource_Inventory_Location__c> resourceInventoryLocations = fetchResourceInventoryLocations();
    List<Platform_Event_Error__c> errors = fetchPlatformEventErrors();

    System.assertEquals(1, resources.size());
    System.assertEquals(1, resourceInventoryLocations.size());
    System.assertEquals(0, errors.size());
    System.assertEquals(
      'This is an example description for the resource.',
      resources[0].Description__c
    );
    System.assertEquals('Test Resource', resources[0].GP_Resource_Name__c);
    System.assertEquals('1234', resources[0].ISBN__c);
    System.assertEquals('English', resources[0].Language__c);
    // System.assertEquals('Test Resource', resources[0].Name); // Not asserting the value for the name because it is automated by a workflow
    System.assertEquals('124-123', resources[0].Resource_Id__c);
    System.assertEquals(
      'NIV',
      resources[0].Biblica_Translation_Abbreviation__c
    );
    System.assertEquals('BIBLAT', resources[0].Vendor_ID__c);
    System.assertEquals('EACH', resources[0].U_of_M_Schedule_ID__c);
    System.assertEquals(0.49, resources[0].Cost__c);
    System.assertEquals(2.75, resources[0].Weight__c);

    System.assertEquals(
      42,
      resourceInventoryLocations[0].Available_Inventory__c
    );
    System.assertEquals(
      resources[0].Id,
      resourceInventoryLocations[0].Resource__c
    );
    System.assertEquals('DPI', resourceInventoryLocations[0].Warehouse__c);
  }

  @IsTest
  static void testExistingResource() {
    Resource__c resource = new Resource__c();
    resource.Name = 'Test Resource';
    resource.Cost__c = 5;
    resource.U_of_M_Schedule_ID__c = '2';
    resource.Resource_Id__c = '124-123';
    resource.ISBN__c = '1234';
    resource.Description__c = 'This is an example description for the resource.';
    resource.Vendor_ID__c = '1';
    resource.Weight__c = 5;
    resource.Language__c = 'English';
    insert resource;

    Resource_Inventory_Location__c resourceInventoryLocation = new Resource_Inventory_Location__c();
    resourceInventoryLocation.Resource__c = resource.Id;
    resourceInventoryLocation.Warehouse__c = 'DPI';
    resourceInventoryLocation.Resource_Location_Id__c = '124-123:DPI';
    insert resourceInventoryLocation;

    GP_Resource_Inventory_Data_Import_Event__e event = new GP_Resource_Inventory_Data_Import_Event__e();
    event.Data__c = '{"Resource Name":"Test Resource","Resource ID":"124-123","ISBN":"123456789","Translation":"NIV","Language":"English","Quantity Available":42.000,"Location":"DPI","Resource Description":"This is an example description for the resource."}';
    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Resource__c> resources = fetchResources();
    List<Resource_Inventory_Location__c> resourceInventoryLocations = fetchResourceInventoryLocations();
    List<Platform_Event_Error__c> errors = fetchPlatformEventErrors();

    System.assertEquals(1, resources.size());
    System.assertEquals(1, resourceInventoryLocations.size());
    System.assertEquals(0, errors.size());

    System.assertEquals(resource.Id, resources[0].Id);
    System.assertEquals(
      'This is an example description for the resource.',
      resources[0].Description__c
    );
    System.assertEquals('Test Resource', resources[0].GP_Resource_Name__c);
    System.assertEquals('1234', resources[0].ISBN__c);
    System.assertEquals('English', resources[0].Language__c);
    // System.assertEquals('Test Resource', resources[0].Name); // Not asserting the value for the name because it is automated by a workflow
    System.assertEquals('124-123', resources[0].Resource_Id__c);
    System.assertEquals(
      'NIV',
      resources[0].Biblica_Translation_Abbreviation__c
    );

    System.assertEquals(
      42,
      resourceInventoryLocations[0].Available_Inventory__c
    );
    System.assertEquals(resource.Id, resourceInventoryLocations[0].Resource__c);
    System.assertEquals('DPI', resourceInventoryLocations[0].Warehouse__c);
  }

  @IsTest
  static void testError() {
    GP_Resource_Inventory_Data_Import_Event__e event = new GP_Resource_Inventory_Data_Import_Event__e();
    event.Data__c = '{"Resource Name":"Test Resource","Resource ID":"124-123","ISBN":"1234","Translation":"NIV","Language":"English","Quantity Available":"Hello World","Location":"Abuja","Resource Description":"This is an example description for the resource."}';
    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Resource__c> resources = fetchResources();
    List<Resource_Inventory_Location__c> resourceInventoryLocations = fetchResourceInventoryLocations();
    List<Platform_Event_Error__c> errors = fetchPlatformEventErrors();

    System.assertEquals(0, resources.size());
    System.assertEquals(0, resourceInventoryLocations.size());
    System.assertEquals(1, errors.size());
    System.assertEquals('NJE_ResourceInventory', errors[0].Origin__c);
    System.assertEquals(event.Data__c, errors[0].Data__c);
    System.assert(String.isNotBlank(errors[0].Error__c));
  }
}