@isTest
public class FutureGiftAllocationTest {
    //Created 1 Feb 2022 to handle the updates to the triggerhandler for project remaining balance calculations --jkrizan
    //because this is accessing the project update, we need to make that data visible to validate the trigger hence SellAllData=true is set
    @isTest(SeeAllData=true)
//Create the method
    static void validateFutureAllocation() {
   	
//Create the test data for after insert check        
       //first create record with null project -- this validates the if statement in the class
       Future_Gift_Allocation__c FGAnoproject = new Future_Gift_Allocation__c(Future_Gift__c='a1h3i000000i20FAAQ', Allocation_Amount__c=100.00, General_Accounting_Unit__c='a0e3i000005xjsbAAA');
        insert FGAnoproject;
         System.assertEquals(null, FGAnoproject.Project__c);
 
//insert with project value
        Future_Gift_Allocation__c FGAwproject = new Future_Gift_Allocation__c(Future_Gift__c='a1h3i000000i20FAAQ', Allocation_Amount__c=100.00, General_Accounting_Unit__c='a0e3i000005xjsbAAA');
       //System.debug('Test Entry for Allocation Amount: ' + FGA.Allocation_Amount__c);

       // Insert New Future Gift Allocation Record (FGA)
       insert FGAwproject;
    
       // Retrieve the new FGA
       FGAwproject = [SELECT Name FROM Future_Gift_Allocation__c WHERE Id =:FGAwproject.Id];
       //System.debug('New Name of FGA Record after trigger fired: ' + FGA.Name);

        //get the new calculation to update the project record
        AggregateResult[] agResults = [SELECT SUM(Bib_Probability_Total__c) from Future_Gift_Allocation__c WHERE General_Accounting_Unit__c ='a0e3i000005xjsbAAA' AND (Future_Gift__r.Stage__c = 'Proposed' OR Future_Gift__r.Stage__c ='Solicitation' OR Future_Gift__r.Stage__c ='Commitment Made')];
		Double dbl_total = (Double)agResults[0].get('expr0');  
        
        //based on the record that I am using the adding of 100 should make the value 2500
        System.assertEquals(1100100, dbl_total);
    
  //check the After Update section of the code with the same FGA record we just tested with.  
  //Lets update the Tax Deductible Field to False
 		FGAwproject.Tax_Deductible__c = False;
        update FGAwproject;
		
        Future_Gift_Allocation__c FGAupdate = [SELECT Name, Tax_Deductible__c FROM Future_Gift_Allocation__c WHERE Id =:FGAwproject.Id];
   		System.assert(FGAupdate.Tax_Deductible__c != True);      
  //lets verify that the calculated amount stays the same        
        AggregateResult[] agResults2 = [SELECT SUM(Bib_Probability_Total__c) from Future_Gift_Allocation__c WHERE General_Accounting_Unit__c ='a0e3i000005xjsbAAA' AND (Future_Gift__r.Stage__c = 'Proposed' OR Future_Gift__r.Stage__c ='Solicitation' OR Future_Gift__r.Stage__c ='Commitment Made')];
		Double dbl_total2 = (Double)agResults2[0].get('expr0');  
        System.assertEquals(1100100, dbl_total2);
    }
    }