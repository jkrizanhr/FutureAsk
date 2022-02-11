({
  fetchDataHelper: function (component, recordId) {      
    return new Promise($A.getCallback(function(resolve, reject) {
      var _fetchData = component.get("c.fetchData");
      _fetchData.setParams({
        recordId : recordId
      });

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
  deleteResourceOrderItemHelper : function(component, roiId) {
    var _deleteResourceOrderItem = component.get("c.deleteResourceOrderItem");
    _deleteResourceOrderItem.setParams({
      roiId : roiId
    });

    _deleteResourceOrderItem.setCallback(this, function(res) {
      if(res.getState() === "ERROR") {
        console.log(res.getError());
      }
    });
    $A.enqueueAction(_deleteResourceOrderItem);
  },
  deleteResourceOrderHelper : function(component, roId) {
    var _deleteResourceOrder = component.get("c.deleteResourceOrder");
    _deleteResourceOrder.setParams({
      roId : roId
    });

    _deleteResourceOrder.setCallback(this, function(res) {
      if(res.getState() === "ERROR") {
        console.log(res.getError());
      } else {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Cancelled!",
            "message": "The resource order has been cancelled successfully."
        });
        toastEvent.fire();
        component.set('v.resourceOrderId', null);
        component.set('v.resourceOrderItems', []);
        component.set('v.componentTitle', 'Log Shared Digital Resources');
        component.set('v.loading', false);
      }
    });
    $A.enqueueAction(_deleteResourceOrder);
  }
})