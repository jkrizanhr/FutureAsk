({
  doInit : function(component, event, helper) {
    var _getOneClickUpProject = component.get("c.getOneClickUpProject");
      _getOneClickUpProject.setParams({
        recordId : component.get('v.recordId')
      });

      _getOneClickUpProject.setCallback(this, function(res) {
        if(res.getState() === "ERROR") {
          console.log(res.getError());
        } else {
          res.getReturnValue();
        }
      });
      $A.enqueueAction(_getOneClickUpProject);
  },

})