@isTest
private class HistoricalTransactionFetchJobTest {

  @isTest static void testJob() {
    Historical_Transaction_Settings__c htSettings = new Historical_Transaction_Settings__c();
    htSettings.Name = 'Test';
    htSettings.Time_Step_Minutes__c = 10;
    htSettings.Start_Time_Step_seconds__c = 1;
    htSettings.Record_Query_Size__c = 100;
    htSettings.Datetime_Compare_Field__c = 'Create_Time__c';
    insert htSettings;

    String response = '{"success": true, "transactions": [{"transactionId": "1111", "type": "Payment", "status": "Posted", "amount": 50.00, "createTime": 1455835390811, "email": "test@test.test"}]}';
    Map<String, String> headers = new Map<String, String> {
      'Content-Type' => 'application/json'
    };
    HistoricalTransactionRequestMock mockResponse = new HistoricalTransactionRequestMock(200, 'Complete', response, headers);
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    HistoricalTransactionFetchJob.schedule('Test', 'Historical Transaction Fetch Job Test', null);
    Test.stopTest();
  }

}