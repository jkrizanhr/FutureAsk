({
  fetchDataHelper: function (component, recordId) {
    component.set('v.loading', true);
    return new Promise($A.getCallback(function (resolve, reject) {
      var _fetchData = component.get("c.fetchSubscription");
      console.log(recordId);
      _fetchData.setParams({
        recordId: recordId
      });

      _fetchData.setCallback(this, function (res) {
        if (res.getState() === "ERROR") {
          reject(res.getError());
        } else {
          resolve(res.getReturnValue());
          console.log(res.getReturnValue());
        }
      });
      $A.enqueueAction(_fetchData);
    }));
  },
  fetchSavedPaymentMethodsHelper: function(component){
    return new Promise($A.getCallback(function(resolve, reject) {
      var _fetchData = component.get("c.fetchSavedPaymentMethods");

      _fetchData.setCallback(this, function(res) {
        if(res.getState() === "ERROR") {
          reject(res.getError());
        } else {
          resolve(res.getReturnValue());
        }
      });
      $A.enqueueAction(_fetchData);
    }));
  },
  buildPaymentMethodListHelper : function(paymentMethods){
    var methods = [];
    for (var i=0; i < paymentMethods.length; i++){
      var pm = paymentMethods[i];
      if (pm.paymentMethod == 'Credit Card'){
        pm.label = pm.cardType
          ? pm.cardType + ' ' + pm.cardLastFour
          : 'Credit Card ' + pm.cardLastFour;
      } else {
        pm.label = 'EFT ' + pm.accountNumber;
      }
      methods.push(pm);
    }
    return methods;
  },
  updatePaymentMethodHelper: function (component, recordId, subscription, paymentMethod) {
    var _updatePaymentMethod = component.get("c.updateSubscriptionPaymentMethod");
    _updatePaymentMethod.setParams({
      recordId: recordId,
      subscription: subscription,
      paymentMethod: paymentMethod
    });

    _updatePaymentMethod.setCallback(this, function (res) {
      component.set('v.loading', false);
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
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
          title: "Error",
          message: errorMessage,
          type: "error"
        });
        toastEvent.fire();
        var evt = component.getEvent("closeWindow");
        evt.fire();
      } else {
        console.log(res.getReturnValue());
        if (res.getReturnValue() == 'Successful.'){
          var toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams({
            title: "Success!",
            message: "The payment method has been updated successfully.",
            type: "success"
          });
          toastEvent.fire();
          var evt = component.getEvent("closeWindow");
          evt.fire();
          $A.get('e.force:refreshView').fire();
        } else {
          var toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams({
            title: "Error!",
            message: "Error Message: " + res.getReturnValue(),
            mode: "sticky",
            type: "error"
          });
          toastEvent.fire();
        }
      }
    });
    $A.enqueueAction(_updatePaymentMethod);
  },
})