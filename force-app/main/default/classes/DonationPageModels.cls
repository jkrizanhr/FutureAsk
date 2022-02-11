global class DonationPageModels {
  global class FormData {
    public Id campaignId { get; set; }
    public String stripePublicKey { get; set; }
    public String authNetClientKey { get; set; }
    public String authNetAPILoginId { get; set; }
    public Campaign campaign { get; set; }
    public List<DonationOption> donationOptions { get; set; }
    public Map<String, List<Schema.PicklistEntry>> selectOptions { get; set; }
  }

  global class FormSubmission {
    public Id campaignId { get; set; }
    public Donation_Form_Submission__c dfs { get; set; }
    public List<DonationOption> chosenOptions { get; set; }
    public String stripeToken { get; set; }
    public String stripeSourceId { get; set; }
    public String authNetOpaqueDataDescriptor { get; set; }
    public String authNetOpaqueDataDataValue { get; set; }
    public Long submissionTimestamp { get; set; }
    public String submissionDate { get; set; }
  }

  global class DonationOption {
    public Donation_Option__c option { get; set; }
    public Decimal amount { get; set; }
    public String frequency { get; set; }
    public Integer frequencyInterval { get; set; }
    public Integer numPayments { get; set; }

    global DonationOption(Donation_Option__c donOpt) {
      this.option = donOpt;
      this.amount = donOpt.Allow_Custom_Amount__c == true
        ? null
        : donOpt.Amount__c;
    }
  }

  global class FormResponse {
    public Boolean success { get; set; }
    public String error { get; set; }
    public Id donationFormSubmissionId { get; set; }
    public Decimal donationAmount { get; set; }
    public Decimal totalAmount { get; set; }
  }

  global class PaymentResponse {
    public Boolean success { get; set; }
    public String error { get; set; }
    public String type { get; set; }
    public String transactionId { get; set; }
    public String subscriptionId { get; set; }
    public String customerId { get; set; }
    public String paymentProfileId { get; set; }
    public List<OptionResponse> optionResponses { get; set; }
    public String status { get; set; }
    public Datetime createTime { get; set; }
  }

  global class OptionResponse {
    public Boolean success { get; set; }
    public String error { get; set; }
    public String subscriptionId { get; set; }
    public Id donOptId { get; set; }
  }
}