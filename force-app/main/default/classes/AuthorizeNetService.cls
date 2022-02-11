public class AuthorizeNetService {
  private AuthorizeNetModels.merchantAuthenticationType merchantAuthentication;
  @TestVisible
  private String url;

  public AuthorizeNetService(
    String apiLoginId,
    String transactionKey,
    Boolean sandbox
  ) {
    this.merchantAuthentication = new AuthorizeNetModels.merchantAuthenticationType(
      apiLoginId,
      transactionKey
    );
    this.url =
      'https://api' +
      (sandbox ? 'test' : '') +
      '.authorize.net/xml/v1/request.api';
  }

  private HttpResponse sendRequest(String body) {
    HttpRequest req = new HttpRequest();
    req.setBody(body);
    req.setEndpoint(this.url);
    req.setHeader('Content-Type', 'text/xml');
    req.setMethod('POST');
    req.setTimeout(30000);
    Http http = new Http();
    return http.send(req);
  }

  public AuthorizeNetModels.createTransactionResponse createTransaction(
    AuthorizeNetModels.transactionRequestType tr,
    String refId
  ) {
    String xml = new AuthorizeNetModels.createTransactionRequest(
        this.merchantAuthentication,
        refId,
        tr
      )
      .toXML();
    HttpResponse res = sendRequest(xml);
    return new AuthorizeNetModels.createTransactionResponse(res);
  }

  public AuthorizeNetModels.ARBGetSubscriptionResponse getSubscription(
    String subscriptionId,
    String refId
  ) {
    HttpResponse res = sendRequest(
      new AuthorizeNetModels.ARBGetSubscriptionRequest(
          this.merchantAuthentication,
          refId,
          subscriptionId
        )
        .toXML()
    );
    return new AuthorizeNetModels.ARBGetSubscriptionResponse(res);
  }

  public AuthorizeNetModels.ARBGetSubscriptionStatusResponse getSubscriptionStatus(
    String subscriptionId,
    String refId
  ) {
    HttpResponse res = sendRequest(
      new AuthorizeNetModels.ARBGetSubscriptionStatusRequest(
          this.merchantAuthentication,
          refId,
          subscriptionId
        )
        .toXML()
    );
    return new AuthorizeNetModels.ARBGetSubscriptionStatusResponse(res);
  }

  public AuthorizeNetModels.ARBCreateSubscriptionResponse createSubscription(
    AuthorizeNetModels.ARBSubscriptionType sub,
    String refId
  ) {
    HttpResponse res = sendRequest(
      new AuthorizeNetModels.ARBCreateSubscriptionRequest(
          this.merchantAuthentication,
          refId,
          sub
        )
        .toXML()
    );
    return new AuthorizeNetModels.ARBCreateSubscriptionResponse(res);
  }

  public AuthorizeNetModels.ARBUpdateSubscriptionResponse updateSubscription(
    AuthorizeNetModels.ARBSubscriptionType sub,
    String subscriptionId,
    String refId
  ) {
    HttpResponse res = sendRequest(
      new AuthorizeNetModels.ARBUpdateSubscriptionRequest(
          this.merchantAuthentication,
          refId,
          subscriptionId,
          sub
        )
        .toXML()
    );
    return new AuthorizeNetModels.ARBUpdateSubscriptionResponse(res);
  }

  public AuthorizeNetModels.ARBCancelSubscriptionResponse cancelSubscription(
    String subscriptionId,
    String refId
  ) {
    HttpResponse res = sendRequest(
      new AuthorizeNetModels.ARBCancelSubscriptionRequest(
          this.merchantAuthentication,
          refId,
          subscriptionId
        )
        .toXML()
    );
    return new AuthorizeNetModels.ARBCancelSubscriptionResponse(res);
  }

  public AuthorizeNetModels.getSettledBatchListResponse getSettledBatchList(
    Datetime firstSettlementDate,
    Datetime lastSettlementDate,
    Boolean includeStatistics,
    String refId
  ) {
    String firstSettlementDateStr = firstSettlementDate.formatGMT(
      'yyyy-MM-dd\'T\'HH:mm:ss\'Z\''
    );
    String lastSettlementDateStr = lastSettlementDate.formatGMT(
      'yyyy-MM-dd\'T\'HH:mm:ss\'Z\''
    );
    HttpResponse res = sendRequest(
      new AuthorizeNetModels.getSettledBatchListRequest(
          this.merchantAuthentication,
          refId,
          firstSettlementDateStr,
          lastSettlementDateStr,
          includeStatistics
        )
        .toXML()
    );
    return new AuthorizeNetModels.getSettledBatchListResponse(res);
  }

  public AuthorizeNetModels.getUnsettledTransactionListResponse getUnsettledTransactionList() {
    HttpResponse res = sendRequest(
      new AuthorizeNetModels.getUnsettledTransactionListRequest(
          this.merchantAuthentication
        )
        .toXML()
    );
    return new AuthorizeNetModels.getUnsettledTransactionListResponse(res);
  }

  public AuthorizeNetModels.getTransactionListResponse getTransactionList(
    String batchId,
    String refId
  ) {
    HttpResponse res = sendRequest(
      new AuthorizeNetModels.getTransactionListRequest(
          this.merchantAuthentication,
          refId,
          batchId
        )
        .toXML()
    );
    return new AuthorizeNetModels.getTransactionListResponse(res);
  }

  public AuthorizeNetModels.getTransactionDetailsResponse getTransactionDetails(
    String transId,
    String refId
  ) {
    HttpResponse res = sendRequest(
      new AuthorizeNetModels.getTransactionDetailsRequest(
          this.merchantAuthentication,
          refId,
          transId
        )
        .toXML()
    );
    return new AuthorizeNetModels.getTransactionDetailsResponse(res);
  }

  public AuthorizeNetModels.getBatchStatisticsResponse getBatchStatistics(
    String batchId
  ) {
    HttpResponse res = sendRequest(
      new AuthorizeNetModels.getBatchStatisticsRequest(
          this.merchantAuthentication,
          batchId
        )
        .toXML()
    );
    return new AuthorizeNetModels.getBatchStatisticsResponse(res);
  }
  /*
    Use this function to retrieve an existing customer profile along with all
    the associated payment profiles and shipping addresses.
   */
  public AuthorizeNetModels.getCustomerProfileResponse getCustomerProfile(
    String refId,
    String customerProfileId,
    Boolean includeIssuerInfo
  ) {
    AuthorizeNetModels.getCustomerProfileRequest request = new AuthorizeNetModels.getCustomerProfileRequest(
      this.merchantAuthentication,
      refId
    );
    request.customerProfileId = customerProfileId;
    request.includeIssuerInfo = includeIssuerInfo;
    HttpResponse res = sendRequest(request.toXML());
    return new AuthorizeNetModels.getCustomerProfileResponse(res);
  }
  /*
    Use this function to create a new customer profile including any customer
    payment profiles and customer shipping addresses.
   */
  public AuthorizeNetModels.createCustomerProfileResponse createCustomerProfile(
    String refId,
    AuthorizeNetModels.customerProfileType profile,
    String validationMode
  ) {
    AuthorizeNetModels.createCustomerProfileRequest request = new AuthorizeNetModels.createCustomerProfileRequest(
      this.merchantAuthentication,
      refId
    );
    request.profile = profile;
    request.validationMode = validationMode;
    HttpResponse res = sendRequest(request.toXML());
    return new AuthorizeNetModels.createCustomerProfileResponse(res);
  }
  /* Use this function to create a new customer profile using the transaction id from
    a previous request (within 30 days).
  */
  public AuthorizeNetModels.createCustomerProfileResponse createCustomerProfileFromTransaction(
    String refId,
    String transId,
    String customerProfileId,
    AuthorizeNetModels.customer customer
  ) {
    AuthorizeNetModels.createCustomerProfileFromTransactionRequest request = new AuthorizeNetModels.createCustomerProfileFromTransactionRequest(
      this.merchantAuthentication,
      refId
    );

    if (String.isBlank(customerProfileId)) {
      request.customer = customer;
    }
    request.transId = transId;
    request.customerProfileId = customerProfileId;
    HttpResponse res = sendRequest(request.toXML());
    return new AuthorizeNetModels.createCustomerProfileResponse(res);
  }
  /*
    Use this function to retrieve all existing customer profile IDs.
   */
  public AuthorizeNetModels.getCustomerProfileIdsResponse getCustomerProfileIds(
    String refId
  ) {
    AuthorizeNetModels.getCustomerProfileIdsRequest request = new AuthorizeNetModels.getCustomerProfileIdsRequest(
      this.merchantAuthentication,
      refId
    );
    HttpResponse res = sendRequest(request.toXML());
    return new AuthorizeNetModels.getCustomerProfileIdsResponse(res);
  }
  /*
    Use this function to delete an existing customer profile along with all
    associated customer payment profiles and customer shipping addresses.
   */
  public AuthorizeNetModels.ANetApiResponse deleteCustomerProfile(
    String refId,
    String customerProfileId
  ) {
    AuthorizeNetModels.deleteCustomerProfileRequest request = new AuthorizeNetModels.deleteCustomerProfileRequest(
      this.merchantAuthentication,
      refId,
      customerProfileId
    );
    HttpResponse res = sendRequest(request.toXML());
    return new AuthorizeNetModels.ANetApiResponse(res);
  }
  /*
    Use this function to update an existing customer profile.
   */
  public AuthorizeNetModels.ANetApiResponse updateCustomerProfile(
    String refId,
    AuthorizeNetModels.customerProfileType profile
  ) {
    AuthorizeNetModels.updateCustomerProfileRequest request = new AuthorizeNetModels.updateCustomerProfileRequest(
      this.merchantAuthentication,
      refId
    );
    request.profile = profile;
    HttpResponse res = sendRequest(request.toXML());
    return new AuthorizeNetModels.ANetApiResponse(res);
  }
  /*
    Use this function to create a new customer payment profile for an existing
    customer profile.
   */
  public AuthorizeNetModels.createCustomerPaymentProfileResponse createCustomerPaymentProfile(
    String refId,
    String customerProfileId,
    AuthorizeNetModels.customerPaymentProfileType paymentProfile,
    String validationMode
  ) {
    AuthorizeNetModels.createCustomerPaymentProfileRequest request = new AuthorizeNetModels.createCustomerPaymentProfileRequest(
      this.merchantAuthentication,
      refId
    );
    request.customerProfileId = customerProfileId;
    request.paymentProfile = paymentProfile;
    request.validationMode = validationMode;
    HttpResponse res = sendRequest(request.toXML());
    return new AuthorizeNetModels.createCustomerPaymentProfileResponse(res);
  }
  /*
    Use this function to retrieve the details of a customer payment profile
    associated with an existing customer profile.

    Note: If the payment profile has previously been set as the default payment
    profile, you can submit this request using customerProfileId as the only
    parameter. Submitting this request with only the customer profile ID will
    cause the information for the default payment profile to be returned if a
    default payment profile has been previously designated. If no payment
    profile has been designated as the default payment profile, failing to
    specify a payment profile will result in an error.
   */
  public AuthorizeNetModels.getCustomerPaymentProfileResponse getCustomerPaymentProfile(
    String refId,
    String customerProfileId,
    String customerPaymentProfileId,
    Boolean unmaskExpirationDate,
    Boolean includeIssuerInfo
  ) {
    AuthorizeNetModels.getCustomerPaymentProfileRequest request = new AuthorizeNetModels.getCustomerPaymentProfileRequest(
      this.merchantAuthentication,
      refId
    );
    request.customerProfileId = customerProfileId;
    request.customerPaymentProfileId = customerPaymentProfileId;
    request.unmaskExpirationDate = unmaskExpirationDate;
    request.includeIssuerInfo = includeIssuerInfo;
    HttpResponse res = sendRequest(request.toXML());
    return new AuthorizeNetModels.getCustomerPaymentProfileResponse(res);
  }
  /*
    Use this function to generate a test transaction that verifies an existing
    customer payment profile. No customer receipt emails are sent when the
    validateCustomerPaymentProfileRequest function is called.
   */
  public AuthorizeNetModels.validateCustomerPaymentProfileResponse validateCustomerPaymentProfile(
    String refId,
    String customerProfileId,
    String customerPaymentProfileId,
    String customerShippingAddressId,
    String cardCode,
    String validationMode
  ) {
    AuthorizeNetModels.validateCustomerPaymentProfileRequest request = new AuthorizeNetModels.validateCustomerPaymentProfileRequest(
      this.merchantAuthentication,
      refId
    );
    request.customerProfileId = customerProfileId;
    request.customerPaymentProfileId = customerPaymentProfileId;
    request.customerShippingAddressId = customerShippingAddressId;
    request.cardCode = cardCode;
    request.validationMode = validationMode;
    HttpResponse res = sendRequest(request.toXML());
    return new AuthorizeNetModels.validateCustomerPaymentProfileResponse(res);
  }
  /*
    Use this function to delete a customer payment profile from an existing
    customer profile.
   */
  public AuthorizeNetModels.ANetApiResponse deleteCustomerPaymentProfile(
    String refId,
    String customerProfileId,
    String customerPaymentProfileId
  ) {
    AuthorizeNetModels.deleteCustomerPaymentProfileRequest req = new AuthorizeNetModels.deleteCustomerPaymentProfileRequest(
      this.merchantAuthentication,
      refId
    );
    req.customerProfileId = customerProfileId;
    req.customerPaymentProfileId = customerPaymentProfileId;
    HttpResponse res = sendRequest(req.toXML());
    return new AuthorizeNetModels.ANetApiResponse(res);
  }
  /*
    Use this function to update a payment profile for an existing customer profile.

    Note: If some fields in this request are not submitted or are submitted
    with a blank value, the values in the original profile are removed. As a
    best practice to prevent this from happening, call
    getCustomerPaymentProfileRequest to receive all current information
    including masked payment information. Change the field or fields that you
    wish to update, and then reuse all the fields you received, with updates,
    in a call to updateCustomerPaymentProfileRequest.

    To test the validity of new payment information, call
    validateCustomerPaymentProfileRequest after successfully updating the
    payment profile.
   */
  public AuthorizeNetModels.createCustomerPaymentProfileResponse updateCustomerPaymentProfile(
    String refId,
    String customerProfiled,
    AuthorizeNetModels.customerPaymentProfileType paymentProfile,
    String validationMode
  ) {
    AuthorizeNetModels.updateCustomerPaymentProfileRequest req = new AuthorizeNetModels.updateCustomerPaymentProfileRequest(
      this.merchantAuthentication,
      refId
    );
    req.customerProfileId = customerProfiled;
    req.validationMode = validationMode;
    req.paymentProfile = paymentProfile;
    HttpResponse res = sendRequest(req.toXML());
    /*
      NOTE: we are returning createCustomerPaymentProfileResponse because it's
      the same as updateCustomerPaymentProfileResponse.
     */
    return new AuthorizeNetModels.createCustomerPaymentProfileResponse(res);
  }
}