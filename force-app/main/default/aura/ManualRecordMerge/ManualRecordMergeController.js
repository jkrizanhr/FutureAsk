({
    doInit : function(component, event, helper) {
        var rows = [
            {recordId:""},
            {recordId:""}
        ];
        component.set("v.recordsToMerge", rows);
    },
    saveDuplicates : function(component, event, helper) {
        var recordsToMerge = component.get("v.recordsToMerge");

        if(recordsToMerge && recordsToMerge.length >= 2) {
            var recIds = [];
            var nothingSet = false;
            for(var i = 0; i < recordsToMerge.length; i++) {
                if(!recordsToMerge[i].recordId) {
                    nothingSet = true;
                } else if(recIds.indexOf(recordsToMerge[i].recordId) === -1) {
                    recIds.push(recordsToMerge[i].recordId);
                }
            }

            if(!nothingSet && recIds && recIds.length >= 2) {
                var _createDuplicateSetWithItems = component.get("c.createDuplicateSetWithItems");
                _createDuplicateSetWithItems.setParams({
                    recordsToMerge : recIds
                });
                _createDuplicateSetWithItems.setCallback(this, function(res) {
                    if(res.getState() === "ERROR") {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!",
                            "message": "Error flagging as duplicates.",
                            "type": "error"
                        });
                        toastEvent.fire();
                    } else {
                        component.set("v.successScreen", true);
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                        "recordId": recIds[0],
                        "slideDevName": "detail"
                        });
                        navEvt.fire();
                    }
                });
                $A.enqueueAction(_createDuplicateSetWithItems);
            } else if(nothingSet) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Validation Error",
                    "message": "At least 2 records must be provided in order to merge.",
                    "type": "error"
                });
                toastEvent.fire();
                
            } else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Validation Error",
                    "message": "You provided the same record multiple times so there is nothing to merge.",
                    "type": "error"
                });
                toastEvent.fire();
            }
        }
    },
    addRow : function(component, event, helper) {
        var rows = component.get("v.recordsToMerge");
        rows.push({recordId:""});
        component.set("v.recordsToMerge", rows);
    },
    objectTypeChange : function(component, event, helper) {
        var rows = [
            {recordId:""},
            {recordId:""}
        ];
        component.set("v.recordsToMerge", rows);
    },
    resetForm : function(component, event, helper) {
        component.set("v.objectType", "Account");
        var rows = [
            {recordId:""},
            {recordId:""}
        ];
        component.set("v.recordsToMerge", rows);
        component.set("v.successScreen", false);
    }
})