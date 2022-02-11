trigger OnFutureGiftAllFields on Future_Gift_Allocation__c (after insert, after update)


/*{
    map<string, Future_Gift_Allocation__c> ObjMap = new map<string, Future_Gift_Allocation__c>();
    
    for(Future_Gift_Allocation__c obj: Trigger.new)
    {
        if (obj.Project__c != Null)
        {
            ObjMap.put(obj.Project__c, obj);
        }
    }
    
    List<Project__c> projects = [SELECT Name, Shared_Field__c, AccountId, Expected_Event_Types__c 
    					FROM Case WHERE Shared_Field__c IN :ObjMap.KeySet()];
    List<Project__c> ProjectUpdateList = new List<Project__c>();
    
    for(Case c: cases)
    {
    	Future_Gift_Allocation__c obj = ObjMap.get(c.Shared_Field__c);
        c.AccountId = obj.Account__c;
        c.App__c = obj.Id;
        c.Expected_Event_Types__c = obj.Event_Types__c;
        caseUpdateList.add(c);
    }
    
    if(caseUpdateList.size() > 0)
    {
        update caseUpdateList;
    }
} */