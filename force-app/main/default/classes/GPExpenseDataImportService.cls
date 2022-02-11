public inherited sharing class GPExpenseDataImportService {
  private GP_Expense_Data_Import_Event__e event;
  public GPExpenseDataImportService(GP_Expense_Data_Import_Event__e event) {
    this.event = event;
  }

  public void run() {
    if (this.event == null || String.isBlank(this.event.Data__c)) {
      throw new GPDataImportEventException('Event data not found.');
    }

    // Deserialize the data
    Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(this.event.Data__c);

    String projectCode = GPDataImportHelper.getStringVal(dataMap, 'Project Code');
    if (String.isBlank(projectCode)) {
      // We don't want to import the data if it does not have a project code
      return;
    }

    projectCode = projectCode.trim();

    Expense__c expense = new Expense__c();

    List<npsp__General_Accounting_Unit__c> gaus = [
      SELECT Id
      FROM npsp__General_Accounting_Unit__c
      WHERE Purpose_Code__c = :projectCode
    ];

    if (gaus.isEmpty()) {
      throw new GPDataImportEventException('No existing GAU with the matching purpose code.');
    }

    expense.General_Accounting_Unit__c = gaus[0].Id;

    String description = GPDataImportHelper.getStringVal(dataMap, 'Description');
    String vendorName = GPDataImportHelper.getStringVal(dataMap, 'Vendor Name');

    if (String.isNotBlank(description) && String.isNotBlank(vendorName)) {
      expense.Title__c = description + ' - ' + vendorName;
    } else if (String.isNotBlank(description)) {
      expense.Title__c = description;
    } else if (String.isNotBlank(vendorName)) {
      expense.Title__c = VendorName;
    }
    expense.Title__c = expense.Title__c.abbreviate(255);
    expense.Description__c = description;
    expense.Amount__c = GPDataImportHelper.getDecimalVal(dataMap, 'Analytical Amount');
    String dte = GPDataImportHelper.getStringVal(dataMap, 'Date');
    if (String.isNotBlank(dte)) {
      expense.Date__c = Date.valueOf(dte);
    }
    String voucherNumber = GPDataImportHelper.getStringVal(dataMap, 'Voucher Number');
    voucherNumber = voucherNumber != null ? voucherNumber : '';
    String accountNumber = GPDataImportHelper.getStringVal(dataMap, 'Account Number');
    accountNumber = accountNumber != null ? accountNumber : '';
    expense.GP_External_Id__c = voucherNumber + ':' + accountNumber + ':' + projectCode;

    upsert expense GP_External_Id__c;
  }
}