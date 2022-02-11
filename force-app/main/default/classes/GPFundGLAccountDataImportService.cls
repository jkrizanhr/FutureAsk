public inherited sharing class GPFundGLAccountDataImportService {
  private GP_Fund_GL_Account_Data_Import_Event__e event;

  /**
   * Constructor
   * @param event - Platform event GP_Fund_GL_Account_Data_Import_Event__e from Trigger.new
   */
  public GPFundGLAccountDataImportService(GP_Fund_GL_Account_Data_Import_Event__e event) {
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

    String purposeCode = GPDataImportHelper.getStringVal(dataMap, 'aaTrxDimCode');
    if (String.isBlank(purposeCode)) {
      purposeCode = '';
    }
    purposeCode = purposeCode.trim();

    // Map and upsert the Fund GL Account
    Fund_GL_Account__c fundGLAccount = new Fund_GL_Account__c();
    fundGLAccount.GL_Account__c = GPDataImportHelper.getStringVal(dataMap, 'ACTNUMST');
    fundGLAccount.GL_Account_Prefix__c = GPDataImportHelper.getStringVal(dataMap, 'ACTNUMBR_1');
    fundGLAccount.GL_Account_External_Id__c = purposeCode + ':' + fundGLAccount.GL_Account__c;
    fundGLAccount.GL_Account_Description__c = GPDataImportHelper.getStringVal(dataMap, 'ACTDESCR');

    if (String.isNotBlank(purposeCode)) {
      List<npsp__General_Accounting_Unit__c> gaus = [
        SELECT Id
        FROM npsp__General_Accounting_Unit__c
        WHERE Purpose_Code__c = :purposeCode
      ];

      if (!gaus.isEmpty()) {
        fundGLAccount.General_Accounting_Unit__c = gaus[0].Id;
      }
    }

    Integer numFundGLAccounts = [
      SELECT COUNT()
      FROM Fund_GL_Account__c
      WHERE GL_Account_External_Id__c = :fundGLAccount.GL_Account_External_Id__c
    ];

    if (numFundGLAccounts == 0) {
      // Only set the name field for new records to ensure that we don't overwrite it.
      fundGLAccount.Name = fundGLAccount.GL_Account__c;
    }

    upsert fundGLAccount GL_Account_External_Id__c;
  }
}