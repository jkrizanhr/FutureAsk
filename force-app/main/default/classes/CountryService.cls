public inherited sharing class CountryService {
  
  public static void countryRollupToProject(List<Country__c> countries, Map<Id, Country__c> oldMap) {
    Map<Id, Project__c> projectMap = new Map<Id, Project__c>();

    for (Country__c country : countries){
      Country__c old = oldMap != null 
        ? oldMap.get(country.Id)
        : null;
      if (old != null){
        if (
          (old.Project__c != null && old.Project__c != country.Project__c) ||
          old.Country__c != country.Country__c
        ){
          if (country.Project__c != null){
            Project__c temp = new Project__c(
              Id = country.Project__c
            );
            projectMap.put(country.Project__c, temp);
          }
          if (old.Project__c != null && old.Project__c != country.Project__c){
            Project__c temp = new Project__c(
              Id = old.Project__c
            );
            projectMap.put(old.Project__c, temp);
          }
        } 
      } else {
        if (country.Project__c != null){
          Project__c temp = new Project__c(
            Id = country.Project__c
          );
          projectMap.put(country.Project__c, temp);
        }
      }
    }

    if (!projectMap.isEmpty()){
      for (Project__c proj : [
        SELECT Id, Countries_Served__c, 
          (SELECT Country__c FROM Countries__r ORDER BY Country__c ASC) 
        FROM Project__c WHERE Id IN :projectMap.keySet()]
      ){
        Set<String> tempCountrySet = new Set<String>();
        if (!proj.Countries__r.isEmpty()){
          for (Integer i = 0; i < proj.Countries__r.size(); i++){
            tempCountrySet.add(proj.Countries__r[i].Country__c);
          }
        }
        proj.Countries_Served__c = !tempCountrySet.isEmpty()
          ? String.join((Iterable<String>)tempCountrySet, '; ')
          : null;
        projectMap.put(proj.Id, proj);
      }
    }

    if (!projectMap.isEmpty()){
      update projectMap.values();
    }
  }
}