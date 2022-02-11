({
  fetchCurrentSessionTypeHelper : function(component) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var _fetchData = component.get("c.fetchCurrentSessionType");

      _fetchData.setCallback(this, function(res) {
        if(res.getState() === "ERROR") {
          reject(res.getError());
        } else {
          resolve(res.getReturnValue());
        }
      });
      $A.enqueueAction(_fetchData);
    }));
  }
})