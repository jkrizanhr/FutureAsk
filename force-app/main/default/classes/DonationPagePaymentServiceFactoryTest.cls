@isTest
private class DonationPagePaymentServiceFactoryTest {
  @isTest
  static void testFactory() {
    Test.startTest();

    DonationPagePaymentService service = DonationPagePaymentServiceFactory.getPaymentService('Test', 'Sandbox', true);
    System.assert(service instanceof DonationPageTestPaymentService);

    service = DonationPagePaymentServiceFactory.getPaymentService('INVALID', 'Sandbox', true);
    System.assertEquals(null, service);

    Test.stopTest();
  }
}