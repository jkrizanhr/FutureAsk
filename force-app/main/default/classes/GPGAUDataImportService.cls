public inherited sharing class GPGAUDataImportService {
  private GP_GAU_Data_Import_Event__e event;

  /**
   * Constructor
   * @param event - Platform event GP_GAU_Data_Import_Event__e from Trigger.new
   */
  public GPGAUDataImportService(GP_GAU_Data_Import_Event__e event) {
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
    Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(this.event.Data__c);
    System.debug(dataMap);

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Purpose_Code__c = GPDataImportHelper.getStringVal(dataMap, 'aaTrxDimCode').trim();

    List<npsp__General_Accounting_Unit__c> gaus = [
      SELECT Id
      FROM npsp__General_Accounting_Unit__c
      WHERE Purpose_Code__c = :gau.Purpose_Code__c
    ];

    String desc1 = GPDataImportHelper.getStringVal(dataMap, 'aaTrxDimCodeDescr');
    String desc2 = GPDataImportHelper.getStringVal(dataMap, 'aaTrxDimCodeDescr2');

    if (gaus.isEmpty()) {
      gau.Name = gau.Purpose_Code__c + ' - ' + desc1;
      gau.Name = gau.Name.abbreviate(80);
      gau.npsp__Description__c = desc2;
    } else {
      gau.Id = gaus[0].Id;
    }

    gau.GP_Active__c = GPDataImportHelper.getDecimalVal(dataMap, 'INACTIVE') == 0 ? true : false;
    gau.GP_Dim_Code_Description__c = desc1;
    gau.GP_Dim_Code_Description_2__c = desc2;

    upsert gau;
  }
}