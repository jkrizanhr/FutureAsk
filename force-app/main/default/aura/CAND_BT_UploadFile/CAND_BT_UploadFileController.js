({
  handleUploadFinished: function (component, event) {
    var uploadedFiles = event.getParam("files");
    var filesList = component.get("v.filesList");

    for (var i=0; i < uploadedFiles.length; i++){
      var temp = uploadedFiles[i].name.substring(uploadedFiles[0].name.lastIndexOf('.') + 1);
      var type = null;
      
      switch (temp){
        case 'ppt':
          type = 'ppt';
          break;
        case 'docx':
          type = 'word';
          break;
        case 'jpg':
          type = 'image';
          break;
        case 'jpeg':
          type = 'image';
          break;
        case 'xls':
          type = 'excel';
          break;
        case 'pdf':
          type = 'pdf';
          break;
        default:
          type = 'attachment';
      }
      
      filesList.push({
        name: uploadedFiles[0].name,
        type: type
      });
    }
    component.set("v.filesList", filesList);
  },

  closeModal : function(component, event, helper){
    var files = component.get("v.filesList").length;
    
    if (files != null && files != 0){
      var message = 'Files Uploaded: ' + files;
      var toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
          "title": "Success!",
          "message": message,
          "duration": 500,
          "type" : "success"
      });
      toastEvent.fire();
    }

    var evt = component.getEvent('closeWindow');
    component.set("v.filesList", []);
    evt.fire();
  }
})