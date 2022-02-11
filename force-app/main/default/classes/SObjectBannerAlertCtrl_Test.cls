@isTest
private class SObjectBannerAlertCtrl_Test {

  static testMethod void testSObjectBannerAlertCtrl() {
    SObject_Banner_Alert__c setting1 = new SObject_Banner_Alert__c();
    setting1.Name = 'Contact.LastName with Phone';
    setting1.Message__c = 'This test contact named {!LastName} has a phone of {!phone}';
    setting1.Field_Name__c = 'Phone';
    setting1.Object_Name__c = 'Contact';
    setting1.Value__c = '';
    setting1.Does_not_equal__c = true;
    setting1.Message_Merge_Fields__c = 'phone, lastname';
    insert setting1;

    Contact con = new Contact();
    con.lastName = 'Contact';
    con.firstName = 'Test';
    con.Phone = '1234321232';
    insert con;

    Test.StartTest();
    List<SObjectBannerAlert_Ctrl.CustomAlertGroup> alertResults = SObjectBannerAlert_Ctrl.getAlertsForSObject(con.Id);
    System.assertEquals(1, alertResults.size(), 'There should be one alert message returned');
    Test.StopTest();
  }
}