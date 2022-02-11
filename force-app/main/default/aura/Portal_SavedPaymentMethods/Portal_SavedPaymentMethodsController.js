({
  doInit : function(component, event, helper) {
    component.set('v.isLoading', true);
    var isMobile = helper.detectMobileHelper();
    component.set('v.isMobile', isMobile);
    helper.fetchDataHelper(component)
      .then($A.getCallback(function(results) {
        component.set('v.paymentMethods', results);
        component.set('v.isLoading', false);
      }));
  },
  closeModal : function(component, event, helper){
    component.set('v.modalType', null);
    component.set('v.selectedPaymentMethod', null);
  },
  // Update Payment Method Modal
  handleUpdate : function(component, event, helper){
    var paymentMethod = null;
    var pmId = event.getSource().get('v.value');
    var methods = component.get('v.paymentMethods');
    for (var i=0; i < methods.length; i++){
      if(methods[i].id == pmId){
        paymentMethod = methods[i];
        break;
      }
    }
    component.set('v.selectedPaymentMethod', paymentMethod);
    component.set('v.modalType', 'Update Payment Method');
  },
  // Delete Payment Method Modal
  handleDelete : function(component, event, helper){
    var paymentMethod = null;
    var pmId = event.getSource().get('v.value');
    var methods = component.get('v.paymentMethods');
    for (var i=0; i < methods.length; i++){
      if(methods[i].id == pmId){
        paymentMethod = methods[i];
        break;
      }
    }
    component.set('v.selectedPaymentMethod', paymentMethod);
    component.set('v.modalType', 'Delete Payment Method');
  },
  // New Payment Method Modal
  handleNew : function(component, event, helper){
    component.set('v.modalType', 'Add Payment Method');
  }
})