@isTest
private class ResultServiceTest {

  @isTest
  static void resultSnapshotRollupTest() {
    Account household = new Account(
      Name = 'Household'
    );
    insert household;

    Contact c1 = new Contact(
      LastName = 'Contact 1',
      AccountId = household.Id
    );
    Contact c2 = new Contact(
      LastName = 'Contact 2',
      AccountId = household.Id
    );
    insert new List<Contact>{c1, c2};

    DS360oi__DonorSearch_del_del__c ss1 = new DS360oi__DonorSearch_del_del__c(
      DS360oi__DS_Rating__c = 'Snapshot 1',
      DS360oi__Wealth_Score__c = 100.03,
      DS360oi__Capacity_Range_Based_on_Wealth__c = 'Snapshot 1',
      DS360oi__Wealth_Capacity_Range__c = 'Snapshot 1',
      DS360oi__Annual_Fund_Likelihood__c = 100,
      DS360oi__Major_Gift_Likelihood__c = 100,
      DS360oi__Quality_Score__c = 100,
      DS360oi__Profile__c = 'www.salesforce.com',
      DS360oi__ID__c = c1.Id,
      CreatedDate = Datetime.now().addMinutes(-5)
    );
    DS360oi__DonorSearch_del_del__c ss2 = new DS360oi__DonorSearch_del_del__c(
      DS360oi__DS_Rating__c = 'Snapshot 2',
      DS360oi__Wealth_Score__c = 100.03,
      DS360oi__Capacity_Range_Based_on_Wealth__c = 'Snapshot 2',
      DS360oi__Wealth_Capacity_Range__c = 'Snapshot 2',
      DS360oi__Annual_Fund_Likelihood__c = 100,
      DS360oi__Major_Gift_Likelihood__c = 100,
      DS360oi__Quality_Score__c = 100,
      DS360oi__Profile__c = 'www.salesforce.com',
      DS360oi__ID__c = c2.Id,
      CreatedDate = Datetime.now().addMinutes(-1)
    );
    DS360oi__DonorSearch_del_del__c ss3 = new DS360oi__DonorSearch_del_del__c(
      DS360oi__DS_Rating__c = 'Snapshot 3',
      DS360oi__Wealth_Score__c = 100.03,
      DS360oi__Capacity_Range_Based_on_Wealth__c = 'Snapshot 3',
      DS360oi__Wealth_Capacity_Range__c = 'Snapshot 3',
      DS360oi__Annual_Fund_Likelihood__c = 100,
      DS360oi__Major_Gift_Likelihood__c = 100,
      DS360oi__Quality_Score__c = 100,
      DS360oi__Profile__c = 'www.salesforce.com',
      DS360oi__ID__c = c1.Id
    );
    
    Test.startTest();
      // TEST INSERT
      insert ss1;
      Account res1 = [SELECT Id, DS_Rating__c, Estimated_Capacity__c, Target_Ask_Based_on_Giving__c, Target_Ask_Based_on_Wealth__c, Annual_Fund_Likelihood__c, Major_Gift_Likelihood__c, Quality_Score__c, Profile__c, DS_Last_Updated_Date__c FROM Account WHERE Id = :household.Id];
      System.assertEquals('Snapshot 1', res1.DS_Rating__c);
      
      insert new List<DS360oi__DonorSearch_del_del__c>{ss2, ss3};
      Account res2 = [SELECT Id, DS_Rating__c, Estimated_Capacity__c, Target_Ask_Based_on_Giving__c, Target_Ask_Based_on_Wealth__c, Annual_Fund_Likelihood__c, Major_Gift_Likelihood__c, Quality_Score__c, Profile__c, DS_Last_Updated_Date__c FROM Account WHERE Id = :household.Id];
      System.assertEquals('Snapshot 3', res2.DS_Rating__c);
      
      // TEST DELTE
      delete ss3;
      Account res3 = [SELECT Id, DS_Rating__c, Estimated_Capacity__c, Target_Ask_Based_on_Giving__c, Target_Ask_Based_on_Wealth__c, Annual_Fund_Likelihood__c, Major_Gift_Likelihood__c, Quality_Score__c, Profile__c, DS_Last_Updated_Date__c FROM Account WHERE Id = :household.Id];
      System.assertEquals('Snapshot 2', res3.DS_Rating__c);
      
      // TEST UNDELETE
      undelete ss3;
      Account res4 = [SELECT Id, DS_Rating__c, Estimated_Capacity__c, Target_Ask_Based_on_Giving__c, Target_Ask_Based_on_Wealth__c, Annual_Fund_Likelihood__c, Major_Gift_Likelihood__c, Quality_Score__c, Profile__c, DS_Last_Updated_Date__c FROM Account WHERE Id = :household.Id];
      System.assertEquals('Snapshot 3', res4.DS_Rating__c);
    Test.stopTest();
  }
}