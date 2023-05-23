import { LightningElement, wire, api } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getFutureGiftAllocations from '@salesforce/apex/Project_Finance_LWC_Controller.getFutureGiftAllocations';
import getGAUBalance from '@salesforce/apex/Project_Finance_LWC_Controller.getGAUBalance';
import getGAUAllocation from '@salesforce/apex/Project_Finance_LWC_Controller.getGAUAllocation';
import getTransferData from '@salesforce/apex/Project_Finance_LWC_Controller.getTransferData';
import updateProjectRecord from '@salesforce/apex/Project_Finance_LWC_Controller.updateProjectRecord';

export default class Project_Finance extends LightningElement {
    @api objectApiName;
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: ['Project__c.Name', 'Project__c.Total_Project_FY_Cost__c'] })
    record;

    @wire(getFutureGiftAllocations, { strprojectname: '$recordName' })
    futureGiftAllocations;

    @wire(getGAUBalance, { strprojectID: '$recordId' })
    gauBalance;

    @wire(getGAUAllocation, { strprojectID: '$recordId' })
    gauAllocations;

    @wire(getTransferData, { strprojectID: '$recordId' })
    transferData;

    get recordName() {
        return getFieldValue(this.record.data, 'Project__c.Name');
    }

    get totalProjectFYCost() {
        return getFieldValue(this.record.data, 'Project__c.Total_Project_FY_Cost__c');
    }

    renderedCallback() {
        if (!this.sortableInitialized) {
            this.sortableInitialized = true;
            this.initializeSortable();
        }
    }

    initializeSortable() {
        let tables = this.template.querySelectorAll('table.sortable');
        tables.forEach((table) => {
            let headers = table.querySelectorAll('th');
            headers.forEach((header, index) => {
                header.addEventListener('click', () => {
                    this.sortTable(table, index);
                });
            });
        });
    }

    sortTable(table, columnIndex) {
        let rows = Array.from(table.querySelectorAll('tbody tr'));
        let sortedRows = rows.sort((a, b) => {
            let aText = a.cells[columnIndex].textContent.trim();
            let bText = b.cells[columnIndex].textContent.trim();
            if (!isNaN(aText) && !isNaN(bText)) {
                return parseFloat(aText) - parseFloat(bText);
            }
            return aText.localeCompare(bText);
        });
        if (table.sortedColumnIndex === columnIndex) {
            sortedRows.reverse();
            table.sortedColumnIndex = null;
        } else {
            table.sortedColumnIndex = columnIndex;
        }
        let tbody = table.querySelector('tbody');
        sortedRows.forEach((row) => {
            tbody.appendChild(row);
        });
    }

    get data() {
        return {
            allocationAmountsSum: this.futureGiftAllocations.data ? this.futureGiftAllocations.data.sumAllocationAmount : 0,
            probabilityTotals: this.futureGiftAllocations.data ? this.futureGiftAllocations.data.sumBibFundingStatusProbabilityTotal : 0,
            gauBalanceSum: this.gauBalance.data ? this.gauBalance.data.sumGPBalance : 0,
            gauAllocationsSum: this.gauAllocations.data ? this.gauAllocations.data.sumAmount : 0,
            transferTotals: this.transferData.data ? this.transferData.data.sumTransferAmount : 0,
            gauBalanceData: this.gauBalance.data ? this.gauBalance.data.records : [],
        gauAllocationData: this.gauAllocations.data ? this.gauAllocations.data.records : [],
        allocationAmounts: this.futureGiftAllocations.data ? this.futureGiftAllocations.data.FGArecords : [],
        transferData: this.transferData.data ? this.transferData.data.records : []
        };
        
    }

    get remainingFYNeed() {
        const {
            totalProjectFYCost,
            data: { gauBalanceSum, gauAllocationsSum, allocationAmountsSum, transferTotals },
        } = this;
        // Log the variable values for checking
    console.log(totalProjectFYCost);
    console.log(gauBalanceSum);
    console.log(gauAllocationsSum);
    console.log(allocationAmountsSum);
    console.log(transferTotals);
    console.log(allocationAmounts);
        return totalProjectFYCost - gauBalanceSum - gauAllocationsSum - allocationAmountsSum - transferTotals;
      
    }

    updateProjectRecord() {
        updateProjectRecord({
            projectId: this.recordId,
            allocationAmountsSum: this.data.allocationAmountsSum,
            probabilityTotals: this.data.probabilityTotals,
            gauBalanceSum: this.data.gauBalanceSum,
            gauAllocationsSum: this.data.gauAllocationsSum,
            transferTotals: this.data.transferTotals,
            remainingFYNeedValue: this.remainingFYNeed
        })
        .then(() => {
            alert('Project record updated successfully.');
            return this.refreshData();
        })
        .catch(error => {
            console.error('Error updating project record:', error);
            alert('Failed to update project record.');
        });
    }
}
