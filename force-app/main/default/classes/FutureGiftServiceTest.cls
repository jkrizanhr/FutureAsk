@isTest
public class FutureGiftServiceTest {
  private class FutureAskValidationException extends Exception{}
  
  @testSetup 
  static void insertData() {
    Decimal usdRate = 1.10385;
    Decimal gbpRate = 0.855313;

    Currency_Exchange_Rate__c rate = new Currency_Exchange_Rate__c();
    rate.API_Response__c = CurrencyExchangeRateTestHelper.getResponseString(
        'EUR',
        usdRate,
        gbpRate
    );
    rate.Base__c = 'EUR';
    rate.Exchange_Rate_Collected_Date__c = Date.today();
    insert rate;
  }

  @isTest
  static void testFutureGiftRollupsToAccount() {
    Account acct1 = new Account();
    acct1.Name = 'Test Account 1';
    insert acct1;
    
    Account acct2 = new Account();
    acct2.Name = 'Test Account 2';
    insert acct2;

    Future_Gift__c fg1 = new Future_Gift__c();
    fg1.Account__c = acct1.Id;
    fg1.RecordTypeId = Schema.SObjectType.Future_Gift__c.getRecordTypeInfosByName().get('Legacy').getRecordTypeId();

    Future_Gift__c fg2 = new Future_Gift__c();
    fg2.Account__c = acct2.Id;
    fg2.RecordTypeId = Schema.SObjectType.Future_Gift__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();

    Future_Gift__c fg3 = new Future_Gift__c();
    fg3.Account__c = acct1.Id;
    fg3.RecordTypeId = Schema.SObjectType.Future_Gift__c.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
        
    Test.startTest();
      // INSERT FUTURE ASK TEST (Insert Future Asks)
      insert new List<Future_Gift__c>{fg1, fg2, fg3};
      Account fgRes1 = [SELECT Id, Number_of_Future_Gift_Proposals__c, Legacy_Club__c, Has_Pledge__c, Has_Proposal__c FROM Account WHERE Id = :acct1.Id];
      System.assertEquals(0, fgRes1.Number_of_Future_Gift_Proposals__c, 'The number of Future Ask Proposals should be 0.');
      System.assertEquals(true, fgRes1.Legacy_Club__c, 'Acct 1 has a legacy future ask.');
      System.assertEquals(true, fgRes1.Has_Pledge__c, 'Acct 1 has a pledge future ask.');
      System.assertEquals(false, fgRes1.Has_Proposal__c, 'Acct 1 does not have a proposal future ask.');
      
      // UPDATE FUTURE ASK TEST (Update Future Ask 2 to have Account 1 field set)
      fg2.Account__c = acct1.Id;
      update fg2;
      Account fgRes2 = [SELECT Id, Number_of_Future_Gift_Proposals__c, Legacy_Club__c, Has_Pledge__c, Has_Proposal__c FROM Account WHERE Id = :acct1.Id];
      System.assertEquals(1, fgRes2.Number_of_Future_Gift_Proposals__c, 'The number of Future Ask Proposals should be 1 (fg2).');
      System.assertEquals(true, fgRes2.Legacy_Club__c, 'Acct 1 has a legacy future ask.');
      System.assertEquals(true, fgRes2.Has_Proposal__c, 'Acct 1 has a proposal future ask.');
      System.assertEquals(true, fgRes2.Has_Pledge__c, 'Acct 1 has a pledge future ask.');
      
      // UPDATE FUTURE ASK TEST (Update Future Ask 2 to not have Account field set and Future Ask 1 to have a Closed Won StageName)
      fg1.RecordTypeId = Schema.SObjectType.Future_Gift__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId(); 
      fg2.Account__c = acct2.Id;
      update new List<Future_Gift__c>{fg1, fg2};
      Account fgRes3 = [SELECT Id, Number_of_Future_Gift_Proposals__c, Legacy_Club__c, Has_Pledge__c, Has_Proposal__c FROM Account WHERE Id = :acct1.Id];
      System.assertEquals(1, fgRes3.Number_of_Future_Gift_Proposals__c, 'The number of Future Ask Proposals should be 1 (fg1).');
      System.assertEquals(false, fgRes3.Legacy_Club__c, 'Acct 1 does not have a legacy future ask because changed to proposal.');
      System.assertEquals(true, fgRes3.Has_Proposal__c, 'Acct 1 still has a proposal future ask.');
      
      // DELETE FUTURE ASK TEST (Delete Future Ask 3)
      delete fg3;
      Account fgRes4 = [SELECT Id, Number_of_Future_Gift_Proposals__c, Legacy_Club__c, Has_Pledge__c, Has_Proposal__c FROM Account WHERE Id = :acct1.Id];    
      System.assertEquals(false, fgRes4.Has_Pledge__c, 'Acct 1 pledge future ask is deleted.');
      
      // UNDELETE FUTURE ASK TEST (Undelete Future Ask 3)
      undelete fg3;
      Account fgRes5 = [SELECT Id, Number_of_Future_Gift_Proposals__c, Legacy_Club__c, Has_Pledge__c, Has_Proposal__c FROM Account WHERE Id = :acct1.Id];
      System.assertEquals(true, fgRes5.Has_Pledge__c, 'Acct 1 pledge future ask is undeleted.');
    Test.stopTest();
  }

  @isTest
  static void testCreateFutureGiftStageHistoryRecord() {
    Account acct = new Account(
      Name = 'Test Account'
    );
    insert acct;

    Future_Gift__c fg = new Future_Gift__c(
      Account__c = acct.Id, 
      Stage__c = 'Solicitation',
      RecordTypeId = Schema.SObjectType.Future_Gift__c.getRecordTypeInfosByDeveloperName().get('Proposal').getRecordTypeId()
    );
    
    Test.startTest();
      insert fg;
      Future_Gift_Stage_History__c res1 = [SELECT Id, New_Stage__c FROM Future_Gift_Stage_History__c WHERE Future_Gift__c = :fg.Id];
      System.assertNotEquals(res1, null);
      System.assertEquals(res1.New_Stage__c, 'Solicitation');

      fg.Stage__c = 'Commitment Made';
      update fg;

      Future_Gift_Stage_History__c res2 = [SELECT Id, New_Stage__c, End_Date__c FROM Future_Gift_Stage_History__c WHERE Id = :res1.Id];
      System.assertEquals(res2.End_Date__c, Date.today());

      Future_Gift_Stage_History__c res3 = [SELECT Id, New_Stage__c, Previous_Stage__c FROM Future_Gift_Stage_History__c WHERE Id != :res1.Id AND Future_Gift__c = :fg.Id LIMIT 1];
      System.assertNotEquals(res3, null);
      System.assertEquals(res3.New_Stage__c, 'Commitment Made');
      System.assertEquals(res3.Previous_Stage__c, 'Solicitation');
    Test.stopTest();
  }

  @isTest
  static void testCreateFutureGiftRoleForDonorRelationshipManager() {
    User testUser = UnitTestHelper.createStandardUser();
    testUser.IsActive = true;
    insert testUser;
    
    Account acct = new Account(
      Name = 'Test Account',
      Donor_Relationship_Manager__c = testUser.Id
    );
    insert acct;

    Future_Gift__c fg = new Future_Gift__c(
      Account__c = acct.Id, 
      Stage__c = 'Solicitation',
      RecordTypeId = Schema.SObjectType.Future_Gift__c.getRecordTypeInfosByDeveloperName().get('Proposal').getRecordTypeId()
    );
    
    Test.startTest();
      insert fg;
    Test.stopTest();

    Future_Gift_Role__c fgRole = [SELECT Id, Future_Gift__c, Biblica_Staff_Member__c FROM Future_Gift_Role__c WHERE Future_Gift__c = :fg.Id LIMIT 1];
    System.assertEquals(testUser.Id, fgRole.Biblica_Staff_Member__c);
  }

  @isTest
  static void testFutureAskValidationOnStageChange() {
    Account acct = new Account(
      Name = 'Test Account'
    );
    insert acct;

    Future_Gift__c fg = new Future_Gift__c(
      Account__c = acct.Id,
      Original_Currency__c = 'USD',
      Stage__c = 'Solicitation',
      RecordTypeId = Schema.SObjectType.Future_Gift__c.getRecordTypeInfosByDeveloperName().get('Proposal').getRecordTypeId()
    );
    insert fg;

    npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c(
      Name = 'Test GAU',
      Purpose_Code__c = '123456'
    );
    insert gau;

    Future_Gift_Allocation__c fga = new Future_Gift_Allocation__c(
      Future_Gift__c = fg.Id,
      General_Accounting_Unit__c = gau.Id,
      Allocation_Amount__c = 150
    );
    
    Test.startTest();
      // TEST INSERT FUTURE ASK ALLOCATION WITH VALUE THAT'S TOO HIGH IN SOLICITATION STAGE
      try {
        insert fga;
      } 
      catch(Exception e) {
        throw new FutureAskValidationException('An exception should NOT have been thrown by the trigger but was.'); 
      } 
      // TEST UPDATE FUTURE ASK TO COMMITMENT MADE WITHOUT ORIGINAL ASK AMOUNT
      try {
        fg.Stage__c = 'Commitment Made';
        update fg;
        throw new FutureAskValidationException('An exception should have been thrown by the trigger but was not.'); 
      } 
      catch(Exception e) {
        Boolean expectedExceptionThrown =  e.getMessage().contains('The Future Ask must have the Original Actual Amount set before moving past the "Solicitation" stage.') 
          ? true 
          : false;
        System.AssertEquals(expectedExceptionThrown, true);
      } 
      // TEST UPDATE FUTURE ASK TO COMMITMENT MADE WITH LOW ORIGINAL ASK AMOUNT
      try {
        fg.Original_Actual_Ask_Amount__c = 100;
        fg.Stage__c = 'Commitment Made';
        update fg;
      } 
      catch(Exception e) {
        Boolean expectedExceptionThrown =  e.getMessage().contains('The sum of the Future Ask Allocations cannot exceed the Future Ask Actual Amount. Please fix the Allocations before moving past the "Solicitation" stage.') 
          ? true 
          : false;
        System.AssertEquals(expectedExceptionThrown, true);
      } 
      // TEST UPDATE FUTURE ASK ALLOCATION TO LOWER VALUE, UPDATE FUTURE GIFT
      try {
        fga.Allocation_Amount__c = 100;
        update fga;
        
        fg.Original_Actual_Ask_Amount__c = 100;
        fg.Stage__c = 'Commitment Made';
        update fg;
      } 
      catch(Exception e) {
        System.debug(e.getMessage());
        throw new FutureAskValidationException('An exception should NOT have been thrown by the trigger but was.'); 
      } 
    Test.stopTest();
  }
}