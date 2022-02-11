@IsTest
public class TriggerHandlerServiceTest {
  @IsTest
  public static void testTriggerHandlerCreation() {
    Contact c = new Contact();
    c.LastName = 'Reichert';

    Test.startTest();
    insert c;
    Test.stopTest();

    npsp__Trigger_Handler__c th = [
      SELECT npsp__Trigger_Action__c
      FROM npsp__Trigger_Handler__c
      WHERE npsp__Object__c = 'Allocation__c' AND npsp__Class__c = 'ALLO_Allocations_TDTM'
    ];
    System.assertEquals(false, th.npsp__Trigger_Action__c.contains('beforeInsert'));
    System.assertEquals(false, th.npsp__Trigger_Action__c.contains('beforeUpdate'));
  }

  @IsTest
  public static void testTriggerHandlerUpdate() {
    Contact c = new Contact();
    c.LastName = 'Reichert';

    insert c;

    npsp__Trigger_Handler__c th = [
      SELECT npsp__Trigger_Action__c
      FROM npsp__Trigger_Handler__c
      WHERE npsp__Object__c = 'Allocation__c' AND npsp__Class__c = 'ALLO_Allocations_TDTM'
    ];
    th.npsp__Trigger_Action__c = 'BeforeInsert;BeforeUpdate;AfterInsert;AfterUpdate;AfterDelete';

    Test.startTest();
    update th;
    Test.stopTest();

    npsp__Trigger_Handler__c th2 = [
      SELECT npsp__Trigger_Action__c
      FROM npsp__Trigger_Handler__c
      WHERE npsp__Object__c = 'Allocation__c' AND npsp__Class__c = 'ALLO_Allocations_TDTM'
    ];

    System.assertEquals(false, th2.npsp__Trigger_Action__c.contains('BeforeInsert'));
    System.assertEquals(false, th2.npsp__Trigger_Action__c.contains('BeforeUpdate'));
  }
}