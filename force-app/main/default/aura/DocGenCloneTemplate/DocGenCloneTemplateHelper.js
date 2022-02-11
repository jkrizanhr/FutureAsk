({
  clone: function(component) {
    component.set('v.showSpinner');
    var action = component.get('c.clone');
    action.setParam('templateId', component.get('v.recordId'));
    action.setCallback(this, (res) => {
      component.set('v.showSpinner', false);
      if (res.getState() === 'ERROR') {
        var errors = res.getError();
        if (errors[0] && errors[0].message) {
          alert('Error message: ' + errors[0].message);
        } else {
          alert('Unknown Error');
        }
        $A.get('e.force:closeQuickAction').fire();
      } else {
        alert('Success!');
        $A.get('e.force:closeQuickAction').fire();
        var navEvt = $A.get('e.force:navigateToSObject');
        navEvt.setParams({
          'recordId': res.getReturnValue()
        });
        navEvt.fire();
      }
    });
    $A.enqueueAction(action);
  }
})