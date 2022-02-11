({
  init: function (component, event, helper) {
    // Handle navigation
    var pageReference = {
      type: "standard__recordPage",
      attributes: {
        recordId: "To be set by event",
        objectApiName: "Opportunity",
        actionName: "view"
      }
    }
    component.set("v.pageReference", pageReference);
  },
  fullRefund: function (component, event, helper) {
    var recordId = component.get('v.recordId');
    var transaction = JSON.stringify(component.get('v.transaction'));
    component.set('v.loading', true);
    helper.fullRefundHelper(component, recordId, transaction);
  },
  closeModal: function (component, event, helper) {
    var evt = component.getEvent('closeWindow');
    evt.fire();
  }
})