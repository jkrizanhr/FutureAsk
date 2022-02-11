public without sharing class ProjectPartnerService {

  public static void rollupNumberOfProjectsToAccount(List<Project_Partner__c> ppList, Map<Id, Project_Partner__c> oldMap) {
    Map<Id, Account> acctsToUpdate = new Map<Id, Account>();
    
    for (Project_Partner__c pp : ppList) {
      Project_Partner__c old = oldMap != null ? oldMap.get(pp.Id) : null;
      if (old == null || (old != null && (
        (pp.Project_Record_Type__c != old.Project_Record_Type__c)
        ))
      ){
        Account acct = new Account(
          Id = pp.Account__c,
          Number_of_MPP_Projects__c = 0,
          Number_of_TPP_Projects__c = 0
        );
        acctsToUpdate.put(pp.Account__c, acct);
      }
    }

    if (!acctsToUpdate.isEmpty()){
      for (AggregateResult ar : [SELECT COUNT(Project__c) ct, Account__c, Project__r.RecordType.Name rtn
                                  FROM Project_Partner__c
                                  WHERE Account__c IN :acctsToUpdate.keySet() AND CreatedDate >= :Date.Today().addYears(-5)
                                  GROUP BY Account__c, Project__r.RecordType.Name
      ]){
        Id acctId = String.valueOf(ar.get('Account__c'));
        String recordType = String.valueOf(ar.get('rtn'));
        if (acctId != null){
          Account acct = acctsToUpdate.get(acctId);
          switch on recordType {
            when 'Language Ministry Project'{
              acct.Number_of_MPP_Projects__c = Double.valueOf(ar.get('ct'));
            }
            when 'Language Translation Plan'{
              acct.Number_of_TPP_Projects__c = Double.valueOf(ar.get('ct'));
            }
            when else {}
          }
        }
      }

      if (!acctsToUpdate.isEmpty()){
        update acctsToUpdate.values();
      }
    }
  }
}