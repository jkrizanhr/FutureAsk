@isTest
public class MultiRequestMock implements HttpCalloutMock {
  /*
    This class handles mock callouts for test methods that require more than one callout response per execution
  */

  List<HttpCalloutMock> responses;

  public MultiRequestMock() {
    this.responses = new List<HttpCalloutMock>();
  }
  public MultiRequestMock(List<HttpCalloutMock> responses) {
    this.responses = responses;
  }

  public void addResponseMock(HttpCalloutMock resp) {
    this.responses.add(resp);
  }

  public HttpResponse respond(HttpRequest request) {
    HttpCalloutMock mock = this.responses.remove(0);
    return mock.respond(request);
  }
}