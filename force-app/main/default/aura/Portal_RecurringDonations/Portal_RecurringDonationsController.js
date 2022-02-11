({
  init: function (component, event, helper) {
    var isMobile = helper.detectMobileHelper();
    component.set('v.isMobile', isMobile);
    helper.fetchDataHelper(component)
      .then($A.getCallback(function(results) {
        component.set('v.recurringDonations', results);
        helper.setDaysOfMonthSuffixHelper(component);
        component.set('v.isLoading', false);
      }));
  },
  // FAQ Modal
  toggleModal : function(component, event, helper){
    component.set('v.showFAQs', !component.get('v.showFAQs'));
  },
  goToGivePage : function(component, event, helper){
    location.href = '/s/give';
  },
  // Update Subscription Modal
  closeModal : function(component, event, helper){
    component.set('v.modalType', null);
    component.set('v.recordId', null);
  },
  updateSubscription : function(component, event, helper){
    component.set('v.recordId', event.getSource().get('v.value'));
    component.set('v.modalType', 'Update Payment Method');
  }
})