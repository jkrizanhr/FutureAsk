public inherited sharing class EventService {
  
  public static void setStageOnEvent(List<Event> events) {
    Map<Id, Event> futureGiftMap = new Map<Id, Event>();
    Map<Id, Event> accountMap = new Map<Id, Event>();

    for (Event event : events){
      if (event.WhatId != null){
        if (String.valueOf(event.WhatId).substring(0, 3) == 'a1h'){
          futureGiftMap.put(event.WhatId, event);
        } else if (String.valueOf(event.WhatId).substring(0, 3) == '001'){
          accountMap.put(event.WhatId, event);
        }
      }
    }

    if (!futureGiftMap.isEmpty()){
      for (Future_Gift__c fg : [SELECT Id, Stage__c FROM Future_Gift__c WHERE Id IN :futureGiftMap.keySet()]){
        Event temp = futureGiftMap.get(fg.Id);
        temp.Stage_When_Activity_Created__c = fg.Stage__c;
      }
    }

    if (!accountMap.isEmpty()){
      for (Account acct : [SELECT Id, Donor_Stage__c FROM Account WHERE Id IN :accountMap.keySet()]){
        Event temp = accountMap.get(acct.Id);
        temp.Stage_When_Activity_Created__c = acct.Donor_Stage__c;
      }
    }
  }
}