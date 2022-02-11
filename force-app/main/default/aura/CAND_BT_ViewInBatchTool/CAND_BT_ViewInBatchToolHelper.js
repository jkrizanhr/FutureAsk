({
    navigate: function (component) {
        var action = component.get('c.getBatchForNavigationFromRecord');
        var recordId = component.get('v.recordId');
        action.setParams({
            parentRecordId: recordId
        });
        action.setCallback(this, (response) => {
            if (response.getState() == 'SUCCESS') {
                var batch = response.getReturnValue();
                var row = {
                    Id: recordId,
                    Control_Batch_Size__c: batch.Control_Batch_Size__c,
                    Control_Batch_Total__c: batch.Control_Batch_Total__c,
                    CreatedDate: batch.CreatedDate,
                    Name: batch.Name,
                    Records_Included_In_Batch__c: batch.Records_Included_in_Batch__c,
                    // Opportunity_Type__c: batch.Opportunity_Type__c,
                    Status__c: batch.Status__c,
                    Date__c: batch.Date__c,
                    Total_Included_in_Batch__c: batch.Total_Included_in_Batch__c
                }
                var navEvent = $A.get('e.force:navigateToComponent');
                navEvent.setParams({
                    componentDef: 'c:CAND_BT_Form',
                    componentAttributes: {
                        btSettings: component.get('v.btSettings'),
                        sObjectName: 'Opportunity',
                        sObjectAPIName: 'Opportunity',
                        parentRecord: row
                    }
                });
                navEvent.fire();
            } else {
                console.log(response.getState());
            }
        })
        $A.enqueueAction(action);
    }
})