({
  fetchTemplate : function(component, recId) {
    var action = component.get('c.fetchTemplate');
    action.setParams({
       docTempId : recId
    });
    action.setCallback(this, function(result) {
      if (result.getState() === 'ERROR') {
        console.error(result.getError());
        alert(JSON.stringify(result.getError()));
      } else {
        var res = result.getReturnValue();
        component.set('v.template', res);
        this.fetchTestRecords(component, res.Salesforce_Object__c);
      }
    });
    $A.enqueueAction(action);
  },

  fetchTestRecords : function(component, templateObjectName) {
    var action = component.get('c.fetchTestRecords');
    action.setParams({
      SObjectName : templateObjectName
    });
    action.setCallback(this, function(result) {
      if (result.getState() === 'ERROR') {
        console.error(result.getError());
        alert(JSON.stringify(result.getError()));
      } else {
        var results = result.getReturnValue();
        results.unshift({
          Name: '-- Select Record --',
          Id: '',
          selected:true
        });
        component.set('v.testRecordOptions', results);
      }
    });
    $A.enqueueAction(action);
  }
})