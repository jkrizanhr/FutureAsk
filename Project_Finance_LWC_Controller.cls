public with sharing class Project_Finance_LWC_Controller {
    private static Period getCurrentFiscalYear() {
    return [SELECT StartDate, EndDate FROM Period WHERE Type = 'Year' AND StartDate <= TODAY AND EndDate >= TODAY LIMIT 1];
}

// Wrapper class definition
public class FutureGiftAllocationWrapper {
    @AuraEnabled public List<Future_Gift_Allocation__c> FGArecords {get; set;}
    @AuraEnabled public Decimal sumAllocationAmount {get; set;}
    @AuraEnabled public Decimal sumBibFundingStatusProbabilityTotal {get; set;}

    public FutureGiftAllocationWrapper(List<Future_Gift_Allocation__c> FGArecords, Decimal sumAllocationAmount, Decimal sumBibFundingStatusProbabilityTotal) {
        this.FGArecords = FGArecords;
        this.sumAllocationAmount = sumAllocationAmount;
        this.sumBibFundingStatusProbabilityTotal = sumBibFundingStatusProbabilityTotal;
    }
}

@AuraEnabled(cacheable=true)
public static FutureGiftAllocationWrapper getFutureGiftAllocations(String strprojectname) {
    Period currentFiscalYear = getCurrentFiscalYear();
    List<Future_Gift_Allocation__c> FGArecords = [SELECT Id, Name, General_Accounting_Unit__r.Name, Allocation_Amount__c, Bib_Funding_Status_Probability_Total__c, Future_Gift__r.Stage__c, 
        Future_Gift__r.Probability_m__c,  Future_Gift__r.Actual_Ask_Date__c FROM Future_Gift_Allocation__c 
        WHERE Project__c = :strprojectname AND 
        Future_Gift__r.Actual_Ask_Date__c >= :currentFiscalYear.StartDate AND 
        Future_Gift__r.Actual_Ask_Date__c <= :currentFiscalYear.EndDate AND
        (Future_Gift__r.Stage__c = 'Commitment Made' OR Future_Gift__r.Stage__c = 'Solicitation' OR Future_Gift__r.Stage__c = 'Proposed') 
    ];

    Decimal sumAllocationAmount = 0;
    Decimal sumBibFundingStatusProbabilityTotal = 0;

    for (Future_Gift_Allocation__c record : FGArecords) {
        sumAllocationAmount += record.Allocation_Amount__c;
        sumBibFundingStatusProbabilityTotal += record.Bib_Funding_Status_Probability_Total__c;
    }
System.debug(sumAllocationAmount);
System.debug(sumBibFundingStatusProbabilityTotal);
System.debug(FGARecords);
return new FutureGiftAllocationWrapper(FGArecords, sumAllocationAmount, sumBibFundingStatusProbabilityTotal);
}

    // Wrapper class definition for GAU_Balance__c
public class GAUBalanceWrapper {
    @AuraEnabled public List<GAU_Balance__c> records {get; set;}
    @AuraEnabled public Decimal sumGPBalance {get; set;}

    public GAUBalanceWrapper(List<GAU_Balance__c> records, Decimal sumGPBalance) {
        this.records = records;
        this.sumGPBalance = sumGPBalance;
    }
}

@AuraEnabled(cacheable=true)
public static GAUBalanceWrapper getGAUBalance(String strprojectID) {
    Period currentFiscalYear = getCurrentFiscalYear();
    List<GAU_Balance__c> records = [SELECT Id, Date__c, General_Accounting_Unit__r.Name, GP_Balance__c FROM GAU_Balance__c WHERE 
        General_Accounting_Unit__r.Grouping_GAU_Project__c = :strprojectID AND 
        (Date__c >= :currentFiscalYear.StartDate AND Date__c <= :currentFiscalYear.EndDate)
    ];

    Decimal sumGPBalance = 0;

    for (GAU_Balance__c record : records) {
        sumGPBalance += record.GP_Balance__c;
    }
    	System.debug('ID' + strprojectID);
System.debug(sumGPBalance);

    return new GAUBalanceWrapper(records, sumGPBalance);
}

// Wrapper class definition for npsp__Allocation__c
public class GAUAllocationWrapper {
    @AuraEnabled public List<npsp__Allocation__c> records {get; set;}
    @AuraEnabled public Decimal sumAmount {get; set;}

    public GAUAllocationWrapper(List<npsp__Allocation__c> records, Decimal sumAmount) {
        this.records = records;
        this.sumAmount = sumAmount;
    }
}

@AuraEnabled(cacheable=true)
public static GAUAllocationWrapper getGAUAllocation(String strprojectID) {
    Period currentFiscalYear = getCurrentFiscalYear();
    List<npsp__Allocation__c> records = [SELECT npsp__Opportunity__r.Name, npsp__Amount__c, Original_Opportunity_Close_Date__c, npsp__General_Accounting_Unit__c FROM npsp__Allocation__c WHERE npsp__General_Accounting_Unit__r.Grouping_GAU_Project__c = :strprojectID AND 
        (Original_Opportunity_Close_Date__c >= :currentFiscalYear.StartDate AND Original_Opportunity_Close_Date__c <= :currentFiscalYear.EndDate)
    ];

    Decimal sumAmount = 0;

    for (npsp__Allocation__c record : records) {
        sumAmount += record.npsp__Amount__c;
    }
	System.debug(strprojectID);
    System.debug(sumAmount);
    return new GAUAllocationWrapper(records, sumAmount);
}

// Wrapper class definition for transfer__c
public class TransferDataWrapper {
    @AuraEnabled public List<transfer__c> records {get; set;}
    @AuraEnabled public Decimal sumTransferAmount {get; set;}

    public TransferDataWrapper(List<transfer__c> records, Decimal sumTransferAmount) {
        this.records = records;
        this.sumTransferAmount = sumTransferAmount;
    }
}

@AuraEnabled(cacheable=true)
public static TransferDataWrapper getTransferData(String strprojectID) {
    Period currentFiscalYear = getCurrentFiscalYear();
    List<transfer__c> records = [SELECT Amount__c, Date__c, Secondary_General_Accounting_Unit__r.Name, Primary_General_Accounting_Unit__r.Project__c FROM Transfer__c WHERE Type__c = 'From' AND Status__c = 'Complete' AND Primary_General_Accounting_Unit__r.Grouping_GAU_Project__c =:strprojectID
        AND (Date__c >= :currentFiscalYear.StartDate AND Date__c <= :currentFiscalYear.EndDate)
    ];

    Decimal sumTransferAmount = 0;

    for (transfer__c record : records) {
        sumTransferAmount += record.Amount__c;
    }

    return new TransferDataWrapper(records, sumTransferAmount);
}

    @AuraEnabled
    public static void updateProjectRecord(Id projectId, String data) {
        Map<String, Object> dataMap = (Map<String, Object>) JSON.deserialize(data, Map<String, Object>.class);

        Project__c project = new Project__c(
            Id = projectId,
            Current_FY_Starting_Balance__c = (Decimal) dataMap.get('gauBalanceSum'),
            Actual_Funds_Raised__c = (Decimal) dataMap.get('gauAllocationsSum'),
            Funds_Expected_this_FY__c = (Decimal) dataMap.get('probabilityTotals'),
            Funds_Transfered_to_Project__c = (Decimal) dataMap.get('transferTotals'),
            Remaining_FY_Need__c = (Decimal) dataMap.get('remainingFYNeed')

        );
            
        update project;
    }
}
