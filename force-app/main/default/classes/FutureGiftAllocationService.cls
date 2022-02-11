public inherited sharing class FutureGiftAllocationService {
  
  public static void allocationAmountNotToExceedFutureGift(List<Future_Gift_Allocation__c> allocs, Map<Id, Future_Gift_Allocation__c> oldMap) {
    Map<Id, List<Future_Gift_Allocation__c>> futureGiftAllocMap = new Map<Id, List<Future_Gift_Allocation__c>>();
    Map<Id, Double> oldFutureGiftMap = new Map<Id, Double>();
    
    for (Future_Gift_Allocation__c fga : allocs) {
      if (oldMap != null) {
        Future_Gift_Allocation__c oldFga = oldMap.get(fga.Id);
        if (
          oldFga != null && ((oldFga.Future_Gift__c != fga.Future_Gift__c) ||
          (oldFga.Future_Gift__c == fga.Future_Gift__c && oldFga.Allocation_Amount__c != fga.Allocation_Amount__c))
        ) {
          if (oldFga.Future_Gift__c != null && fga.Validate_Allocation__c == true) {
            Double temp = !oldFutureGiftMap.isEmpty() && oldFutureGiftMap.get(oldFga.Future_Gift__c) != null
              ? oldFutureGiftMap.get(oldFga.Future_Gift__c)
              : 0;
            temp += oldFga.Allocation_Amount__c;
            oldFutureGiftMap.put(oldFga.Future_Gift__c, temp);
          }
          if (fga.Future_Gift__c != null && fga.Validate_Allocation__c == true) {
            List<Future_Gift_Allocation__c> temp = !futureGiftAllocMap.isEmpty() && futureGiftAllocMap.get(fga.Future_Gift__c) != null
              ? futureGiftAllocMap.get(fga.Future_Gift__c)
              : new List<Future_Gift_Allocation__c>();
            temp.add(fga);
            futureGiftAllocMap.put(fga.Future_Gift__c, temp);
          }
        }
      } else {
        if (fga.Future_Gift__c != null && fga.Validate_Allocation__c == true) {
          List<Future_Gift_Allocation__c> temp = !futureGiftAllocMap.isEmpty() && futureGiftAllocMap.get(fga.Future_Gift__c) != null
            ? futureGiftAllocMap.get(fga.Future_Gift__c)
            : new List<Future_Gift_Allocation__c>();
          temp.add(fga);
          futureGiftAllocMap.put(fga.Future_Gift__c, temp);          
        }
      }
    }

    Map<Id, Future_Gift__c> futureGiftMap = new Map<Id, Future_Gift__c>(
      [SELECT Id, Actual_Ask_Amount__c FROM Future_Gift__c WHERE Id IN :futureGiftAllocMap.keySet() AND Validate_Allocations__c = true]
    );

    for (AggregateResult ar : [
      SELECT sum(Allocation_Amount__c) amt, Future_Gift__c
      FROM Future_Gift_Allocation__c
      WHERE Future_Gift__c IN :futureGiftAllocMap.keySet()
        AND Future_Gift__r.Validate_Allocations__c = true
      GROUP BY Future_Gift__c
    ]) {
      Id fgId = String.valueOf(ar.get('Future_Gift__c'));
      if (fgId != null) {
        Double askAmount = futureGiftMap.get(fgId).Actual_Ask_Amount__c;
        Double allocAmount = Double.valueOf(ar.get('amt'));
        Double negativeAmount = !oldFutureGiftMap.isEmpty() && oldFutureGiftMap.get(fgId) != null
          ? oldFutureGiftMap.get(fgId) : 0;
        Double currentAmount = allocAmount - negativeAmount;

        List<Future_Gift_Allocation__c> fgaList = futureGiftAllocMap.get(fgId);
        for (Future_Gift_Allocation__c fga : fgaList){
          if (askAmount >= currentAmount + fga.Allocation_Amount__c){
            currentAmount += fga.Allocation_Amount__c;
          } else {
            fga.Allocation_Amount__c.addError('The sum of the Future Ask Allocations cannot exceed the Future Ask Actual Amount.');
          }
        }
      }
    }

    for (Id fgId : futureGiftAllocMap.keySet()){
      List<Future_Gift_Allocation__c> fgaList = futureGiftAllocMap.get(fgId);
      if (fgaList.size() == 1){
        Future_Gift__c fg = futureGiftMap.get(fgId);
        if (fg.Actual_Ask_Amount__c < fgaList[0].Allocation_Amount__c){
          fgaList[0].Allocation_Amount__c.addError('The sum of the Future Ask Allocations cannot exceed the Future Ask Actual Amount.');
        }
      }
    }
  }
    
  //jkrizan 2-4-22 deployed I added this method to the current class to simplify code.  However, I wrote my own testclass for it called FutureGiftAllocationTest --
  //I wanted my test class seperate from anything Candoris had written.  But, I wanted to simplify where to look for code.

  //Create the list to hold the project value that is stored on the FundGiftAllocation object.  The Project field here is a formula field drawing in the project name
   //therefore, we are going to take the project name and use SOQL to pull over the ID
    public static void calcprojectsum(){
    List<Project__c> projectForUpdate = new List<Project__c>();
   
   //take the current Future Gift Allocation Record and place that in a list.  Note the (List <Future Gift All...> is needed to convert this from trigger to trigger handler 
    for (Future_Gift_Allocation__c FGA :(List <Future_Gift_Allocation__c>) Trigger.new) {

   //Conditional needed to validate that there is a project record to write the calculated value to...if not, then simply exit the process 
     if (FGA.Project__c != 'GAU not connected to a Project'){
	//capture the projectname from record 
        String strProjectName = FGA.Project__c;
        
// 	 System.debug(strProjectName);
 	//Capture the GAU on the record  
       String strgau = FGA.General_Accounting_Unit__c; 
 	//      System.debug(strgau);
         
        Project__c proj = new Project__c(Name = strProjectName);

	// need to get projectID to run update statement
    List<Project__c> qproject = [Select Id, Name from Project__c where Name=: strProjectName LIMIT 1];

	//assign the ID to a variable
    String strprojectId = qproject[0].Id;
    System.debug(strprojectid);
        
	//query the calculation based on gau and future gift stage    
		AggregateResult[] agResults = [
    		SELECT SUM(Bib_Probability_Total__c) from Future_Gift_Allocation__c WHERE General_Accounting_Unit__c =:strgau AND (Future_Gift__r.Stage__c = 'Proposed' OR Future_Gift__r.Stage__c ='Solicitation' OR Future_Gift__r.Stage__c ='Commitment Made')
];

	//assign the calculated SUM to a variable
		Double dbl_total = (Double)agResults[0].get('expr0');  
	//        System.debug(dbl_total);
	//Assign the project record that will be updated with the total sum calculated
    proj.Bib_Sum_of_Future_Ask_Allocations__c = dbl_total;
    
//use the queried ID to ensure proper record match on the project to be updated with the SUM value    
	   proj.Id = strprojectId;
       projectForUpdate.add(proj);
            
 //Update the project record with the SUM value   
    update projectForUpdate;
        } 
 } // to end the for loop
     
 }// to end method    
}