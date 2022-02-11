({
  doInit: function (component, event, helper) {
    console.log('BatchModalController.doInit');
    var action = component.get('c.getTodaysDate');

    action.setCallback(this, (result) => {
      if (result.getState() === 'SUCCESS') {
        component.set('v.batchDate', result.getReturnValue());
      } else {
        console.log(result.getState());
      }
    });

    $A.enqueueAction(action);

    var getUserAction = component.get('c.getUserId');
    getUserAction.setCallback(this, function (result) {
      if (result.getState() === 'SUCCESS') {
        var user = result.getReturnValue();
        component.set('v.Keyer', user.Id);
      } else {
        console.log('Fetch User Id', console.log(result.getState()));
      }
    });
    $A.enqueueAction(getUserAction);
  },

  toggleDisplay: function (component, event, helper) {
    var cmpTarget = component.find('Modalbox1');
    var cmpBack = component.find('Modalbackdrop');

    component.set('v.display', false);
    component.set('v.display', true);

    if ($A.util.hasClass(cmpTarget, 'slds-fade-in-open')) {
      $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
      component.set('v.batchName', '');
    } else {
      $A.util.addClass(cmpTarget, 'slds-fade-in-open');
      var recordId = component.get('v.recordId');
      if (recordId) {
        //this method will get the Batch Record information, despite the name
        var action = component.get('c.getNewParent');
        action.setParams({
          parentRecordId: recordId
        });

        action.setCallback(this, (result) => {
          if (result.getState() === 'SUCCESS') {
            var batchRecord = result.getReturnValue();
            component.set('v.batchName', batchRecord.Name);
          } else {
            alert('Uh-oh! Something went wrong!')
          }
        });

        $A.enqueueAction(action);
      }
    }

    $A.util.hasClass(cmpBack, 'slds-backdrop--open') ?
      $A.util.removeClass(cmpBack, 'slds-backdrop--open') :
      $A.util.addClass(cmpBack, 'slds-backdrop--open');

    var bn = component.get('v.recordId');
    component.find('field').forEach(function (f) {
      if ((f.get('v.fieldName') != 'Keyer__c' || (f.get('v.fieldName') == 'Keyer__c' && bn != '')) && (f.get('v.fieldName') != 'Date__c' || (f.get('v.fieldName') == 'Date__c' && bn != ''))) {
        f.reset();
      }
    });
  },

  saveBatchCreation: function (component, event, helper) {
    var closeBatchCreation = component.get('c.toggleDisplay');
    closeBatchCreation.setParams({
      component: component,
      event: event,
      helper: helper
    });
    $A.enqueueAction(closeBatchCreation);

    if (component.get('v.recordId') == '') {
      var params = JSON.parse(JSON.stringify((event.getParams())));

      var row = {
        Id: params.response.id,
        // Control_Batch_Size__c: params.response.fields.Control_Batch_Size__c.value,
        // Control_Batch_Total__c: params.response.fields.Control_Batch_Total__c.value,
        CreatedDate: params.response.fields.CreatedDate.value,
        Name: params.response.fields.Name.value,
        // Records_Included_In_Batch__c: params.response.fields.Records_Included_in_Batch__c.value,
        // Status__c: params.response.fields.Status__c.value,
        // Date__c: params.response.fields.Date__c.value,
        // Total_Included_in_Batch__c: params.response.fields.Total_Included_in_Batch__c.value
      }

      var navEvent = $A.get('e.force:navigateToComponent');
      navEvent.setParams({
        componentDef: 'c:CAND_BT_Form',
        componentAttributes: {
          btSettings: component.get('v.btSettings'),
          sObjectName: component.get('v.btSettings').form.objectLabel,
          sObjectAPIName: component.get('v.btSettings').form.objectAPIName,
          parentRecord: row
        }
      });
      navEvent.fire();
    } else {
      $A.get('e.force:refreshView').fire();
    }
  },

  setUserId: function (component) {
    var getUserAction = component.get('c.getUserId');
    getUserAction.setCallback(this, function (result) {
      if (result.getState() === 'SUCCESS') {
        console.log('userId', result.getReturnValue());
        var user = result.getReturnValue();
        var record = JSON.parse(JSON.stringify(component.get('v.record')));
        record.Keyer = user;
        record.Keyer__c = user.Id;
        component.set('v.record', record);
      } else {
        console.log('Fetch User Id', console.log(result.getState()));
        component.find('notifLib').showToast({
          title: 'Uh-oh!',
          variant: 'error',
          message: 'Something went wrong when adding the user\'s Id'
        });
      }
    });
    $A.enqueueAction(getUserAction);

  },
})