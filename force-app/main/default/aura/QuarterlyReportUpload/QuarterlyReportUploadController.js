({
  doInit : function(component, event, helper) {
    var action = component.get('c.getReports');
    action.setParams({
      recordId : component.get("v.recordId")
    })
    action.setCallback(this, (result) => {
      if (result.getState() === 'ERROR') {
        console.log('Error getting file id: ', result.getError());
      } else {
        var contentId = result.getReturnValue();
        console.log(contentId);
        if(contentId) {
          var url = "/sfc/servlet.shepherd/document/download/" + contentId;
          component.set("v.fileURL", url);
          component.set("v.fileId", contentId);
        }
      }
    });
    $A.enqueueAction(action);
  },

  handleUploadFinished: function (component, event, helper) {
    debugger;
    var uploadedFiles = event.getParam("files");
    if(uploadedFiles.length) {

      var action = component.get('c.saveFileId');
      action.setParams({
        recordId : component.get("v.recordId"),
        contentId : uploadedFiles[0].documentId
      });

      action.setCallback(this, (result) => {
        if (result.getState() === 'ERROR') {
          console.log('Error saving file id: ', result.getError());
        } else {
          var url = "/sfc/servlet.shepherd/document/download/" + uploadedFiles[0].documentId;
          component.set("v.fileURL", url);
          component.set("v.fileId", uploadedFiles[0].documentId);
          $A.get('e.force:refreshView').fire();
          var toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams({
            "title": "Success!",
            "message": "Upload Complete"
          });
          toastEvent.fire();
        }
      });

      $A.enqueueAction(action);
    }
  },
    
  previewFile : function(component, event, helper) {
    var contentId = component.get("v.fileId");
    $A.get('e.lightning:openFiles').fire({
      recordIds: [contentId]
    });
  }
})