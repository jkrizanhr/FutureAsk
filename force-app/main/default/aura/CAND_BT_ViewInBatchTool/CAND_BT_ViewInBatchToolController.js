({
  doInit: function (component, event, helper) {
    console.log('\nCAND_BTController.doInit');

    var action = component.get('c.getBTSettings');
    action.setCallback(this, (result) => {
      if (result.getState() === 'ERROR') {
        alert('Error getting Batching Tool Settings: ' + JSON.stringify(result.getError()));
      } else if (result.getState() === 'SUCCESS') {
        var btSettings = JSON.parse(result.getReturnValue());
        console.log('\nBatching Tool Settings:', btSettings);
        component.set('v.btSettings', btSettings);

        if (!btSettings) {
          component.set('v.message', 'No settings found! Please configure the custom metadata types.');
        } else {
          helper.navigate(component);
        }
      } else {
        component.set('v.message', 'Error...');
        alert('Unknown Error...');
      }
    });
    $A.enqueueAction(action);
  },
})