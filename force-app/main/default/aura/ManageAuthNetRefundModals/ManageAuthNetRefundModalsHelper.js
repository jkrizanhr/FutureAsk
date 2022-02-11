({
  fullRefundHelper: function (component, recordId, transaction) {
    var _fullRefund = component.get("c.issueFullRefund");
    _fullRefund.setParams({
      recordId: recordId,
      transInfo: transaction
    });

    _fullRefund.setCallback(this, function (res) {
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
        reject(errors);
      } else {
        console.log(res.getReturnValue());
        // Show Success Toast
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
          title: "Success!",
          message: "The transaction has been refunded successfully.",
          type: "success"
        });
        toastEvent.fire();

        // Redirect to New Opportunity
        var navService = component.find("navService");
        var pageReference = component.get("v.pageReference");
        pageReference.attributes.recordId = res.getReturnValue();
        component.set("v.pageReference", pageReference);
        navService.navigate(pageReference);
      }
    });
    $A.enqueueAction(_fullRefund);
  }
});