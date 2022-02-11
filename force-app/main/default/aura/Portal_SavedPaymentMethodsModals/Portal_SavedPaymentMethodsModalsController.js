({
  init: function (component, event, helper) {
    helper.buildMonthAndYearPicklistsHelper(component);
  },
  handleChange: function (component, event, helper) {
    component.set('v.cardNumber', null);
    component.set('v.cvv', null);
    component.set('v.selectedMonth', new Date().getMonth());
    component.set('v.selectedYear', new Date().getFullYear());
    component.set('v.accountHolder', null);
    component.set('v.accountNumber', null);
    component.set('v.routingNumber', null);
    component.set('v.errorMessage', null);
  },
  handleBuildPaymentMethod: function (component, event, helper) {
    // Check Validity
    var valid = true;
    component.set('v.errorMessage', null);

    // Check Credit Card Fields
    if (component.get('v.selectedPaymentMethod') == 'Credit Card') {
      if (component.get('v.cardNumber') == null || component.get('v.cardNumber') == ""
        || component.get('v.cvv') == null || component.get('v.cvv') == ""
      ) {
        component.set('v.errorMessage', 'Please complete all required fields.');
        valid = false;
      }
      else if (component.get('v.cardNumber').length < 13) {
        component.set('v.errorMessage', 'Please enter a valid credit card number.');
        valid = false;
      }
    } 
    // Check Bank Account Fields
    else {
      if (component.get('v.accountHolder') == null || component.get('v.accountHolder') == ""
        || component.get('v.accountNumber') == null || component.get('v.accountNumber') == ""
        || component.get('v.routingNumber') == null || component.get('v.routingNumber') == ""
      ) {
        component.set('v.errorMessage', 'Please complete all required fields.');
        valid = false;
      }
    }
    // If Valid - Update Payment Method
    if (valid) {
      var params = component.get('v.paymentInfo');
      params['paymentMethod'] = component.get('v.selectedPaymentMethod');
      params['cardNumber'] = component.get('v.cardNumber');
      params['cvv'] = component.get('v.cvv');
      params['selectedMonth'] = component.get('v.selectedMonth');
      params['selectedYear'] = component.get('v.selectedYear');
      params['accountHolder'] = component.get('v.accountHolder');
      params['accountNumber'] = component.get('v.accountNumber');
      params['routingNumber'] = component.get('v.routingNumber');
      component.set('v.loading', true);
      if (component.get('v.paymentMethod')){
        var paymentMethod = JSON.stringify(component.get('v.paymentMethod'));
        helper.updatePaymentMethodHelper(component, paymentMethod, params);
      } else {
        helper.newPaymentMethodHelper(component, params);
      }
    }
  },
  handleDeletePaymentMethod: function(component, event, helper){
    var paymentMethod = JSON.stringify(component.get('v.paymentMethod'));
    helper.deletePaymentMethodHelper(component, paymentMethod);
  },
  closeModal: function (component, event, helper) {
    $A.get('e.force:refreshView').fire();
    var evt = component.getEvent('closeWindow');
    evt.fire();
  }
})