({
  init: function (component, event, helper) {
    helper.fetchDataHelper(component, component.get('v.recordId'))
      .then($A.getCallback(function (results) {
        component.set('v.subscription', results);
        component.set('v.loading', false);
      }));
  },

  handleClick: function (component, event, helper) {
    var button = event.getSource().get("v.value");
    component.set('v.modalType', button);
  },

  closeModal: function (component, event, helper) {
    component.set('v.modalType', null);
    // Refresh Component 
    helper.fetchDataHelper(component, component.get('v.recordId'))
      .then($A.getCallback(function (results) {
        component.set('v.subscription', results);
        component.set('v.loading', false);
      }));
    // Refresh Record Page
    $A.get('e.force:refreshView').fire();
  }
})