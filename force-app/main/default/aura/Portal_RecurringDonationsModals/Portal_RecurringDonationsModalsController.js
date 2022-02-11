({
  init: function (component, event, helper) {
    component.set('v.isLoading', true);
    helper.fetchDataHelper(component, component.get('v.recordId'))
      .then($A.getCallback(function (results) {
        component.set('v.subscription', results);
        component.set('v.loading', false);
      }));
    helper.fetchSavedPaymentMethodsHelper(component)
      .then($A.getCallback(function (results) {
        component.set('v.paymentMethods', helper.buildPaymentMethodListHelper(results));
        component.set('v.loadingPaymentMethods', false);
      }));
  },
  updatePaymentMethod: function(component, event, helper){
    var recordId = component.get('v.recordId');
    var subscription = JSON.stringify(component.get('v.subscription'));
    // Get Payment Method
    var paymentId = component.find('pm').get('v.value');
    var methods = component.get('v.paymentMethods');
    var paymentMethod = null;
    for (var i=0; i < methods.length; i++){
      if (methods[i].id == paymentId){
        paymentMethod = methods[i];
        break;
      }
    }
    paymentMethod = JSON.stringify(paymentMethod);
    component.set('v.loading', true);
    helper.updatePaymentMethodHelper(component, recordId, subscription, paymentMethod);
  },
  closeModal: function (component, event, helper) {
    var evt = component.getEvent('closeWindow');
    evt.fire();
  }
})