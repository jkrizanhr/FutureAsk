public without sharing class Utils {
  public static Map<String, List<SObject>> groupBy(List<SObject> objList, String prop) {
    return groupBy(objList, prop, new Map<String, List<SObject>>());
  }

  public static Map<String, List<SObject>> groupBy(List<SObject> objList, List<String> props) {
    return groupBy(objList, props, new Map<String, List<SObject>>());
  }

  public static Map<String, List<SObject>> groupBy(
    List<SObject> objList,
    String prop,
    Map<String, List<SObject>> mapped
  ) {
    for (SObject iter : objList) {
      String val = String.valueOf(iter.get(prop));
      List<SObject> curList = mapped.get(val);
      if (curList == null) {
        curList = new List<SObject>();
        mapped.put(val, curList);
      }
      curList.add(iter);
    }
    return mapped;
  }

  public static Map<String, List<SObject>> groupBy(
    List<SObject> objList,
    List<String> props,
    Map<String, List<SObject>> mapped
  ) {
    for (SObject iter : objList) {
      List<String> values = new List<String>();
      for (String prop : props) {
        values.add(String.valueOf(iter.get(prop)));
      }
      String key = String.join(values, ':');
      List<SObject> curList = mapped.get(key);
      if (curList == null) {
        curList = new List<SObject>();
        mapped.put(key, curList);
      }
      curList.add(iter);
    }
    return mapped;
  }

  public static Set<Id> sObjListToIdSet(List<SObject> objList) {
    Set<Id> newSet = new Set<Id>();
    for (SObject iter : objList) {
      if (iter.id != null) {
        newSet.add(iter.id);
      }
    }
    return newSet;
  }

  public static List<Id> sObjListToIdList(List<SObject> objList) {
    return new List<Id>(sObjListToIdSet(objList));
  }

  public static Set<Id> sObjListToIdSet(List<SObject> objList, String idProp) {
    Set<Id> idSet = new Set<Id>();
    for (SObject sObj : objList) {
      if (sObj.get(idProp) != null) {
        idSet.add(String.valueOf(sObj.get(idProp)));
      }
    }
    return idSet;
  }

  public static List<Id> sObjListToIdList(List<SObject> objList, String idProp) {
    return new List<Id>(sObjListToIdSet(objList, idProp));
  }

  public static Map<String, SObject> listToMap(List<SObject> objList, String prop) {
    return listToMap(objList, new List<String>{ prop });
  }

  public static Map<String, SObject> listToMap(List<SObject> objList, List<String> props) {
    return listToMap(objList, props, false);
  }

  public static Map<String, SObject> listToMap(
    List<SObject> objList,
    String prop,
    Boolean caseInsensitive
  ) {
    return listToMap(objList, new List<String>{ prop }, caseInsensitive);
  }

  public static Map<String, SObject> listToMap(
    List<SObject> objList,
    List<String> props,
    Boolean caseInsensitive
  ) {
    Map<String, SObject> mapped = new Map<String, SObject>();
    for (SObject iter : objList) {
      String key = buildKey(iter, props);
      if (caseInsensitive) {
        key = key.toLowerCase();
      }
      mapped.put(key, iter);
    }
    return mapped;
  }

  public static String buildKey(SObject obj, List<String> props) {
    List<String> values = new List<String>();
    for (String prop : props) {
      values.add(String.valueOf(obj.get(prop)));
    }
    return String.join(values, ':');
  }

  public static Database.DMLOptions getDMLOptions() {
    Database.DMLOptions dmlOptions = new Database.DMLOptions();
    dmlOptions.DuplicateRuleHeader.AllowSave = true;
    return dmlOptions;
  }

  public static Id getRecordTypeId(String objectApiName, String recordTypeName) {
    return Schema.getGlobalDescribe()
      .get(objectApiName)
      .getDescribe()
      .getRecordTypeInfosByName()
      .get(recordTypeName)
      .getRecordTypeId();
  }

  public static void setUserRegion(List<SObject> objList, String regionField){
    List<User> users = [SELECT Id, Region_Category__c FROM User WHERE Id = :UserInfo.getUserId()];
    User u = !users.isEmpty() ? users[0] : null;

    if (u != null){
      for (SObject obj : objList){
        if (obj.get(regionField) == null && u.Region_Category__c != null){
          obj.put(regionField, u.Region_Category__c);
        }
      }
    }
  }

  // Checks to see whether an Id is valid and returns true or false.
  public static Boolean checkIdValidity(String tempId){
    try {
      Id validId = tempId;
      return true;
    } catch (Exception e){
      return false;
    }
  }
}