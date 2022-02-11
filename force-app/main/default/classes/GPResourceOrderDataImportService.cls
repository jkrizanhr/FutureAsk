public inherited sharing class GPResourceOrderDataImportService {
  private GP_Resource_Order_Data_Import_Event__e event;

  /**
   * Constructor
   * @param event - Platform event GP_Resource_Order_Data_Import_Event__e from Trigger.new
   */
  public GPResourceOrderDataImportService(GP_Resource_Order_Data_Import_Event__e event) {
    this.event = event;
  }

  /**
   * The main method to execute the import process
   *
   * Great Plains data is from the SQL db's NJE_ResourceOrder view
   *  Match on Contact First, last, Email. Create if doesn't exist
   *  Match on Account Name, Street, State. Create if doesn't exist
   *  Create order and add line items to it
   *  Record type should be standard order
   */
  public void run() {
    if (this.event == null || String.isBlank(this.event.Data__c)) {
      throw new GPDataImportEventException('Event data not found.');
    }

    // Deserialize the data
    Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(this.event.Data__c);

    Id resourceId = this.getResourceId(dataMap);
    if (resourceId == null) {
      throw new GPDataImportEventException('Resource record not found.');
    }

    // Insert or update the account and contact
    Account account = GPDataImportHelper.importAccount(dataMap);
    Contact contact = GPDataImportHelper.importContact(dataMap, account.Id);

    Id contactId = contact != null ? contact.Id : null;

    // Get the transaction id
    String transactionId = GPDataImportHelper.getStringVal(dataMap, 'Transaction ID');

    // Only create a resource order and resource order item if the transaction id starts with 'in'
    //   NOTE: This applies to the data for this view and does not necessarily apply to royalty payments
    if (String.isNotBlank(transactionId) && transactionId.startsWithIgnoreCase('in')) {
      // Upsert resource order
      Resource_Order__c resourceOrder = this.buildResourceOrder(dataMap, account.Id, contactId);
      upsert resourceOrder Order_Id__c;

      // Upsert resource order item
      Resource_Order_Item__c resourceOrderItem = this.buildResourceOrderItem(
        dataMap,
        resourceId,
        resourceOrder.Id
      );
      upsert resourceOrderItem Order_Item_Id__c;

      /* 
        Validation Rule:
        The Resource Order cannot be moved to the final stage until there are Resource Order Items 
        with a quantity/amount associated with this order.

        Therefore we are updating the resource order's status after the fact
      */
      Integer count = [
        SELECT COUNT()
        FROM Resource_Order__c
        WHERE Order_Id__c = :transactionId AND Status__c = 'Final Invoice and Payment'
      ];

      if (count == 0) {
        // Only set the status if it is not already set to 'Final Invoice and Payment'
        // because we don't want to update if it's not needed or if it would cause the stage/status
        // to be moved back.
        if (transactionId.startsWithIgnoreCase('IN-GR')) {
          // Grant
          resourceOrder.Status__c = 'Final Invoice and Payment';
        } else {
          // Order
          resourceOrder.Status__c = 'Production and Delivery';
        }
        resourceOrder.Advance_without_Roles__c = true;
        update resourceOrder;
      }
    }
  }

  /**
   * Get the Item ID from the Great Plains data and find an existing resource record id.
   * @return Id
   */
  private Id getResourceId(Map<String, Object> dataMap) {
    String itemId = GPDataImportHelper.getStringVal(dataMap, 'Item ID');
    if (String.isNotBlank(itemId)) {
      List<Resource__c> resources = GPDataImportHelper.fetchResources(itemId);
      if (!resources.isEmpty()) {
        return resources[0].Id;
      }
    }
    return null;
  }

  /**
   * Map the Great Plains data a resource order object
   * @param dataMap
   * @param accountId
   * @param contactId
   * @return Resource_Order__c
   */
  private Resource_Order__c buildResourceOrder(
    Map<String, Object> dataMap,
    Id accountId,
    Id contactId
  ) {
    Resource_Order__c resourceOrder = GPDataImportHelper.buildBaseResourceOrder(
      dataMap,
      accountId,
      contactId
    );
    resourceOrder.RecordTypeId = Utils.getRecordTypeId('Resource_Order__c', 'Standard Order');
    resourceOrder.GP_Order_Total__c = GPDataImportHelper.getDecimalVal(dataMap, 'Order Total');
    return resourceOrder;
  }

  /**
   * Map the Great Plains data a resource order item object
   * @param dataMap
   * @param resourceId
   * @param resourceOrderId
   * @return Resource_Order_Item__c
   */
  public Resource_Order_Item__c buildResourceOrderItem(
    Map<String, Object> dataMap,
    Id resourceId,
    Id resourceOrderId
  ) {
    Resource_Order_Item__c resourceOrderItem = new Resource_Order_Item__c();
    resourceOrderItem.Resource_Order__c = resourceOrderId;
    resourceOrderItem.Resource__c = resourceId;
    resourceOrderItem.Amount__c = GPDataImportHelper.getDecimalVal(dataMap, 'Item Amount');
    resourceOrderItem.GP_Item_Name__c = GPDataImportHelper.getStringVal(dataMap, 'Item Name');
    Decimal quantity = GPDataImportHelper.getDecimalVal(dataMap, 'Item Quantity');
    if (quantity != null) {
      resourceOrderItem.Quantity__c = Integer.valueOf(quantity);
    }
    String transactionId = GPDataImportHelper.getStringVal(dataMap, 'Transaction ID');
    String itemId = GPDataImportHelper.getStringVal(dataMap, 'Item ID');
    resourceOrderItem.Order_Item_Id__c = transactionId + ':' + itemId;
    resourceOrderItem.Status__c = 'Shipped';
    return resourceOrderItem;
  }
}