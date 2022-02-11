public inherited sharing class GPExportBundleTransferService {
  private GP_Export_Bundle__c bundle;
  private List<Transfer__c> transfers;

  /**
   * Constructor
   * @param bundleId
   */
  public GPExportBundleTransferService(Id bundleId) {
    this.bundle = [
      SELECT Fund_GL_Error_Message__c, Id, Name
      FROM GP_Export_Bundle__c
      WHERE Id = :bundleId
    ];
    this.transfers = [
      SELECT
        Amount__c,
        Date__c,
        Fund_GL_Account__c,
        Fund_GL_Account__r.Active__c,
        Fund_GL_Account__r.General_Accounting_Unit__c,
        Fund_GL_Account__r.GL_Account__c,
        Fund_GL_Account__r.GL_Account_Prefix__c,
        GP_Export_Error__c,
        Id,
        Primary_General_Accounting_Unit__c,
        Primary_General_Accounting_Unit__r.npsp__Active__c,
        Primary_General_Accounting_Unit__r.Purpose_Code__c,
        Reciprocal_Transfer__c,
        Secondary_General_Accounting_Unit__c,
        Status__c,
        Type__c
      FROM Transfer__c
      WHERE GP_Export_Bundle__c = :bundleId
      ORDER BY Id
    ];
  }

  /**
   * Utility method to concatenate error messages onto the GP Export Bundle record.
   * @param errMessage - The custom error message to append.
   */
  private void addBundleError(String errMessage) {
    if (String.isNotBlank(this.bundle.Fund_GL_Error_Message__c)) {
      if (this.bundle.Fund_GL_Error_Message__c.contains(errMessage)) {
        return;
      }
      this.bundle.Fund_GL_Error_Message__c += '\n';
    }
    this.bundle.Fund_GL_Error_Message__c += errMessage;
    this.bundle.Fund_GL_Error_Message__c = this.bundle.Fund_GL_Error_Message__c.abbreviate(13000);
  }

  /**
   * Check the GAU and Fund GL Account related to the Transfer and validate that the
   * fields are set properly.
   * @param transfer - The Transfer with the related records (GAU, Fund GL Account)
   */
  private void validateGAUs(Transfer__c transfer) {
    transfer.GP_Export_Error__c = '';
    List<String> validationErrors = new List<String>();

    // Validations on GAU and Fund GL Account related to the Transfer
    if (String.isBlank(transfer.Primary_General_Accounting_Unit__r.Purpose_Code__c)) {
      // Validation Failed
      validationErrors.add('General accounting unit\'s purpose code is blank.');
    }

    if (transfer.Fund_GL_Account__c == null) {
      // Validation Failed
      validationErrors.add('Fund gl account not found.');
    } else {
      if (String.isBlank(transfer.Fund_GL_Account__r.GL_Account__c)) {
        // Validation Failed
        validationErrors.add('Fund gl account\'s gl account is not found.');
      }

      if (!transfer.Fund_GL_Account__r.Active__c) {
        // Validation Failed
        validationErrors.add('Fund gl account is not active.');
      }
    }

    if (
      transfer.Primary_General_Accounting_Unit__r != null &&
      transfer.Fund_GL_Account__c != null &&
      transfer.Primary_General_Accounting_Unit__c !=
      transfer.Fund_GL_Account__r.General_Accounting_Unit__c
    ) {
      // Validation Failed
      validationErrors.add(
        'The general accounting unit associated with the transfer is not the same as the general accounting unit tied to the related fund gl account record.'
      );
    }

    if (!validationErrors.isEmpty()) {
      transfer.GP_Export_Error__c = String.join(validationErrors, '\n');

      if (!transfer.Primary_General_Accounting_Unit__r.npsp__Active__c) {
        // Validation Failed
        transfer.GP_Export_Error__c += '\nInactive GAU';
        this.addBundleError('Transfer: Inactive GAU');
      } else {
        this.addBundleError('Transfer: Error Found');
      }
    }
  }

  /**
   * Map fields to represent a row for a new GP Export AAGL Row record.
   * Example file columns:
   * - SeqID
   * - Donation_ID
   * - Donation_Date
   * - Donation_Batch_Number
   * - GP Full Account
   * - Donation_Amount
   * - Purpose_Code
   * - GP_Natural_Account
   * - Checkbook (leave blank)
   * @param transfer - The transfer record
   * @param rowNumber - The aagl row number that would appear in the export file
   * @return GP_Export_AAGL_Row__c - The new instance of a gp export aagl row record that will
   * later be inserted.
   */
  private GP_Export_AAGL_Row__c buildAAGLRow(Transfer__c transfer, Integer rowNumber) {
    GP_Export_AAGL_Row__c aaglRow = new GP_Export_AAGL_Row__c();
    aaglRow.SeqID__c = rowNumber;
    // Checkbook__c // Should be null
    aaglRow.Donation_Amount__c = transfer.Amount__c;
    aaglRow.Donation_Batch_Number__c = this.bundle.Name;
    aaglRow.Donation_Date__c = String.valueOf(transfer.Date__c);
    aaglRow.Donation_ID__c = transfer.Id;
    aaglRow.GP_Export_Bundle__c = this.bundle.Id;
    aaglRow.GP_Full_Account__c = transfer.Fund_GL_Account__r.GL_Account__c;
    aaglRow.GP_Natural_Account__c = transfer.Fund_GL_Account__r.GL_Account_Prefix__c;
    aaglRow.Purpose_Code__c = transfer.Primary_General_Accounting_Unit__r.Purpose_Code__c;
    aaglRow.Transfer__c = transfer.Id;
    return aaglRow;
  }

  /**
   * The main method called from the GPExportBundleTriggerService which will call the above methods
   * to create gp export aagl rows and validate the transfers and related records.
   */
  public void run() {
    if (this.bundle.Fund_GL_Error_Message__c == null) {
      // Set to an empty string so that we don't have to null check it when concatenating errors.
      this.bundle.Fund_GL_Error_Message__c = '';
    }

    List<GP_Export_AAGL_Row__c> aaglRows = new List<GP_Export_AAGL_Row__c>();
    for (Transfer__c transfer : this.transfers) {
      this.validateGAUs(transfer);
      if (
        transfer.Fund_GL_Account__c != null &&
        String.isNotBlank(transfer.Fund_GL_Account__r.GL_Account__c)
      ) {
        // Create instances of AAGL Rows
        GP_Export_AAGL_Row__c aaglRow = this.buildAAGLRow(transfer, aaglRows.size() + 1);
        aaglRows.add(aaglRow);
      }
    }

    try {
      insert aaglRows;
      update this.transfers;
    } catch (Exception e) {
      this.addBundleError(e.getMessage());
    }

    if (String.isBlank(this.bundle.Fund_GL_Error_Message__c)) {
      this.bundle.Fund_GL_Validation_Check__c = 'Check Transaction Numbers';
    }

    update this.bundle;
  }
}