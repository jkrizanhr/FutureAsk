({
  init: function (component, event, helper) {
    component.set('v.year', new Date().getFullYear());
    helper.fetchDataHelper(component)
      .then($A.getCallback(function(results) {
        helper.createTwitterMessageHelper(component, results);
        component.set('v.projects', results);
      }));
  },
  openDonateTab: function(component, event, helper){
    location.href = '/s/give?gauId=' + event.getSource().get('v.value');
  }
})