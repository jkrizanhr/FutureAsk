({
  init: function (component, event, helper) {
    var subscription = component.get('v.subscription');
    var d_startDate = Date.parse(subscription.startDate);
    if (d_startDate < Date.now() || isNaN(d_startDate)) {
      var today = new Date();
      // Javascript date madness. E.g., result is "2022-08-23"
      subscription.startDate = `${today.getFullYear()}-${(today.getMonth() + 1).toString().padStart(2, "0")}-${today.getDate().toString().padStart(2, "0")}`;
    }
  },
  handleChange: function (component, event, helper) {
    component.set('v.cardNumber', null);
    component.set('v.cvv', null);
    component.set('v.selectedMonth', '1');
    component.set('v.selectedYear', '2020');
    component.set('v.accountHolder', null);
    component.set('v.accountNumber', null);
    component.set('v.routingNumber', null);
    component.set('v.errorMessage', null);

  },
  updateSubscription: function (component, event, helper) {
    var valid = true;
    component.set('v.errorMessage', null);
    var i_startDate = Date.parse(component.get('v.subscription').startDate);
    var today = new Date();
    var i_today = Date.parse(`${today.getFullYear()}-${(today.getMonth() + 1).toString().padStart(2, "0")}-${today.getDate().toString().padStart(2, "0")}`)

    if (component.get('v.subscription').amount == null || component.get('v.subscription').amount == ''
      || component.get('v.subscription').startDate == null || component.get('v.subscription').startDate == ''
    ) {
      component.set('v.errorMessage', 'Please complete all required fields.');
      valid = false;
    } else if (i_startDate < i_today || isNaN(i_today)) { // null is less than 1
      component.set('v.errorMessage', 'Start Date must not occur before the submission date.');
      valid = false;
    }

    if (valid) {
      var recordId = component.get('v.recordId');
      var subscription = JSON.stringify(component.get('v.subscription'));
      component.set('v.loading', true);
      helper.updateSubscriptionHelper(component, recordId, subscription);
    }
  },

  updatePaymentMethod: function (component, event, helper) {
    // Check Validity
    var valid = true;
    component.set('v.errorMessage', null);

    if (component.get('v.selectedPaymentMethod') == 'Credit Card') {
      if (component.get('v.cardNumber') == null || component.get('v.cardNumber') == ""
        || component.get('v.cvv') == null || component.get('v.cvv') == ""
      ) {
        component.set('v.errorMessage', 'Please complete all required fields.');
        valid = false;
      }
      else if (component.get('v.cardNumber').length < 16) {
        component.set('v.errorMessage', 'Please enter a valid credit card number.');
        valid = false;
      }
    } else {
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
      var recordId = component.get('v.recordId');
      var subscription = JSON.stringify(component.get('v.subscription'));
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
      helper.updatePaymentMethodHelper(component, recordId, subscription, params);
    }
  },
  cancelSubscription: function (component, event, helper) {
    var recordId = component.get('v.recordId');
    var subscription = JSON.stringify(component.get('v.subscription'));
    component.set('v.loading', true);
    helper.cancelSubscriptionHelper(component, recordId, subscription);
  },
  closeModal: function (component, event, helper) {
    var evt = component.getEvent('closeWindow');
    evt.fire();
  }
})