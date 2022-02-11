({
    doInit : function(component, event, helper) {
        var action = component.get('c.getProfilePicture');
        action.setParams({
            recordId : component.get("v.recordId"),
            fieldName : component.get("v.fieldName"),
            sObjectName : component.get("v.sObjectName")
        })
        action.setCallback(this, (result) => {
            if (result.getState() === 'ERROR') {
                console.log('Error getting profile id: ', result.getError());
            } else {
                var contentId = result.getReturnValue();
                console.log(contentId);
                if(contentId) {
                    var url = "/sfc/servlet.shepherd/document/download/" + contentId;
                    component.set("v.imageUrl", url);
                    component.set("v.fileId", contentId);
                }
            }
        });
        $A.enqueueAction(action);
    },

    handleUploadFinished: function (component, event, helper) {
        var uploadedFiles = event.getParam("files");
        if(uploadedFiles.length) {

            var action = component.get('c.saveProfileId');
            action.setParams({
                recordId : component.get("v.recordId"),
                contentId : uploadedFiles[0].documentId,
                fieldName : component.get("v.fieldName"),
                sObjectName : component.get("v.sObjectName")
            });

            action.setCallback(this, (result) => {
                if (result.getState() === 'ERROR') {
                    console.log('Error saving profile id: ', result.getError());
                } else {
                    var url = "/sfc/servlet.shepherd/document/download/" + uploadedFiles[0].documentId;
                    component.set("v.imageUrl", url);
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