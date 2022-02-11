@IsTest
private class TransferServiceTest {
  @IsTest
  static void testDefaultFundGLAccount() {
    npsp__General_Accounting_Unit__c gau1 = new npsp__General_Accounting_Unit__c();
    gau1.Name = 'GAU 1';
    gau1.npsp__Active__c = true;
    gau1.Purpose_Code__c = '123';

    npsp__General_Accounting_Unit__c gau2 = new npsp__General_Accounting_Unit__c();
    gau2.Name = 'GAU 2';
    gau2.npsp__Active__c = true;
    gau2.Purpose_Code__c = '456';

    List<npsp__General_Accounting_Unit__c> gaus = new List<npsp__General_Accounting_Unit__c>{
      gau1,
      gau2
    };
    insert gaus;

    Fund_GL_Account__c fundGLAccount1 = new Fund_GL_Account__c();
    fundGLAccount1.Active__c = true;
    fundGLAccount1.GL_Account__c = '1234-000-000';
    fundGLAccount1.GL_Account_Prefix__c = '1234';
    fundGLAccount1.GL_Account_External_Id__c = '789:1234-000-000';
    fundGLAccount1.General_Accounting_Unit__c = gau1.Id;
    insert fundGLAccount1;

    Fund_GL_Account__c fundGLAccount2 = new Fund_GL_Account__c();
    fundGLAccount2.Active__c = true;
    fundGLAccount2.GL_Account__c = '4321-000-000';
    fundGLAccount2.GL_Account_Prefix__c = '4321';
    fundGLAccount2.GL_Account_External_Id__c = '456:4321-000-000';
    fundGLAccount2.General_Accounting_Unit__c = gau2.Id;
    insert fundGLAccount2;

    gau1.Default_Fund_GL_Account__c = fundGLAccount1.Id;
    gau2.Default_Fund_GL_Account__c = fundGLAccount2.Id;
    update gaus;

    Transfer__c transfer = new Transfer__c();
    transfer.Amount__c = 100;
    transfer.Date__c = Date.today();
    transfer.Primary_General_Accounting_Unit__c = gau1.Id;
    transfer.Secondary_General_Accounting_Unit__c = gau2.Id;
    transfer.Status__c = 'Pending';
    transfer.Type__c = 'To';

    Test.startTest();
    insert transfer;
    Test.stopTest();

    List<Transfer__c> results = [
      SELECT Fund_GL_Account__c, Id, Reciprocal_Transfer__c
      FROM Transfer__c
      ORDER BY Id
    ];

    System.assertEquals(2, results.size());
    System.assertEquals(transfer.Id, results[0].Id);
    System.assertEquals(results[1].Id, results[0].Reciprocal_Transfer__c);
    System.assertEquals(fundGLAccount1.Id, results[0].Fund_GL_Account__c);
    System.assertEquals(fundGLAccount2.Id, results[1].Fund_GL_Account__c);
  }

  @IsTest
  static void testCreateReciprocalTo() {
    npsp__General_Accounting_Unit__c gau1 = new npsp__General_Accounting_Unit__c();
    gau1.Name = 'GAU 1';
    gau1.npsp__Active__c = true;
    gau1.Purpose_Code__c = '123';

    npsp__General_Accounting_Unit__c gau2 = new npsp__General_Accounting_Unit__c();
    gau2.Name = 'GAU 2';
    gau2.npsp__Active__c = true;
    gau2.Purpose_Code__c = '456';

    insert new List<npsp__General_Accounting_Unit__c>{ gau1, gau2 };

    Transfer__c transfer = new Transfer__c();
    transfer.Amount__c = 100;
    transfer.Date__c = Date.today();
    transfer.Primary_General_Accounting_Unit__c = gau1.Id;
    transfer.Secondary_General_Accounting_Unit__c = gau2.Id;
    transfer.Status__c = 'Pending';
    transfer.Type__c = 'To';

    Test.startTest();
    insert transfer;
    Test.stopTest();

    List<Transfer__c> results = [
      SELECT
        Amount__c,
        Date__c,
        Id,
        Primary_General_Accounting_Unit__c,
        Reciprocal_Transfer__c,
        Secondary_General_Accounting_Unit__c,
        Status__c,
        Type__c
      FROM Transfer__c
      ORDER BY Id
    ];

    System.assertEquals(transfer.Id, results[0].Id);
    System.assertEquals(results[1].Id, results[0].Reciprocal_Transfer__c);
    System.assertEquals(100, results[1].Amount__c);
    System.assertEquals(Date.today(), results[1].Date__c);
    System.assertEquals(transfer.Id, results[1].Reciprocal_Transfer__c);
    System.assertEquals(gau2.Id, results[1].Primary_General_Accounting_Unit__c);
    System.assertEquals(gau1.Id, results[1].Secondary_General_Accounting_Unit__c);
    System.assertEquals('Pending', results[1].Status__c);
    System.assertEquals('From', results[1].Type__c);
  }

  @IsTest
  static void testCreateReciprocalFrom() {
    npsp__General_Accounting_Unit__c gau1 = new npsp__General_Accounting_Unit__c();
    gau1.Name = 'GAU 1';
    gau1.npsp__Active__c = true;
    gau1.Purpose_Code__c = '123';

    npsp__General_Accounting_Unit__c gau2 = new npsp__General_Accounting_Unit__c();
    gau2.Name = 'GAU 2';
    gau2.npsp__Active__c = true;
    gau2.Purpose_Code__c = '456';

    insert new List<npsp__General_Accounting_Unit__c>{ gau1, gau2 };

    Transfer__c transfer = new Transfer__c();
    transfer.Amount__c = 100;
    transfer.Date__c = Date.today();
    transfer.Primary_General_Accounting_Unit__c = gau1.Id;
    transfer.Secondary_General_Accounting_Unit__c = gau2.Id;
    transfer.Status__c = 'Pending';
    transfer.Type__c = 'From';

    Test.startTest();
    insert transfer;
    Test.stopTest();

    List<Transfer__c> results = [
      SELECT
        Amount__c,
        Date__c,
        Id,
        Primary_General_Accounting_Unit__c,
        Reciprocal_Transfer__c,
        Secondary_General_Accounting_Unit__c,
        Status__c,
        Type__c
      FROM Transfer__c
      ORDER BY Id
    ];

    System.assertEquals(transfer.Id, results[0].Id);
    System.assertEquals(results[1].Id, results[0].Reciprocal_Transfer__c);
    System.assertEquals(100, results[1].Amount__c);
    System.assertEquals(Date.today(), results[1].Date__c);
    System.assertEquals(transfer.Id, results[1].Reciprocal_Transfer__c);
    System.assertEquals(gau2.Id, results[1].Primary_General_Accounting_Unit__c);
    System.assertEquals(gau1.Id, results[1].Secondary_General_Accounting_Unit__c);
    System.assertEquals('Pending', results[1].Status__c);
    System.assertEquals('To', results[1].Type__c);
  }

  @IsTest
  static void testStatusUpdate() {
    npsp__General_Accounting_Unit__c gau1 = new npsp__General_Accounting_Unit__c();
    gau1.Name = 'GAU 1';
    gau1.npsp__Active__c = true;
    gau1.Purpose_Code__c = '123';

    npsp__General_Accounting_Unit__c gau2 = new npsp__General_Accounting_Unit__c();
    gau2.Name = 'GAU 2';
    gau2.npsp__Active__c = true;
    gau2.Purpose_Code__c = '456';

    insert new List<npsp__General_Accounting_Unit__c>{ gau1, gau2 };

    Transfer__c transfer = new Transfer__c();
    transfer.Amount__c = 100;
    transfer.Date__c = Date.today();
    transfer.Primary_General_Accounting_Unit__c = gau1.Id;
    transfer.Secondary_General_Accounting_Unit__c = gau2.Id;
    transfer.Status__c = 'Pending';
    transfer.Type__c = 'To';

    Test.startTest();
    insert transfer;
    transfer.Status__c = 'Complete';
    update transfer;
    Test.stopTest();

    List<Transfer__c> results = [
      SELECT
        Amount__c,
        Date__c,
        Id,
        Primary_General_Accounting_Unit__c,
        Reciprocal_Transfer__c,
        Secondary_General_Accounting_Unit__c,
        Status__c,
        Type__c
      FROM Transfer__c
      ORDER BY Id
    ];

    System.assertEquals(transfer.Id, results[0].Id);
    System.assertEquals(results[1].Id, results[0].Reciprocal_Transfer__c);
    System.assertEquals('Complete', results[0].Status__c);
    System.assertEquals(100, results[1].Amount__c);
    System.assertEquals(Date.today(), results[1].Date__c);
    System.assertEquals(transfer.Id, results[1].Reciprocal_Transfer__c);
    System.assertEquals(gau2.Id, results[1].Primary_General_Accounting_Unit__c);
    System.assertEquals(gau1.Id, results[1].Secondary_General_Accounting_Unit__c);
    System.assertEquals('Complete', results[1].Status__c);
    System.assertEquals('From', results[1].Type__c);
  }
}