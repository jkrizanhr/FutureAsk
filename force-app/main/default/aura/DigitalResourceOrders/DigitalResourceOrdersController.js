({
  init : function(component, event, helper) {
    helper.fetchDataHelper(component, component.get('v.recordId'))
    .then($A.getCallback(function(results) {
      var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
      component.set('v.today', today);
      component.set('v.partner', results);
      component.set('v.loading', false);  
    }));
  },
  handleResourceOrderSuccess : function(component, event, helper) {
    var resourceOrder = JSON.parse(JSON.stringify(event.getParams()));
    component.set('v.resourceOrderId', resourceOrder.response.id);
    component.set('v.componentTitle', 'Add Resource Order Items');
  },
  handleResourceOrderItemSuccess : function(component, event, helper) {
    var resourceOrderItem = JSON.parse(JSON.stringify(event.getParams()));
    var roiIds = component.get('v.resourceOrderItems');
    roiIds.push(resourceOrderItem.response.id);
    component.set('v.resourceOrderItems', roiIds);
    component.find('roiResource').reset();
    component.find('roiAmount').reset();
    component.set('v.roiPrice', 0);
    component.set('v.roiQuantity', 1);
  },
  handleClick : function(component, event, helper){
    var index = event.getSource().get("v.value");
    var roiIds = component.get('v.resourceOrderItems');
    var roiId = roiIds[index];
    roiIds.splice(index, 1);
    component.set('v.resourceOrderItems', roiIds);
    helper.deleteResourceOrderItemHelper(component, roiId);
  },
  cancelOrder : function(component, event, helper){
    var roId = component.get('v.resourceOrderId');
    component.set('v.loading', true);
    helper.deleteResourceOrderHelper(component, roId);
  },
  submitOrder : function(component, event, helper){
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
        "title": "Success!",
        "message": "The resource order has been submitted successfully."
    });
    toastEvent.fire();
    component.set('v.resourceOrderId', null);
    component.set('v.resourceOrderItems', []);
    component.set('v.componentTitle', 'Log Shared Digital Resources');
  }
})