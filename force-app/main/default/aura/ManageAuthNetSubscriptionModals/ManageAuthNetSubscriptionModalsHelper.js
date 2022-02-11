({
  // TODO: PASS UPDATED SUBSCRIPTION BACK TO PARENT COMPONENT
  updateSubscriptionHelper: function (component, recordId, subscription) {
    var _updateSubscription = component.get("c.updateAuthNetSubscription");
    _updateSubscription.setParams({
      recordId: recordId,
      subscription: subscription
    });

    _updateSubscription.setCallback(this, function (res) {
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
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
          title: "Success!",
          message: "The subscription has been updated successfully.",
          type: "success"
        });
        toastEvent.fire();
        var evt = component.getEvent("closeWindow");
        evt.fire();
      }
    });
    $A.enqueueAction(_updateSubscription);
  },

  updatePaymentMethodHelper: function (component, recordId, subscription, params) {
    var _updatePaymentMethod = component.get("c.updateAuthNetPaymentMethod");
    _updatePaymentMethod.setParams({
      recordId: recordId,
      subscription: subscription,
      paymentInfo: params
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
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
          title: "Success!",
          message: "The payment method has been updated successfully.",
          type: "success"
        });
        toastEvent.fire();
        var evt = component.getEvent("closeWindow");
        evt.fire();
      }
    });
    $A.enqueueAction(_updatePaymentMethod);
  },

  cancelSubscriptionHelper: function (component, recordId, subscription) {
    var _cancelSubscription = component.get("c.cancelAuthNetSubscription");
    _cancelSubscription.setParams({
      recordId: recordId,
      subscription: subscription
    });

    _cancelSubscription.setCallback(this, function (res) {
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
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
          title: "Success!",
          message: "The subscription has been cancelled successfully.",
          type: "success"
        });
        toastEvent.fire();
        var evt = component.getEvent("closeWindow");
        evt.fire();
      }
    });
    $A.enqueueAction(_cancelSubscription);
  }
});