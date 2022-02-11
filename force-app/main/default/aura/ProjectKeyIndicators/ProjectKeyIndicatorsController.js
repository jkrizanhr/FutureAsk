({
  init: function (component, event, helper) {
    helper.fetchDataHelper(component, component.get('v.recordId'))
      .then($A.getCallback(function(results) {
        component.set('v.project', results);
        
        if (results.Clickup_Status_Snapshots__r){
          var operational = results.Clickup_Status_Snapshots__r && results.Clickup_Status_Snapshots__r[0].Total_Tasks__c == 0 ? 0 
            : Math.floor(results.Clickup_Status_Snapshots__r[0].Total_Completed_Tasks__c/results.Clickup_Status_Snapshots__r[0].Total_Tasks__c*100);
          component.set('v.operational', operational);
        }
        var financial = results.Total_Funding_Need__c == 0 ? 100 
          : Math.floor(results.Actual_Received__c/results.Total_Funding_Need__c*100);
        component.set('v.financial', financial);
        
        var deliverable = results.Number_of_Active_Deliverables__c == 0 ? 0 
          : Math.floor(results.Number_of_Complete_Deliverables__c/results.Number_of_Active_Deliverables__c*100);
        component.set('v.deliverable', deliverable);
        
      }));
  },
})