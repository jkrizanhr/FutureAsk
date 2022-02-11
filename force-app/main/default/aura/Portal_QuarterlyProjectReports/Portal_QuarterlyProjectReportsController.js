({
  init: function (component, event, helper) {
    helper.fetchDataHelper(component)
      .then($A.getCallback(function(results) {
        component.set('v.reports', results);
      }));
  },
  openReport : function(component, event, helper){
    var url = event.getSource().get('v.value');
    window.open(url);
    // window.open('/sfc/servlet.shepherd/document/download/' + fileId + '?operationContext=S1');
  }
})