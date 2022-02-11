@isTest
private class CountryServiceTest {
  
  @isTest
  static void countryRollupToProjectTest() {
    Project__c lmp = new Project__c(
      Name = 'Test Project'
    );
    insert lmp;
    Project__c ltp = new Project__c(
      Name = 'Test Project'
    );
    insert ltp;

    Country__c chile = new Country__c(
      Country__c = 'Chile',
      Project__c = lmp.Id
    );
    Country__c portugal = new Country__c(
      Country__c = 'Portugal',
      Project__c = lmp.Id
    );
    Country__c spain = new Country__c(
      Country__c = 'Spain',
      Project__c = lmp.Id
    );
    Country__c argentina = new Country__c(
      Country__c = 'Argentina',
      Project__c = lmp.Id
    );

    Test.startTest();
      //TEST INSERT
      insert portugal;
      Project__c res1 = [SELECT Id, Countries_Served__c FROM Project__c WHERE Id = :lmp.Id LIMIT 1];
      System.assertEquals('Portugal', res1.Countries_Served__c);
      
      insert new List<Country__c>{chile, spain, argentina};
      Project__c res2 = [SELECT Id, Countries_Served__c FROM Project__c WHERE Id = :lmp.Id LIMIT 1];
      System.assertEquals('Argentina; Chile; Portugal; Spain', res2.Countries_Served__c);
      
      //TEST UPDATE
      portugal.Country__c = 'Mexico';
      update portugal;
      Project__c res3 = [SELECT Id, Countries_Served__c FROM Project__c WHERE Id = :lmp.Id LIMIT 1];
      System.assertEquals('Argentina; Chile; Mexico; Spain', res3.Countries_Served__c);
      
      portugal.Country__c = 'Argentina';
      update portugal;
      Project__c res4 = [SELECT Id, Countries_Served__c FROM Project__c WHERE Id = :lmp.Id LIMIT 1];
      System.assertEquals('Argentina; Chile; Spain', res4.Countries_Served__c);
      
      portugal.Country__c = 'Portugal';
      portugal.Project__c = ltp.Id;
      update portugal;
      Project__c res5 = [SELECT Id, Countries_Served__c FROM Project__c WHERE Id = :lmp.Id LIMIT 1];
      System.assertEquals('Argentina; Chile; Spain', res5.Countries_Served__c);
      Project__c res6 = [SELECT Id, Countries_Served__c FROM Project__c WHERE Id = :ltp.Id LIMIT 1];
      System.assertEquals('Portugal', res6.Countries_Served__c);

      //TEST DELETE
      delete portugal;
      Project__c res7 = [SELECT Id, Countries_Served__c FROM Project__c WHERE Id = :ltp.Id LIMIT 1];
      System.assertEquals(null, res7.Countries_Served__c);
      
      delete argentina;
      Project__c res8 = [SELECT Id, Countries_Served__c FROM Project__c WHERE Id = :lmp.Id LIMIT 1];
      System.assertEquals('Chile; Spain', res8.Countries_Served__c);
      
      //TEST UNDELETE
      undelete argentina;
      Project__c res9 = [SELECT Id, Countries_Served__c FROM Project__c WHERE Id = :lmp.Id LIMIT 1];
      System.assertEquals('Argentina; Chile; Spain', res9.Countries_Served__c);
    Test.stopTest();
  }
}