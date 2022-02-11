public class DonationPagePaymentServiceFactory {
  public static DonationPagePaymentService getPaymentService(String processor, String settingsName, Boolean testMode) {
    Type t = null;
    if (processor == 'Authorize.net') {
      t = Type.forName('DonationPageAuthNetPaymentService');
    } else if (processor == 'Stripe') {
      t = Type.forName('DonationPageStripePaymentService');
    } else if (processor == 'Test') {
      t = Type.forName('DonationPageTestPaymentService');
    }

    if (t != null) {
      DonationPagePaymentService service = (DonationPagePaymentService) t.newInstance();
      if (String.isNotBlank(settingsName)) {
        service.setPaymentSettings(settingsName);
      }
      if (testMode) {
        service.enableTestMode();
      }
      return service;
    }
    return null;
  }
}