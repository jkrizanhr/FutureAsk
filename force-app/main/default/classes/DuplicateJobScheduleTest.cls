@IsTest
public with sharing class DuplicateJobScheduleTest {
    @IsTest
    public static void testSchedule(){
        Test.startTest();
        System.schedule('Duplicate Job Test', '0 0 0 1/1 * ? *', new DuplicateJobSchedule());
        Test.stopTest();
    }
}