({
  newPaymentMethodHelper: function (component, params) {
    var _newPaymentMethod = component.get("c.newPaymentMethod");
    _newPaymentMethod.setParams({
      paymentInfo: params
    });

    _newPaymentMethod.setCallback(this, function (res) {
      component.set('v.loading', false);
      this.handleResultsHelper(component, res, 'create');
    });
    $A.enqueueAction(_newPaymentMethod);
  },
  buildMonthAndYearPicklistsHelper: function(component){
    // build year picklist
    var yr = new Date().getFullYear();
    var yrs = [];
    for (var i = 0; i < 8; i++){
      yrs.push({
        label: yr + i, 
        value: yr + i
      });
    }
    component.set('v.selectedYear', yr);
    component.set('v.yearOptions', yrs);
    
    // build months picklist
    var mnl = ['1','2','3','4','5','6','7','8','9','10','11','12'];
    var mnv = ['01','02','03','04','05','06','07','08','09','10','11','12'];
    var mn = new Date().getMonth();
    var months = [];
    for (var i = 0; i < mnl.length; i++){
      months.push({
        label: mnl[i], 
        value: mnv[i]
      });
      if (mn == i){
        component.set('v.selectedMonth', mnv[i]);
      }
    }
    component.set('v.monthOptions', months);
  },
  updatePaymentMethodHelper: function (component, paymentMethod, params) {
    var _updatePaymentMethod = component.get("c.updatePaymentMethod");
    _updatePaymentMethod.setParams({
      paymentInfo: params,
      paymentMethod: paymentMethod
    });

    _updatePaymentMethod.setCallback(this, function (res) {
      component.set('v.loading', false);
      this.handleResultsHelper(component, res, 'update');
    });
    $A.enqueueAction(_updatePaymentMethod);
  },
  deletePaymentMethodHelper: function (component, paymentMethod) {
    var _deletePaymentMethod = component.get("c.deletePaymentMethod");
    _deletePaymentMethod.setParams({
      paymentMethod: paymentMethod
    });

    _deletePaymentMethod.setCallback(this, function (res) {
      component.set('v.loading', false);
      this.handleResultsHelper(component, res, 'delete');
    });
    $A.enqueueAction(_deletePaymentMethod);
  },
  handleResultsHelper : function(component, res, type){
    if (res.getState() === "ERROR") {
      var errors = res.getError();
      var errorMessage;
      if (errors) {
        if (errors[0] && errors[0].message) {
          errorMessage = "Error message: " + errors[0].message;
        }
      } else {
        errorMessage = "Unknown error";
      }
      console.log(errorMessage);
      component.set('v.errorMessage', errorMessage);
      component.set('v.modalType', 'Error Modal');
    } else {
      console.log(res.getReturnValue());
      var successMessage = 'Your payment method has been ' + type + 'd successfully!';
      component.set('v.successMessage', successMessage);
      component.set('v.modalType', 'Success Modal');
    }
  }
})