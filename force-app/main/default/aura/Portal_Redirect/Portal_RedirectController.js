({
  doInit : function(component, event, helper) {
    helper.fetchCurrentSessionTypeHelper(component)
    .then($A.getCallback(function(results) {
      if (results.SessionType != 'LivePreview'){
        location.href = '/s/' + component.get('v.redirect');
      } else {
        component.set('v.isCommunityBuilder', true);
      }
    }));
  }
})