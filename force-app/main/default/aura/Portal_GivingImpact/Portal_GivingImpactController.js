({
  init: function (component, event, helper) {
    helper.fetchDataHelper(component)
      .then($A.getCallback(function(results) {
        component.set('v.contact', results);
      }));
  },
})