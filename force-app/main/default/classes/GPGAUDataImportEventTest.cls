@IsTest
private class GPGAUDataImportEventTest {
  /**
   * Utility method to retrieve general accounting unit results
   */
  private static List<npsp__General_Accounting_Unit__c> fetchGeneralAccountingUnits() {
    return [
      SELECT
        GP_Active__c,
        GP_Dim_Code_Description__c,
        GP_Dim_Code_Description_2__c,
        Id,
        Name,
        npsp__Description__c,
        Purpose_Code__c
      FROM npsp__General_Accounting_Unit__c
    ];
  }

  /**
   * Utility method to retrieve platform event error results
   */
  private static List<Platform_Event_Error__c> fetchPlatformEventErrors() {
    return [SELECT Data__c, Error__c, Origin__c FROM Platform_Event_Error__c];
  }

  @IsTest
  static void testNewGAU() {
    GP_GAU_Data_Import_Event__e event = new GP_GAU_Data_Import_Event__e();
    event.Data__c =
      '{' +
      '"aaTrxDimID":1,' +
      '"aaTrxDimCodeID":123,' +
      '"aaTrxDimCode":"1234",' +
      '"aaTrxDimCodeDescr":"Test GAU",' +
      '"aaTrxDimCodeDescr2":"Test Description",' +
      '"NOTEINDX":1231234,' +
      '"INACTIVE": 0,' +
      '"DEX_ROW_TS": "24:56:4",' +
      '"DEX_ROW_ID": 101' +
      '}';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<npsp__General_Accounting_Unit__c> gaus = fetchGeneralAccountingUnits();
    List<Platform_Event_Error__c> errors = fetchPlatformEventErrors();

    System.assertEquals(1, gaus.size());
    System.assertEquals(0, errors.size());
    System.assertEquals('1234 - Test GAU', gaus[0].Name);
    System.assertEquals(true, gaus[0].GP_Active__c);
    System.assertEquals('Test GAU', gaus[0].GP_Dim_Code_Description__c);
    System.assertEquals('Test Description', gaus[0].GP_Dim_Code_Description_2__c);
    System.assertEquals('Test Description', gaus[0].npsp__Description__c);
  }

  @IsTest
  static void testExistingGAU() {
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'A Sample GAU';
    gau.npsp__Active__c = false;
    gau.Purpose_Code__c = '5678';
    insert gau;

    GP_GAU_Data_Import_Event__e event = new GP_GAU_Data_Import_Event__e();
    event.Data__c =
      '{' +
      '"aaTrxDimID":1,' +
      '"aaTrxDimCodeID":121,' +
      '"aaTrxDimCode":"5678",' +
      '"aaTrxDimCodeDescr":"Test GAU",' +
      '"aaTrxDimCodeDescr2":"Test Description",' +
      '"NOTEINDX":1231234,' +
      '"INACTIVE": 1,' +
      '"DEX_ROW_TS": "24:56:4",' +
      '"DEX_ROW_ID": 101' +
      '}';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<npsp__General_Accounting_Unit__c> gaus = fetchGeneralAccountingUnits();
    List<Platform_Event_Error__c> errors = fetchPlatformEventErrors();

    System.assertEquals(1, gaus.size());
    System.assertEquals(0, errors.size());

    System.assertEquals(gau.Id, gaus[0].Id);
    System.assertEquals('A Sample GAU', gaus[0].Name);
    System.assertEquals(false, gaus[0].GP_Active__c);
    System.assertEquals('Test GAU', gaus[0].GP_Dim_Code_Description__c);
    System.assertEquals('Test Description', gaus[0].GP_Dim_Code_Description_2__c);
    System.assertEquals(null, gaus[0].npsp__Description__c);
  }

  @IsTest
  static void testError() {
    GP_GAU_Data_Import_Event__e event = new GP_GAU_Data_Import_Event__e();
    event.Data__c = '';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<npsp__General_Accounting_Unit__c> gaus = fetchGeneralAccountingUnits();
    List<Platform_Event_Error__c> errors = fetchPlatformEventErrors();

    System.assertEquals(0, gaus.size());
    System.assertEquals(1, errors.size());
    System.assertEquals('AAG00401', errors[0].Origin__c);
    System.assertEquals(null, errors[0].Data__c);
    System.assert(String.isNotBlank(errors[0].Error__c));
  }
}