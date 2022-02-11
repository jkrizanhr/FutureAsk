public inherited sharing class GPResourceInventoryDataImportService {
  private GP_Resource_Inventory_Data_Import_Event__e event;

  /**
   * Constructor
   * @param event - Platform event GP_Resource_Inventory_Data_Import_Event__e from Trigger.new
   */
  public GPResourceInventoryDataImportService(
    GP_Resource_Inventory_Data_Import_Event__e event
  ) {
    this.event = event;
  }

  /**
   * The main method to execute the import process
   */
  public void run() {
    if (this.event == null || String.isBlank(this.event.Data__c)) {
      throw new GPDataImportEventException('Event data not found.');
    }

    // Deserialize the data
    Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(
      this.event.Data__c
    );

    String resourceId = GPDataImportHelper.getStringVal(dataMap, 'Resource ID');
    if (String.isBlank(resourceId)) {
      throw new GPDataImportEventException('Resource ID is blank.');
    }

    Resource__c resource = this.buildResource(dataMap);
    upsert resource Resource_Id__c;

    Resource_Inventory_Location__c resourceInventoryLocation = this.buildResourceInventoryLocation(
      dataMap,
      resource.Id
    );
    upsert resourceInventoryLocation Resource_Location_Id__c;
  }

  /**
   * Build an instance of the resource record from the JSON containing the SQL view row data
   * @param dataMap The untyped deserialization of the data
   */
  private Resource__c buildResource(Map<String, Object> dataMap) {
    Resource__c resource = new Resource__c();
    resource.Name = GPDataImportHelper.getStringVal(dataMap, 'Resource Name');

    if (String.isBlank(resource.Name)) {
      resource.Name = 'Resource';
    }

    resource.Biblica_Translation_Abbreviation__c = GPDataImportHelper.getStringVal(
      dataMap,
      'Translation'
    );
    resource.Cost__c = GPDataImportHelper.getDecimalVal(
      dataMap,
      'Standard Cost'
    );
    resource.Description__c = GPDataImportHelper.getStringVal(
      dataMap,
      'Resource Description'
    );
    resource.GP_Resource_Name__c = GPDataImportHelper.getStringVal(
      dataMap,
      'Resource Name'
    );
    resource.ISBN__c = GPDataImportHelper.getStringVal(dataMap, 'ISBN');
    resource.Language__c = GPDataImportHelper.getStringVal(dataMap, 'Language');
    resource.Resource_Id__c = GPDataImportHelper.getStringVal(
      dataMap,
      'Resource ID'
    );
    resource.U_of_M_Schedule_ID__c = GPDataImportHelper.getStringVal(
      dataMap,
      'U Of M Schedule'
    );
    resource.Vendor_ID__c = GPDataImportHelper.getStringVal(
      dataMap,
      'Vendor ID'
    );
    resource.Weight__c = GPDataImportHelper.getDecimalVal(
      dataMap,
      'Item Shipping Weight'
    );

    List<Resource__c> resources = GPDataImportHelper.fetchResources(
      resource.Resource_Id__c
    );

    if (!resources.isEmpty()) {
      resource.Name = resources[0].Name;

      if (String.isNotBlank(resources[0].Biblica_Translation_Abbreviation__c)) {
        resource.Biblica_Translation_Abbreviation__c = resources[0]
          .Biblica_Translation_Abbreviation__c;
      }
      if (resources[0].Cost__c != null) {
        resource.Cost__c = resources[0].Cost__c;
      }
      if (String.isNotBlank(resources[0].Description__c)) {
        resource.Description__c = resources[0].Description__c;
      }
      if (String.isNotBlank(resources[0].GP_Resource_Name__c)) {
        resource.GP_Resource_Name__c = resources[0].GP_Resource_Name__c;
      }
      if (String.isNotBlank(resources[0].ISBN__c)) {
        resource.ISBN__c = resources[0].ISBN__c;
      }
      if (String.isNotBlank(resources[0].Language__c)) {
        resource.Language__c = resources[0].Language__c;
      }
      if (String.isNotBlank(resources[0].U_of_M_Schedule_ID__c)) {
        resource.U_of_M_Schedule_ID__c = resources[0].U_of_M_Schedule_ID__c;
      }
      if (String.isNotBlank(resources[0].Vendor_ID__c)) {
        resource.Vendor_ID__c = resources[0].Vendor_ID__c;
      }
      if (resources[0].Weight__c != null) {
        resource.Weight__c = resources[0].Weight__c;
      }
    }

    return resource;
  }

  /**
   * Build an instance of the resource inventory location record from the JSON containing the SQL view row data
   * @param dataMap The untyped deserialization of the data
   * @param resourceSfId The Salesforce resource record id
   */
  private Resource_Inventory_Location__c buildResourceInventoryLocation(
    Map<String, Object> dataMap,
    Id resourceSfId
  ) {
    Resource_Inventory_Location__c resourceInventoryLocation = new Resource_Inventory_Location__c();
    resourceInventoryLocation.Resource__c = resourceSfId;
    resourceInventoryLocation.Warehouse__c = GPDataImportHelper.getStringVal(
      dataMap,
      'Location'
    );
    String resourceId = GPDataImportHelper.getStringVal(dataMap, 'Resource ID');
    resourceInventoryLocation.Resource_Location_Id__c =
      resourceId +
      ':' +
      resourceInventoryLocation.Warehouse__c;
    Decimal quantityAvailable = GPDataImportHelper.getDecimalVal(
      dataMap,
      'Quantity Available'
    );
    if (quantityAvailable != null) {
      resourceInventoryLocation.Available_Inventory__c = Integer.valueOf(
        quantityAvailable
      );
    }
    return resourceInventoryLocation;
  }
}