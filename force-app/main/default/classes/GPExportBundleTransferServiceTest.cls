@IsTest
private class GPExportBundleTransferServiceTest {
  private static List<GP_Export_Bundle__c> retrieveBundles() {
    return [
      SELECT
        End_Date__c,
        Fund_GL_Error_Message__c,
        Fund_GL_Validation_Check__c,
        Id,
        Name,
        Start_Date__c,
        Validation_Error__c
      FROM GP_Export_Bundle__c
    ];
  }

  private static List<GP_Export_AAGL_Row__c> retrieveAAGLRows() {
    return [
      SELECT
        Checkbook__c,
        Donation_Amount__c,
        Donation_Batch_Number__c,
        Donation_Date__c,
        Donation_ID__c,
        GAU_Allocation__c,
        GP_Export_Bundle__c,
        GP_Full_Account__c,
        GP_Natural_Account__c,
        Id,
        Name,
        Purpose_Code__c,
        SeqID__c,
        Transfer__c
      FROM GP_Export_AAGL_Row__c
      ORDER BY Checkbook__c NULLS LAST
    ];
  }

  private static List<Transfer__c> retrieveTransfers() {
    return [
      SELECT
        Amount__c,
        Date__c,
        Fund_GL_Account__c,
        GP_Export_Bundle__c,
        GP_Export_Error__c,
        Id,
        Primary_General_Accounting_Unit__c,
        Reciprocal_Transfer__c,
        Secondary_General_Accounting_Unit__c,
        Status__c,
        Type__c
      FROM Transfer__c
      ORDER BY Id
    ];
  }

  @IsTest
  static void testSuccess() {
    npsp__General_Accounting_Unit__c gau1 = new npsp__General_Accounting_Unit__c();
    gau1.Name = 'GAU 1';
    gau1.npsp__Active__c = true;
    gau1.Purpose_Code__c = '789';

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

    GP_Export_Bundle__c bundle = new GP_Export_Bundle__c();
    bundle.Start_Date__c = Date.today();
    bundle.End_Date__c = Date.today();
    bundle.RecordTypeId = Utils.getRecordTypeId('GP_Export_Bundle__c', 'GAU Reclass');

    Test.startTest();
    insert transfer;
    insert bundle;
    Test.stopTest();

    List<GP_Export_Bundle__c> bundles = retrieveBundles();
    List<Transfer__c> transfers = retrieveTransfers();
    List<GP_Export_AAGL_Row__c> aaglRows = retrieveAAGLRows();

    // GP Export Bundle Assertions
    System.assertEquals(Date.today(), bundles[0].End_Date__c);
    System.assertEquals('Check Transaction Numbers', bundles[0].Fund_GL_Validation_Check__c);
    System.assertEquals(Date.today(), bundles[0].Start_Date__c);
    System.assertEquals(false, bundles[0].Validation_Error__c);
    System.assertEquals(null, bundles[0].Fund_GL_Error_Message__c);

    // Transfer Assertions
    System.assertEquals(2, transfers.size());
    System.assertEquals(bundles[0].Id, transfers[0].GP_Export_Bundle__c);
    System.assertEquals(null, transfers[0].GP_Export_Error__c);
    System.assertEquals(bundles[0].Id, transfers[1].GP_Export_Bundle__c);
    System.assertEquals(null, transfers[1].GP_Export_Error__c);

    // GP Export AAGL Row Assertions
    System.assertEquals(null, aaglRows[0].Checkbook__c);
    System.assertEquals(100, aaglRows[0].Donation_Amount__c);
    System.assertEquals(bundles[0].Name, aaglRows[0].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today()), aaglRows[0].Donation_Date__c);
    System.assertEquals(transfer.Id, aaglRows[0].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[0].GP_Export_Bundle__c);
    System.assertEquals('1234-000-000', aaglRows[0].GP_Full_Account__c);
    System.assertEquals('1234', aaglRows[0].GP_Natural_Account__c);
    System.assertEquals('789', aaglRows[0].Purpose_Code__c);
    System.assertEquals(null, aaglRows[0].GAU_Allocation__c);
    System.assertEquals(1, aaglRows[0].SeqID__c);
    System.assertEquals(transfer.Id, aaglRows[0].Transfer__c);

    System.assertEquals(null, aaglRows[1].Checkbook__c);
    System.assertEquals(100, aaglRows[1].Donation_Amount__c);
    System.assertEquals(bundles[0].Name, aaglRows[1].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today()), aaglRows[1].Donation_Date__c);
    System.assertEquals(transfers[1].Id, aaglRows[1].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[1].GP_Export_Bundle__c);
    System.assertEquals('4321-000-000', aaglRows[1].GP_Full_Account__c);
    System.assertEquals('4321', aaglRows[1].GP_Natural_Account__c);
    System.assertEquals('456', aaglRows[1].Purpose_Code__c);
    System.assertEquals(null, aaglRows[1].GAU_Allocation__c);
    System.assertEquals(2, aaglRows[1].SeqID__c);
    System.assertEquals(transfers[1].Id, aaglRows[1].Transfer__c);
  }

  @IsTest
  static void testInactiveGAU() {
    npsp__General_Accounting_Unit__c gau1 = new npsp__General_Accounting_Unit__c();
    gau1.Name = 'GAU 1';
    gau1.npsp__Active__c = true;
    gau1.Purpose_Code__c = '1234';

    npsp__General_Accounting_Unit__c gau2 = new npsp__General_Accounting_Unit__c();
    gau2.Name = 'GAU 2';
    gau2.npsp__Active__c = true;
    gau2.Purpose_Code__c = '4567';

    List<npsp__General_Accounting_Unit__c> gaus = new List<npsp__General_Accounting_Unit__c>{
      gau1,
      gau2
    };
    insert gaus;

    Fund_GL_Account__c fundGLAccount1 = new Fund_GL_Account__c();
    fundGLAccount1.Active__c = false;
    fundGLAccount1.GL_Account__c = '1234-000-000';
    fundGLAccount1.GL_Account_Prefix__c = '1234';
    fundGLAccount1.GL_Account_External_Id__c = '1234:1234-000-000';
    fundGLAccount1.General_Accounting_Unit__c = gau1.Id;
    insert fundGLAccount1;

    Fund_GL_Account__c fundGLAccount2 = new Fund_GL_Account__c();
    fundGLAccount2.Active__c = true;
    fundGLAccount2.GL_Account__c = '4321-000-000';
    fundGLAccount2.GL_Account_Prefix__c = '4321';
    fundGLAccount2.GL_Account_External_Id__c = '4567:4321-000-000';
    fundGLAccount2.General_Accounting_Unit__c = gau2.Id;
    insert fundGLAccount2;

    gau1.Default_Fund_GL_Account__c = fundGLAccount1.Id;
    gau2.Default_Fund_GL_Account__c = fundGLAccount2.Id;
    update gaus;

    gau1.npsp__Active__c = false;
    update gau1;

    Transfer__c transfer = new Transfer__c();
    transfer.Amount__c = 100;
    transfer.Date__c = Date.today();
    transfer.Primary_General_Accounting_Unit__c = gau1.Id;
    transfer.Secondary_General_Accounting_Unit__c = gau2.Id;
    transfer.Status__c = 'Pending';
    transfer.Type__c = 'To';

    GP_Export_Bundle__c bundle = new GP_Export_Bundle__c();
    bundle.Start_Date__c = Date.today();
    bundle.End_Date__c = Date.today();
    bundle.RecordTypeId = Utils.getRecordTypeId('GP_Export_Bundle__c', 'GAU Reclass');

    Test.startTest();
    insert transfer;
    insert bundle;
    Test.stopTest();

    List<GP_Export_Bundle__c> bundles = retrieveBundles();
    List<Transfer__c> transfers = retrieveTransfers();
    List<GP_Export_AAGL_Row__c> aaglRows = retrieveAAGLRows();

    // GP Export Bundle Assertions
    System.assertEquals(1, bundles.size());
    System.assertEquals(Date.today(), bundles[0].End_Date__c);
    System.assertEquals('Check GAUs', bundles[0].Fund_GL_Validation_Check__c);
    System.assertEquals(Date.today(), bundles[0].Start_Date__c);
    System.assertEquals(true, bundles[0].Validation_Error__c);
    System.assertNotEquals(null, bundles[0].Fund_GL_Error_Message__c);

    // Transfer Assertions
    System.assertEquals(2, transfers.size());

    System.assertEquals(bundles[0].Id, transfers[0].GP_Export_Bundle__c);
    System.assertNotEquals(null, transfers[0].GP_Export_Error__c);

    System.assertEquals(bundles[0].Id, transfers[1].GP_Export_Bundle__c);
    System.assertEquals(null, transfers[1].GP_Export_Error__c);

    // GP Export AAGL Row Assertions
    System.assertEquals(2, aaglRows.size());

    System.assertEquals(null, aaglRows[0].Checkbook__c);
    System.assertEquals(100, aaglRows[0].Donation_Amount__c);
    System.assertEquals(bundles[0].Name, aaglRows[0].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today()), aaglRows[0].Donation_Date__c);
    System.assertEquals(transfer.Id, aaglRows[0].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[0].GP_Export_Bundle__c);
    System.assertEquals('1234-000-000', aaglRows[0].GP_Full_Account__c);
    System.assertEquals('1234', aaglRows[0].GP_Natural_Account__c);
    System.assertEquals('1234', aaglRows[0].Purpose_Code__c);
    System.assertEquals(null, aaglRows[0].GAU_Allocation__c);
    System.assertEquals(1, aaglRows[0].SeqID__c);
    System.assertEquals(transfer.Id, aaglRows[0].Transfer__c);

    System.assertEquals(null, aaglRows[1].Checkbook__c);
    System.assertEquals(100, aaglRows[1].Donation_Amount__c);
    System.assertEquals(bundles[0].Name, aaglRows[1].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today()), aaglRows[1].Donation_Date__c);
    System.assertEquals(transfers[1].Id, aaglRows[1].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[1].GP_Export_Bundle__c);
    System.assertEquals('4321-000-000', aaglRows[1].GP_Full_Account__c);
    System.assertEquals('4321', aaglRows[1].GP_Natural_Account__c);
    System.assertEquals('4567', aaglRows[1].Purpose_Code__c);
    System.assertEquals(null, aaglRows[1].GAU_Allocation__c);
    System.assertEquals(2, aaglRows[1].SeqID__c);
    System.assertEquals(transfers[1].Id, aaglRows[1].Transfer__c);
  }

  @IsTest
  static void test() {
    npsp__General_Accounting_Unit__c gau1 = new npsp__General_Accounting_Unit__c();
    gau1.Name = 'GAU 1';
    gau1.npsp__Active__c = true;
    gau1.Purpose_Code__c = '1234';

    npsp__General_Accounting_Unit__c gau2 = new npsp__General_Accounting_Unit__c();
    gau2.Name = 'GAU 2';
    gau2.npsp__Active__c = true;
    gau2.Purpose_Code__c = '4567';

    List<npsp__General_Accounting_Unit__c> gaus = new List<npsp__General_Accounting_Unit__c>{
      gau1,
      gau2
    };
    insert gaus;

    Fund_GL_Account__c fundGLAccount1 = new Fund_GL_Account__c();
    fundGLAccount1.Active__c = false;
    fundGLAccount1.GL_Account__c = '1234-000-000';
    fundGLAccount1.GL_Account_Prefix__c = '1234';
    fundGLAccount1.GL_Account_External_Id__c = '1234:1234-000-000';
    fundGLAccount1.General_Accounting_Unit__c = gau1.Id;

    Fund_GL_Account__c fundGLAccount2 = new Fund_GL_Account__c();
    fundGLAccount2.Active__c = true;
    fundGLAccount2.GL_Account__c = '4321-000-000';
    fundGLAccount2.GL_Account_Prefix__c = '4321';
    fundGLAccount2.GL_Account_External_Id__c = '4567:4321-000-000';
    fundGLAccount2.General_Accounting_Unit__c = gau2.Id;

    insert new List<Fund_GL_Account__c>{ fundGLAccount1, fundGLAccount2 };

    Transfer__c transfer = new Transfer__c();
    transfer.Amount__c = 100;
    transfer.Date__c = Date.today();
    transfer.Primary_General_Accounting_Unit__c = gau1.Id;
    transfer.Secondary_General_Accounting_Unit__c = gau2.Id;
    transfer.Status__c = 'Pending';
    transfer.Type__c = 'To';
    transfer.Fund_GL_Account__c = fundGLAccount2.Id;

    GP_Export_Bundle__c bundle = new GP_Export_Bundle__c();
    bundle.Start_Date__c = Date.today();
    bundle.End_Date__c = Date.today();
    bundle.RecordTypeId = Utils.getRecordTypeId('GP_Export_Bundle__c', 'GAU Reclass');

    Test.startTest();
    insert transfer;
    insert bundle;
    Test.stopTest();

    List<GP_Export_Bundle__c> bundles = retrieveBundles();
    List<Transfer__c> transfers = retrieveTransfers();
    List<GP_Export_AAGL_Row__c> aaglRows = retrieveAAGLRows();

    // GP Export Bundle Assertions
    System.assertEquals(1, bundles.size());
    System.assertEquals(Date.today(), bundles[0].End_Date__c);
    System.assertEquals('Check GAUs', bundles[0].Fund_GL_Validation_Check__c);
    System.assertEquals(Date.today(), bundles[0].Start_Date__c);
    System.assertEquals(true, bundles[0].Validation_Error__c);
    System.assertNotEquals(null, bundles[0].Fund_GL_Error_Message__c);

    // Transfer Assertions
    System.assertEquals(2, transfers.size());

    System.assertEquals(bundles[0].Id, transfers[0].GP_Export_Bundle__c);
    System.assertNotEquals(null, transfers[0].GP_Export_Error__c);

    System.assertEquals(bundles[0].Id, transfers[1].GP_Export_Bundle__c);
    System.assertNotEquals(null, transfers[1].GP_Export_Error__c);

    // GP Export AAGL Row Assertions
    System.assertEquals(1, aaglRows.size());

    System.assertEquals(null, aaglRows[0].Checkbook__c);
    System.assertEquals(100, aaglRows[0].Donation_Amount__c);
    System.assertEquals(bundles[0].Name, aaglRows[0].Donation_Batch_Number__c);
    System.assertEquals(String.valueOf(Date.today()), aaglRows[0].Donation_Date__c);
    System.assertEquals(transfer.Id, aaglRows[0].Donation_ID__c);
    System.assertEquals(bundles[0].Id, aaglRows[0].GP_Export_Bundle__c);
    System.assertEquals('4321-000-000', aaglRows[0].GP_Full_Account__c);
    System.assertEquals('4321', aaglRows[0].GP_Natural_Account__c);
    System.assertEquals('1234', aaglRows[0].Purpose_Code__c);
    System.assertEquals(null, aaglRows[0].GAU_Allocation__c);
    System.assertEquals(1, aaglRows[0].SeqID__c);
    System.assertEquals(transfer.Id, aaglRows[0].Transfer__c);
  }
}