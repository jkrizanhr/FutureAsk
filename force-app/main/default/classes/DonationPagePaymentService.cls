public interface DonationPagePaymentService {
  /*
    This interface class defines the required methods that need to exist in any Donation Page Payment Service class in order for the page to behave properly
  */

  void setPublicKey(DonationPageModels.FormData fd);
  DonationPageModels.PaymentResponse createOneTimePayment(DonationPageModels.FormSubmission submission, DonationPageModels.PaymentResponse res);
  DonationPageModels.PaymentResponse createRecurringPayment(DonationPageModels.FormSubmission submission, DonationPageModels.PaymentResponse res);
  DonationPageModels.PaymentResponse createMultiFrequencyRecurringPayment(
    DonationPageModels.FormSubmission submission,
    DonationPageModels.PaymentResponse res
  );
  void enableTestMode();
  void setPaymentSettings(String settingsName);
}