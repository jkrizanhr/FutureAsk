({
  init: function (component, event, helper) {
    helper.fetchDataHelper(component, component.get('v.recordId'))
      .then($A.getCallback(function (results) {
        component.set('v.transaction', results);
        component.set('v.loading', false);
      }));
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

  handleClick: function (component, event, helper) {
    var button = event.getSource().get("v.value");
    component.set('v.modalType', button);
  },

  openOpp: function (component, event, helper) {
    var navService = component.find("navService");
    var pageReference = component.get("v.pageReference");
    pageReference.attributes.recordId = event.getSource().get("v.value");
    component.set("v.pageReference", pageReference);
    navService.navigate(pageReference);
  },

  closeModal: function (component, event, helper) {
    component.set('v.modalType', null);
  }
})