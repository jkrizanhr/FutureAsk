({
  fetchDataHelper: function (component, recordId) {
    component.set('v.loading', true);
    return new Promise($A.getCallback(function (resolve, reject) {
      var _fetchData = component.get("c.fetchData");
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
})