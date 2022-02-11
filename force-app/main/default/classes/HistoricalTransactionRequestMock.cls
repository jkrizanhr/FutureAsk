@isTest
public class HistoricalTransactionRequestMock implements HttpCalloutMock {
  protected Integer code;
  protected String status;
  protected String bodyAsString;
  protected Blob bodyAsBlob;
  protected Map<String, String> responseHeaders;

  public HistoricalTransactionRequestMock(Integer code, String status, String body, Map<String, String> responseHeaders) {
    this.code = code;
    this.status = status;
    this.bodyAsString = body;
    this.bodyAsBlob = null;
    this.responseHeaders = responseHeaders;
  }

  public HistoricalTransactionRequestMock(Integer code, String status, Blob body, Map<String, String> responseHeaders) {
    this.code = code;
    this.status = status;
    this.bodyAsBlob = body;
    this.bodyAsString = null;
    this.responseHeaders = responseHeaders;
  }

  public HttpResponse respond(HttpRequest req) {
    HttpResponse res = new HttpResponse();
    res.setStatusCode(code);
    res.setStatus(status);
    if (bodyAsBlob != null) {
      res.setBodyAsBlob(bodyAsBlob);
    } else {
      res.setBody(bodyAsString);
    }

    if (responseHeaders != null) {
      for (String key : responseHeaders.keySet()) {
        res.setHeader(key, responseHeaders.get(key));
      }
    }

    return res;
  }
}