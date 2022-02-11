@IsTest
private class GPExpenseDataImportEventTest {
  private static List<Expense__c> fetchExpenses() {
    return [
      SELECT
        Amount__c,
        Date__c,
        Description__c,
        General_Accounting_Unit__c,
        GP_External_Id__c,
        Id,
        Title__c
      FROM Expense__c
    ];
  }

  @IsTest
  static void testNewExpense() {
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test Fund';
    gau.Purpose_Code__c = '4567';
    gau.npsp__Active__c = true;
    insert gau;

    GP_Expense_Data_Import_Event__e event = new GP_Expense_Data_Import_Event__e();
    event.Data__c =
      '{' +
      '"Voucher Number":"123",' +
      '"Description":"Test Description",' +
      '"Vendor Code":"ABCDE",' +
      '"Vendor Name":"Test Vendor",' +
      '"Document Number":"8/07/20",' +
      '"Date":"2020-08-07 00:00:00.000",' +
      '"Document Amount":100.00000,' +
      '"Account Number":"1111-000-000",' +
      '"Analytical Amount":42.50000,' +
      '"Project Code":"4567",' +
      '"Dimension Description":"Test Dimension Description"' +
      '}';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Expense__c> expenses = fetchExpenses();

    System.assertEquals(1, expenses.size());
    System.assertEquals(42.50, expenses[0].Amount__c);
    System.assertEquals(Date.newInstance(2020, 8, 7), expenses[0].Date__c);
    System.assertEquals('Test Description', expenses[0].Description__c);
    System.assertEquals(gau.Id, expenses[0].General_Accounting_Unit__c);
    System.assertEquals('123:1111-000-000:4567', expenses[0].GP_External_Id__c);
    System.assertEquals('Test Description - Test Vendor', expenses[0].Title__c);
  }

  @IsTest
  static void testExistingExpense() {
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'Test Fund';
    gau.Purpose_Code__c = '4321';
    gau.npsp__Active__c = true;
    insert gau;

    Expense__c expense = new Expense__c();
    expense.Title__c = 'Test Expense';
    expense.Amount__c = 100;
    expense.Date__c = Date.today().addDays(-1);
    expense.Description__c = 'This is a test';
    expense.General_Accounting_Unit__c = gau.Id;
    expense.GP_External_Id__c = '123:1111-000-000:4321';
    insert expense;

    GP_Expense_Data_Import_Event__e event = new GP_Expense_Data_Import_Event__e();
    event.Data__c =
      '{' +
      '"Voucher Number":"123",' +
      '"Description":"Test Description",' +
      '"Vendor Code":"ABCDE",' +
      '"Vendor Name":"Test Vendor",' +
      '"Document Number":"8/07/20",' +
      '"Date":"2020-08-06 00:00:00.000",' +
      '"Document Amount":100.00000,' +
      '"Account Number":"1111-000-000",' +
      '"Analytical Amount":150.0000,' +
      '"Project Code":"4321",' +
      '"Dimension Description":"Test Dimension Description"' +
      '}';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Expense__c> expenses = fetchExpenses();

    System.assertEquals(1, expenses.size());
    System.assertEquals(expense.Id, expenses[0].Id);
    System.assertEquals(150, expenses[0].Amount__c);
    System.assertEquals(Date.newInstance(2020, 8, 6), expenses[0].Date__c);
    System.assertEquals('Test Description', expenses[0].Description__c);
    System.assertEquals(gau.Id, expenses[0].General_Accounting_Unit__c);
    System.assertEquals('123:1111-000-000:4321', expenses[0].GP_External_Id__c);
    System.assertEquals('Test Description - Test Vendor', expenses[0].Title__c);
  }

  @IsTest
  static void testError() {
    GP_Expense_Data_Import_Event__e event = new GP_Expense_Data_Import_Event__e();
    event.Data__c = '';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Expense__c> expenses = fetchExpenses();

    List<Platform_Event_Error__c> errors = [
      SELECT Data__c, Error__c, Origin__c
      FROM Platform_Event_Error__c
    ];

    System.assertEquals(0, expenses.size());
    System.assertEquals(1, errors.size());
    System.assertEquals(null, errors[0].Data__c);
    System.assert(errors[0].Error__c.contains('Event data not found.'));
    System.assertEquals('NJE_Expenses', errors[0].Origin__c);
  }
}