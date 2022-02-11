public inherited sharing class TaskService {
    
  public static void setStageOnTask(List<Task> tasks) {
    Map<Id, Task> futureGiftMap = new Map<Id, Task>();
    Map<Id, Task> accountMap = new Map<Id, Task>();

    for (Task task : tasks){
      if (task.WhatId != null){
        if (String.valueOf(task.WhatId).substring(0, 3) == 'a1h'){
          futureGiftMap.put(task.WhatId, task);
        } else if (String.valueOf(task.WhatId).substring(0, 3) == '001'){
          accountMap.put(task.WhatId, task);
        }
      }
    }

    if (!futureGiftMap.isEmpty()){
      for (Future_Gift__c fg : [SELECT Id, Stage__c FROM Future_Gift__c WHERE Id IN :futureGiftMap.keySet() AND Stage__c != null]){
        Task temp = futureGiftMap.get(fg.Id);
        temp.Stage_When_Activity_Created__c = fg.Stage__c;
      }
    }

    if (!accountMap.isEmpty()){
      for (Account acct : [SELECT Id, Donor_Stage__c FROM Account WHERE Id IN :accountMap.keySet() AND Donor_Stage__c != null]){
        Task temp = accountMap.get(acct.Id);
        temp.Stage_When_Activity_Created__c = acct.Donor_Stage__c;
      }
    }
  }
}