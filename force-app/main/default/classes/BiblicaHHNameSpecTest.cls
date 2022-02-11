@isTest
private class BiblicaHHNameSpecTest {
  @isTest
  static void testNaming() {
    npsp__Household_Naming_Settings__c hns = new npsp__Household_Naming_Settings__c();
    hns.npsp__Household_Name_Format__c = '{!LastName} ' + label.npo02.DefaultHouseholdName;
    hns.npsp__Formal_Greeting_Format__c = '{!{!Salutation} {!FirstName}} {!LastName}';
    hns.npsp__Informal_Greeting_Format__c = '{!{!FirstName}}';
    hns.npsp__Name_Connector__c = label.npo02.HouseholdNameConnector;
    hns.npsp__Name_Overrun__c = label.npo02.HouseholdNameOverrun;
    hns.npsp__Contact_Overrun_Count__c = 9;
    hns.npsp__Implementing_Class__c = 'BiblicaHHNameSpec';
    insert hns;

    npsp.UTIL_CustomSettings_API.getHouseholdNamingSettings()
      .npsp__Implementing_Class__c = 'BiblicaHHNameSpec';

    Contact con = new Contact();
    con.FirstName = 'Bill';
    con.LastName = 'Jones';
    con.Gender__c = 'Male';
    insert con;
    con = [SELECT Id, AccountId FROM Contact WHERE Id = :con.Id];

    Contact con2 = new Contact();
    con2.FirstName = 'Jane';
    con2.LastName = 'Jones';
    con2.Gender__c = 'Female';
    con2.AccountId = con.AccountId;
    insert con2;
  }
}