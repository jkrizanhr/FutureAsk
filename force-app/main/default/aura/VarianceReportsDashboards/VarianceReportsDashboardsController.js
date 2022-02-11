({
  doInit: function(component, event){      
    var _fetchData = component.get("c.fetchData");

    _fetchData.setCallback(this, function(results) {
      _fetchData.setParams({
        searchKey : null
      });
      if(results.getState() === "SUCCESS") {
        component.set('v.dashboards', results.getReturnValue());
        component.set('v.searchKey', null);
        component.set('v.loading', false);
      }
    });
    $A.enqueueAction(_fetchData);
  },
  searchKeyChange: function (component, event, helper) {
    var isKey = event.keyCode === 13 || event.keyCode === 8;
    var searchKey = component.get('v.searchKey');
    
    if (isKey || searchKey.length > 2){
      var _fetchData = component.get("c.fetchData");
      _fetchData.setParams({
        searchKey : searchKey
      });
      _fetchData.setCallback(this, function(results) {
        if(results.getState() === "SUCCESS") {
          component.set('v.dashboards', results.getReturnValue());
        }
      });
    $A.enqueueAction(_fetchData);
    } 
  },
  editRecord : function(component, event){
    var editRecordEvent = $A.get("e.force:editRecord");
    editRecordEvent.setParams({
      "recordId": event.getSource().get("v.value")
    });
    editRecordEvent.fire();
  },
  createRecord : function(component, event){
    var createRecordEvent = $A.get("e.force:createRecord");
    createRecordEvent.setParams({
        "entityApiName": "Embedded_Dashboard__c"
    });
    createRecordEvent.fire();
  },
  openNewWindow : function(component, event){        
    if (event.getSource().get("v.value") != null){
      window.open(event.getSource().get("v.value"),"_blank");
    }
  }
})