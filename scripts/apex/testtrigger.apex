trigger FutureCalculation on Future_Gift_Allocation__c (after insert, after update) {
    
    List<Project__c> projectForUpdate = new List<Project__c>();
    
    for (Future_Gift_Allocation__c FGA : Trigger.new) {
       String ProjectName = FGA.Project__c;
       String strgau = FGA.General_Accounting_Unit__c; 
       Project__c proj = new Project__c(Name = ProjectName);

// need to get projectID to run update statement

    List<Project> qproject = [Select Id from Project__c where Name=: ProjectName LIMIT 1];
    String strprojectId = qproject[0].Id;

AggregateResult[] agResults = [
    SELECT SUM(Allocation_Amount__c) total from Future_Gift_Allocation__c WHERE General_Accounting_Unit__c =:strgau AND (Future_Gift__r.Stage__c = 'Proposed' OR Future_Gift__r.Stage__c ='Solicitation' OR Future_Gift__r.Stage__c ='Commitment Made')
];
Double dbl_total = (Double)agResults[0].get('total');  
    proj.Bib_Sum_of_Future_Ask_Allocations__c = dbl_total;
    proj.Id = strprojectId;

       projectForUpdate.add(proj);
    }
    update projectForUpdate;
}