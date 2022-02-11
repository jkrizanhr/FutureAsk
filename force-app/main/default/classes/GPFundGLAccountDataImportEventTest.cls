@IsTest
private class GPFundGLAccountDataImportEventTest {
  /**
   * Utility method to retrieve platform event error results
   */
  private static List<Platform_Event_Error__c> fetchPlatformEventErrors() {
    return [SELECT Data__c, Error__c, Origin__c FROM Platform_Event_Error__c];
  }

  /**
   * Utility method to retrieve fund gl accounts
   */
  private static List<Fund_GL_Account__c> fetchFundGLAccounts() {
    return [
      SELECT
        Active__c,
        General_Accounting_Unit__c,
        GL_Account__c,
        GL_Account_Description__c,
        GL_Account_External_Id__c,
        GL_Account_Prefix__c,
        Id,
        Name
      FROM Fund_GL_Account__c
    ];
  }

  @IsTest
  static void testNewData() {
    GP_Fund_GL_Account_Data_Import_Event__e event = new GP_Fund_GL_Account_Data_Import_Event__e();
    event.Data__c =
      '{' +
      '"ACTDESCR":"Test Fund Description",' +
      '"ACTNUMBR_1":"1010",' +
      '"ACTNUMST":"1010-000-123",' +
      '"aaTrxDimCode":"4321",' +
      '"aaTrxDimCodeDescr":"Test GAU",' +
      '"aaTrxDimCodeDescr2":"Test GAU Description",' +
      '"INACTIVE": 1' +
      '}';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Platform_Event_Error__c> errors = fetchPlatformEventErrors();
    List<Fund_GL_Account__c> glFundAccounts = fetchFundGLAccounts();

    System.assertEquals(0, errors.size());
    System.assertEquals(1, glFundAccounts.size());
    System.assertEquals('1010-000-123', glFundAccounts[0].GL_Account__c);
    System.assertEquals('Test Fund Description', glFundAccounts[0].GL_Account_Description__c);
    System.assertEquals('4321:1010-000-123', glFundAccounts[0].GL_Account_External_Id__c);
    System.assertEquals('1010', glFundAccounts[0].GL_Account_Prefix__c);
    System.assertEquals('1010-000-123', glFundAccounts[0].Name);
  }

  @IsTest
  static void testNewFundGLAccountExistingGAU() {
    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c();
    gau.Name = 'A Sample GAU';
    gau.npsp__Active__c = true;
    gau.Purpose_Code__c = '1234';
    insert gau;

    GP_Fund_GL_Account_Data_Import_Event__e event = new GP_Fund_GL_Account_Data_Import_Event__e();
    event.Data__c =
      '{' +
      '"ACTDESCR":"Test Fund Description",' +
      '"ACTNUMBR_1":"1111",' +
      '"ACTNUMST":"1111-000-123",' +
      '"aaTrxDimCode":"1234",' +
      '"aaTrxDimCodeDescr":"Test GAU",' +
      '"aaTrxDimCodeDescr2":"Test GAU Description",' +
      '"INACTIVE": 0' +
      '}';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Platform_Event_Error__c> errors = fetchPlatformEventErrors();
    List<Fund_GL_Account__c> glFundAccounts = fetchFundGLAccounts();

    System.assertEquals(0, errors.size());

    System.assertEquals(1, glFundAccounts.size());
    System.assertEquals(gau.Id, glFundAccounts[0].General_Accounting_Unit__c);
    System.assertEquals('1111-000-123', glFundAccounts[0].GL_Account__c);
    System.assertEquals('Test Fund Description', glFundAccounts[0].GL_Account_Description__c);
    System.assertEquals('1234:1111-000-123', glFundAccounts[0].GL_Account_External_Id__c);
    System.assertEquals('1111', glFundAccounts[0].GL_Account_Prefix__c);
    System.assertEquals('1111-000-123', glFundAccounts[0].Name);
  }

  @IsTest
  static void testExistingFundGLAccount() {
    Fund_GL_Account__c glFundAccount = new Fund_GL_Account__c();
    glFundAccount.Active__c = true;
    glFundAccount.GL_Account__c = '1234-000-000';
    glFundAccount.GL_Account_External_Id__c = '317:1234-000-000';
    glFundAccount.GL_Account_Prefix__c = '1234';
    glFundAccount.Name = 'Test Fund GL Account';
    insert glFundAccount;

    GP_Fund_GL_Account_Data_Import_Event__e event = new GP_Fund_GL_Account_Data_Import_Event__e();
    event.Data__c =
      '{' +
      '"ACTDESCR":"Test Fund Description",' +
      '"ACTNUMBR_1":"1234",' +
      '"ACTNUMST":"1234-000-000",' +
      '"aaTrxDimCode":"317",' +
      '"aaTrxDimCodeDescr":"Test GAU",' +
      '"aaTrxDimCodeDescr2":"Test GAU Description",' +
      '"INACTIVE": 0' +
      '}';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Platform_Event_Error__c> errors = fetchPlatformEventErrors();
    List<Fund_GL_Account__c> glFundAccounts = fetchFundGLAccounts();

    System.assertEquals(0, errors.size());
    System.assertEquals(1, glFundAccounts.size());
    System.assertEquals('1234-000-000', glFundAccounts[0].GL_Account__c);
    System.assertEquals('Test Fund Description', glFundAccounts[0].GL_Account_Description__c);
    System.assertEquals('317:1234-000-000', glFundAccounts[0].GL_Account_External_Id__c);
    System.assertEquals('1234', glFundAccounts[0].GL_Account_Prefix__c);
    System.assertEquals('Test Fund GL Account', glFundAccounts[0].Name);
  }

  @IsTest
  static void testError() {
    GP_Fund_GL_Account_Data_Import_Event__e event = new GP_Fund_GL_Account_Data_Import_Event__e();
    event.Data__c = '';

    Test.startTest();
    EventBus.publish(event);
    Test.stopTest();

    List<Platform_Event_Error__c> errors = fetchPlatformEventErrors();
    List<Fund_GL_Account__c> glFundAccounts = fetchFundGLAccounts();

    System.assertEquals(1, errors.size());
    System.assertEquals(0, glFundAccounts.size());
    System.assertEquals(null, errors[0].Data__c);
    System.assert(errors[0].Error__c.contains('Event data not found.'));
    System.assertEquals('AAG00201', errors[0].Origin__c);
  }
}