@isTest
private class UtilsTest {
  
  @isTest
  static void testUtilGroupByMethods() {
    Account acct1 = new Account(Name = 'A'); 
    Account acct2 = new Account(Name = 'B'); 
    Account acct3 = new Account(Name = 'C');    
    List<SObject> objList = new List<SObject>{acct1, acct2, acct3};
    insert objList;

    String prop1 = 'Id';
    String prop2 = 'Name';
    List<String> props = new List<String>{prop1, prop2};

    Test.startTest();
     Map<String, List<SObject>> res1 = Utils.groupBy(objList, prop1);
     Map<String, List<SObject>> res2 = Utils.groupBy(objList, props);
     Map<String, List<SObject>> res3 = Utils.groupBy(objList, prop1, res1);
     Map<String, List<SObject>> res4 = Utils.groupBy(objList, props, res2);
    Test.stopTest();

    System.assertNotEquals(null, res1);
    System.assertNotEquals(null, res2);
    System.assertNotEquals(null, res3);
    System.assertNotEquals(null, res4);
  }

  @isTest
  static void testSobjectListMethods(){
    Account acct1 = new Account(Name = 'A'); 
    Account acct2 = new Account(Name = 'B'); 
    Account acct3 = new Account(Name = 'C');    
    List<SObject> objList = new List<SObject>{acct1, acct2, acct3};
    insert objList;

    String prop1 = 'Id';
    String prop2 = 'Name';
    List<String> props = new List<String>{prop1, prop2};

    Test.startTest();
    List<Id> res1 = Utils.sObjListToIdList(objList);
    Set<Id> res2 = Utils.sObjListToIdSet(objList, prop1);
    List<Id> res3 = Utils.sObjListToIdList(objList, prop1);
    Test.stopTest();

    System.assertNotEquals(null, res1);
    System.assertNotEquals(null, res2);
    System.assertNotEquals(null, res3);
  }

  @isTest
  static void testListToMapMethods(){
    Account acct1 = new Account(Name = 'A'); 
    Account acct2 = new Account(Name = 'B'); 
    Account acct3 = new Account(Name = 'C');    
    List<SObject> objList = new List<SObject>{acct1, acct2, acct3};
    insert objList;

    String prop1 = 'Id';
    String prop2 = 'Name';
    List<String> props = new List<String>{prop1, prop2};

    Test.startTest();
    Map<String, SObject> res1 = Utils.listToMap(objList, prop1);
    Map<String, SObject> res2 = Utils.listToMap(objList, props);
    Test.stopTest();

    System.assertNotEquals(null, res1);
    System.assertNotEquals(null, res2);
  }

  @isTest 
  static void testBuildKeyMethod(){
    Account acct1 = new Account(Name = 'A'); 
    Account acct2 = new Account(Name = 'B'); 
    Account acct3 = new Account(Name = 'C');    
    List<SObject> objList = new List<SObject>{acct1, acct2, acct3};
    insert objList;

    String prop1 = 'Id';
    String prop2 = 'Name';
    List<String> props = new List<String>{prop1, prop2};

    Test.startTest();
      String res1 = Utils.buildKey(acct1, props);
    Test.stopTest();

    System.assertNotEquals(null, res1);
  }

  @isTest
  static void testGetRecordTypeId(){
    Test.startTest();
      Id res1 = Utils.getRecordTypeId('Account', 'Organization');
    Test.stopTest();

    System.assertNotEquals(null, res1);
  }
}