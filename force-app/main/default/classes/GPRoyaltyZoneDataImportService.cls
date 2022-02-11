public inherited sharing class GPRoyaltyZoneDataImportService {
  private GP_Royalty_Zone_Data_Import_Event__e event;
  private Id resourceId;

  /**
   * Constructor
   * @param event Platform event GP_Royalty_Zone_Data_Import_Event__e from Trigger.new
   * @param resourceId "Royalty Payment" resource id
   */
  public GPRoyaltyZoneDataImportService(GP_Royalty_Zone_Data_Import_Event__e event, Id resourceId) {
    this.event = event;
    this.resourceId = resourceId;
  }

  /**
   * The main method to execute the import process
   *
   * NJE_RoyaltyZone
   *  Match on Contact First, last, Email. Create if doesn't exist
   *  Match on Account Name, Street, State. Create if doesn't exist
   *  Match agreement, don't set if no match found
   *  Set record type of order to royalty payment
   *  Automatically create a resource line item linked to a
   *  resource called "Royalty Payment" for the full order amount
   */
  public void run() {
    if (this.event == null || String.isBlank(this.event.Data__c)) {
      throw new GPDataImportEventException('Event data not found.');
    }

    if (this.resourceId == null) {
      throw new GPDataImportEventException('Resource record not found.');
    }

    // Deserialize the data
    Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(this.event.Data__c);

    Id agreementId = this.getAgreementId(dataMap);

    // Insert or update the account and contact
    Account account = GPDataImportHelper.importAccount(dataMap);
    Contact contact = GPDataImportHelper.importContact(dataMap, account.Id);

    Id contactId = contact != null ? contact.Id : null;

    // Upsert resource order
    Resource_Order__c resourceOrder = this.buildResourceOrder(
      dataMap,
      account.Id,
      contactId,
      agreementId
    );
    upsert resourceOrder Order_Id__c;

    // Upsert resource order item
    Resource_Order_Item__c item = this.buildResourceOrderItem(dataMap, resourceOrder.Id);
    upsert item Order_Item_Id__c;

    // Insert or update the country
    String countryStr = GPDataImportHelper.getStringVal(dataMap, 'Country');
    if (String.isNotBlank(countryStr)) {
      List<Country__c> countries = [
        SELECT Id, Country__c
        FROM Country__c
        WHERE Resource_Order_Item__c = :item.Id
      ];
      if (countries.isEmpty()) {
        Country__c country = new Country__c();
        country.Resource_Order_Item__c = item.Id;
        country.Country__c = countryStr;
        insert country;
      } else if (countries[0].Country__c != countryStr) {
        countries[0].Country__c = countryStr;
        update countries[0];
      }
    }
  }

  /**
   * Get the Agreement Name from the Great Plains data and find an existing Agreement record id.
   * @return Id
   */
  private Id getAgreementId(Map<String, Object> dataMap) {
    String royaltyZoneAgreementName = GPDataImportHelper.getStringVal(dataMap, 'Agreement Name');
    if (String.isNotBlank(royaltyZoneAgreementName)) {
      List<Agreement__c> agreements = [
        SELECT Id
        FROM Agreement__c
        WHERE RoyaltyZone_Agreement_Name__c = :royaltyZoneAgreementName
      ];
      if (!agreements.isEmpty()) {
        return agreements[0].Id;
      }
    }
    return null;
  }

  /**
   * Map the Great Plains RoyaltyZone data a resource order object
   * @param dataMap
   * @param accountId
   * @param contactId
   * @param agreementId
   * @return Resource_Order__c
   */
  private Resource_Order__c buildResourceOrder(
    Map<String, Object> dataMap,
    Id accountId,
    Id contactId,
    Id agreementId
  ) {
    Resource_Order__c resourceOrder = GPDataImportHelper.buildBaseResourceOrder(
      dataMap,
      accountId,
      contactId
    );
    resourceOrder.Agreement__c = agreementId;
    resourceOrder.RecordTypeId = Utils.getRecordTypeId('Resource_Order__c', 'Royalty Payment');
    resourceOrder.Invoice_Id__c = GPDataImportHelper.getStringVal(dataMap, 'Invoice ID');
    String invoiceDateStr = GPDataImportHelper.getStringVal(dataMap, 'Invoice Date');
    if (String.isNotBlank(invoiceDateStr)) {
      resourceOrder.Invoice_Date__c = Date.valueOf(invoiceDateStr);
    }
    resourceOrder.GP_Order_Total__c = GPDataImportHelper.getDecimalVal(dataMap, 'Amount');
    return resourceOrder;
  }

  /**
   * Map the Great Plains data a resource order item object
   * @param dataMap
   * @param resourceOrderId
   * @return Resource_Order_Item__c
   */
  private Resource_Order_Item__c buildResourceOrderItem(
    Map<String, Object> dataMap,
    Id resourceOrderId
  ) {
    Resource_Order_Item__c resourceOrderItem = new Resource_Order_Item__c();
    resourceOrderItem.Resource__c = this.resourceId;
    resourceOrderItem.Resource_Order__c = resourceOrderId;
    resourceOrderItem.Amount__c = GPDataImportHelper.getDecimalVal(dataMap, 'Amount');
    String transactionId = GPDataImportHelper.getStringVal(dataMap, 'Transaction ID');
    String invoiceId = GPDataImportHelper.getStringVal(dataMap, 'Invoice ID');
    resourceOrderItem.Order_Item_Id__c = transactionId + ':' + invoiceId;
    return resourceOrderItem;
  }
}