@isTest
public class DonationPageTestPaymentService implements DonationPagePaymentService {
  /*
    This is the payment service class that is used in all unit tests for the donation page controller
  */

  private Boolean isTestMode;

  public DonationPageTestPaymentService() {
    this.isTestMode = false;
  }

  public void setPublicKey(DonationPageModels.FormData fd) {
    fd.stripePublicKey = 'public_key';
    fd.authNetClientKey = 'client_Key';
    fd.authNetAPILoginId = 'login_id';
  }
  public DonationPageModels.PaymentResponse createOneTimePayment(
    DonationPageModels.FormSubmission submission,
    DonationPageModels.PaymentResponse res
  ) {
    res.success = false;
    res.error = 'One-time payments are set up to fail in tests to test error handling.';
    res.type = 'One-time';
    return res;
  }
  public DonationPageModels.PaymentResponse createRecurringPayment(
    DonationPageModels.FormSubmission submission,
    DonationPageModels.PaymentResponse res
  ) {
    res.success = true;
    res.transactionId = 'ch_1234567890';
    res.subscriptionId = 'sub_0987654321';
    res.status = 'succeeded';
    res.type = 'Standard Recurring';
    return res;
  }
  public DonationPageModels.PaymentResponse createMultiFrequencyRecurringPayment(
    DonationPageModels.FormSubmission submission,
    DonationPageModels.PaymentResponse res
  ) {
    res.success = true;
    res.transactionId = 'ch_1234567890';
    res.status = 'succeeded';
    res.type = 'Per Option Recurring';
    res.optionResponses = new List<DonationPageModels.OptionResponse>();
    for (DonationPageModels.DonationOption option : submission.chosenOptions) {
      DonationPageModels.OptionResponse optRes = new DonationPageModels.OptionResponse();
      optRes.success = true;
      optRes.subscriptionId = 'sub_' + option.option.Id;
      optRes.donOptId = option.option.Id;
      res.optionResponses.add(optRes);
    }
    return res;
  }
  public void enableTestMode() {
    this.isTestMode = true;
  }
  public void setPaymentSettings(String settingsName) {
  }
}