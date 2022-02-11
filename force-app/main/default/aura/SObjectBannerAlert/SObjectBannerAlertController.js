({
  doInit : function(component, event, helper) {
    var _getAlertsForSObject = component.get("c.getAlertsForSObject");
    _getAlertsForSObject.setParams({
      recordId : component.get("v.recordId")
    });

    _getAlertsForSObject.setCallback(this, function(res) {
      if(res.getState() === "ERROR") {
        const errorMessage = res.getError()[0].message;
        console.log("Error getting alerts", errorMessage);
        component.find('notifLib').showToast({
          "title": "Error",
          "variant": "error",
          "message": "Banner Alerts - " + ((errorMessage.length > 80) ? errorMessage.substr(0, 79) + '...' : errorMessage)
        });
      } else {
        var results = res.getReturnValue();
        component.set("v.alertGroups", results);
      }
    });
    $A.enqueueAction(_getAlertsForSObject);
  }
})