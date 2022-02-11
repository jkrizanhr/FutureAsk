@IsTest
private class DocumentFieldValidationHelper_Test {
  @IsTest
  static void testBehavior() {
    DocumentGenerationTestHelper.createSampleTestData();

    List<SObject> records = [
      SELECT Id, Name, (SELECT Id, Name FROM Contacts), npe01__One2OneContact__r.Name
      FROM Account
      WHERE Name = 'Test Organization'
    ];

    Test.startTest();
    Boolean result1 = DocGenFieldService.validateField(records[0], 'npe01__One2OneContact__r.Name');
    Boolean result2 = DocGenFieldService.validateField(records[0], 'Contacts[0].Name');
    Boolean result3 = DocGenFieldService.validateField(records[0], 'FakeContacts[0].Name');
    Boolean result4 = DocGenFieldService.validateField(records[0], '');
    Test.stopTest();

    System.assertEquals(true, result1);
    System.assertEquals(true, result2);
    System.assertEquals(false, result3);
    System.assertEquals(false, result4);
  }
}