({
    calculateMess: function (component, event, helper) {
        var records = [];
        var recordId = component.get('v.recordId');
        component.set('v.showSpinner', true);
		
        var action = component.get('c.calculateMessages');
        action.setParams({
            campaignId: recordId
        });

        action.setCallback(this, (result) => {
            component.set('v.showSpinner', false);
            if (result.getState() === 'ERROR') {
                var errors = result.getError();
                console.log(errors);
                console.log(errors[0]);
                console.log(errors.message);
                component.set('v.errors', 'ERROR: ' + errors[0].message);
            } else if (result.getState() == 'SUCCESS') {
                component.set('v.errors', 'A job has been successfully queued. Depending on the number of GAU allocations in the current campaign hierarchy, it may take 5 or more minutes to process.');
            } else {
                component.set('v.errors', 'ERROR: Something unexpected occured with this update; Please try again or contact your System Administrator');
            }
        });

        $A.enqueueAction(action);
    }
})