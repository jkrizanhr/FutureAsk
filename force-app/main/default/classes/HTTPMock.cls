@isTest
public class HTTPMock implements HTTPCalloutMock {
  Map<String, HTTPResponse> responseMap;

  public HTTPMock(Map<String, HTTPResponse> responseMap) {
    this.responseMap = responseMap;
  }

  public HTTPResponse Respond(HTTPRequest req){
    System.debug(responseMap.get(req.getEndpoint()));
    return responseMap.get(req.getEndpoint());
  }
}