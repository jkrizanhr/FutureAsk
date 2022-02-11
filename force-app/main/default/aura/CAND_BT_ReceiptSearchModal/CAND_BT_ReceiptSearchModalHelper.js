({
    _fetchData: function (component, searchText) {
        //do an action to perform a search on Accounts/Donor Id (Like account/exact match on donor Id)
        //set something on the component to display the records

        //Also get receipt
        var query = 'SELECT Name, Amount, Original_Amount__c, Original_Currency__c, CloseDate, Account.Name,' +
            ' (SELECT npsp__Amount__c, Original_Amount__c, Original_Currency__c, npsp__General_Accounting_Unit__r.Name, Tax_Deductible__c from npsp__Allocations__r)' +
            ' from Opportunity WHERE Transaction_Number__c = \'' +
            searchText + '\' LIMIT 1';

        console.log('q', query);

        var action = component.get('c.opportunitySearch');
        action.setParams({
            query: query
        });

        action.setCallback(this, function (response) {
            if (response.getState() === 'SUCCESS') {
                console.log(response.getReturnValue());
                component.set('v.opportunity', response.getReturnValue());
                console.log(component.get('v.opportunity'))
            } else {
                console.log('Nothing has been found');
                console.log(response.getState());
                //set component to nothing has been found
                component.set('v.opportunity', '');
            }
        });

        $A.enqueueAction(action);
    }
})