({
  doInit: function (component, event, helper) {
    console.log('\nCAND_BT_Form.doInit');

    var btSettings = component.get('v.btSettings');

    if (!btSettings || !btSettings.form) {
      component.find('notifLib').showNotice({
        header: 'Error!',
        variant: 'error',
        message: 'Error: Custom Metadata Type Configuartion Required!'
      });
      return;
    }

    helper.getRecordTypeIds(component);
    var parentRecord = component.get('v.parentRecord');
    var getParentAction = component.get('c.getNewParent');
    getParentAction.setParams({
      parentRecordId: parentRecord.Id
    });
    getParentAction.setCallback(this, (result) => {
      if (result.getState() === 'SUCCESS') {
        component.set('v.parentRecord', result.getReturnValue());
        var parentRecord = result.getReturnValue();
        helper._initializeRecord(component);
        var record = JSON.parse(JSON.stringify(component.get('v.record')));
        component.set('v.record', record);
        component.set('v.showRelatedOpportunityList', true);
        if (parentRecord.Opportunity_Type__c === 'Indirect Donor or Estate Gift') {
          component.set('v.showSinglePayorInputBox', true);
        }
      } else {
        component.find('notifLib').showNotice({
          header: 'Error!',
          variant: 'error',
          message: 'Error: Parent Record could not be found!'
        });
        return;
      }
    });
    $A.enqueueAction(getParentAction);
  },

  navigateToBatches: function (component, event, helper) {
    console.log('\nCAND_BT_Form.NaviagteTobatches');
    var navEvent = $A.get('e.force:navigateToComponent');
    navEvent.setParams({
      componentDef: 'c:CAND_BT'
    });
    navEvent.fire();
  },

  handleLookupEvent: function (component, event, helper) {
    console.log('\nCAND_BT_FormController.handleLookupEvent');

    var object = JSON.parse(JSON.stringify(event.getParam('object')));
    var objectAPIName = event.getParam('objectAPIName');
    var objectIndex = event.getParam('objectIndex');
    var record = JSON.parse(JSON.stringify(component.get('v.record')));
    let receiptType = 'Print';

    if (objectAPIName === 'Account') {
      // figure out the proper receipt type from the contact or the account. otherwise leave as email
      if (object.npe01__One2OneContact__c != null && object.npe01__One2OneContact__r.Receipt_Type__c != null){
        receiptType = object.npe01__One2OneContact__r.Receipt_Type__c;
      } else if (object.Receipt_Type__c != null){
        receiptType = object.Receipt_Type__c;
      }

      var type = event.getSource().get("v.objectLabel");
      if (type == 'Payor or Estate Account') {
        record.Paid_By__c = object ? object.Id : null;
      } else {
        record.AccountId = object ? object.Id : null;
        record.Receipt_Type__c = receiptType;
        record.Language_Preference__c = object.Language_Preference__c != null ? object.Language_Preference__c : 'English';
        record.OngoingCheckDonor = object.Is_Ongoing_Check_Donor__c;
        if (object && !record.npsp__Primary_Contact__c) {
          record.npsp__Primary_Contact__c = object.npe01__One2OneContact__c;
          record.Contact = object.npe01__One2OneContact__r;
        }
      }
    } else if (objectAPIName === 'Contact') {
      // If lookup item is a Contact
      if (object && object.Id.substring(0,3) === '003'){
        // figure out the proper receipt type from the contact or the account. otherwise leave as email
        if (object.Receipt_Type__c != null){
          receiptType = object.Receipt_Type__c;
        } else if (object.Account != null && object.Account.Receipt_Type__c != null){
          receiptType = object.Account.Receipt_Type__c;
        }
  
        record.npsp__Primary_Contact__c = object ? object.Id : null;
        record.Receipt_Type__c = receiptType;
        
        if (object && !record.AccountId) {
          record.AccountId = object.AccountId;
          record.Account = object.Account;
        }
      } 
      // If lookup item is a Lead
      else if (object && object.Id.substring(0,3) === '00Q') {
        objectAPIName = 'Lead';
        record.npsp__Primary_Contact__c = object ? object.Id : null;
        component.set('v.isLead', true);
      } 
      if (objectAPIName != 'Lead'){
        component.set('v.isLead', false);
      }
    } else if (objectAPIName === 'Campaign') {
      var fundId = null;
      var fundName = null;
      var glAcctId = null;
      var glAcctName = null;
      if (object.Batch_Tool_Purpose_Code_Default__c != null){
        fundId = object.Batch_Tool_Purpose_Code_Default__r.Id;
        fundName = object.Batch_Tool_Purpose_Code_Default__r.Name;
        if (object.Batch_Tool_Purpose_Code_Default__r.Default_Fund_GL_Account__c != null){
          glAcctId = object.Batch_Tool_Purpose_Code_Default__r.Default_Fund_GL_Account__r.Id;
          glAcctName = object.Batch_Tool_Purpose_Code_Default__r.Default_Fund_GL_Account__r.Name;
        }
      }

      if (objectIndex == null){
        record.CampaignId = object ? object.Id : null;
      } else {
        var recordSplitList = JSON.parse(JSON.stringify(component.get('v.recordSplitList')));
        recordSplitList[objectIndex].Campaign = object ? object : null;
        recordSplitList[objectIndex].Tax_Deductible__c = true;
        if (fundId != null && (
          recordSplitList[objectIndex].Fund == "" || 
          recordSplitList[objectIndex].Fund == null || 
          recordSplitList[objectIndex].Fund == undefined)
        ){
          recordSplitList[objectIndex].Fund = {Id: fundId, Name: fundName}
          recordSplitList[objectIndex].glAcct = glAcctId != null 
            ? {Id: glAcctId, Name: glAcctName}
            : null;
        } 
        component.set('v.recordSplitList', recordSplitList);
      }

    } else if (objectAPIName === 'npsp__General_Accounting_Unit__c' && objectIndex != null) {
      var recordSplitList = JSON.parse(JSON.stringify(component.get('v.recordSplitList')));
      // Check that the record already has this split
      var duplicateFound = false;
      for (var i in recordSplitList) {
        if (object && recordSplitList[i].Fund.Id === object.Id && i != recordSplitList.length - 1) {
          component.find('notifLib').showToast({
            title: 'Warning!',
            variant: 'warning',
            message: 'This record has already been selected. Removing row...'
          });
          object = null;
          duplicateFound = true;
        }
      }
      if (!duplicateFound) {
        if (!object) {
          recordSplitList[objectIndex].Original_Amount__c = 0;
        }
        var glAcctId = null;
        var glAcctName = null; 
        if (object.Default_Fund_GL_Account__c != null){
          glAcctId = object.Default_Fund_GL_Account__r.Id;
          glAcctName = object.Default_Fund_GL_Account__r.Name;
        }
        recordSplitList[objectIndex].glAcct = glAcctId != null  
          ? {Id: glAcctId, Name: glAcctName}
          : null;
      } else {
        recordSplitList.splice(objectIndex, 1);
      }
      component.set('v.recordSplitList', recordSplitList);
    } else if (objectAPIName === 'Opportunity') {
      var matchingGiftList = JSON.parse(JSON.stringify(component.get('v.matchingGiftList')));
      var duplicateFound = false;
      for (var i in matchingGiftList) {
        if (i != objectIndex && object && matchingGiftList[i].Gift && matchingGiftList[i].Gift.Id === object.Id && i != matchingGiftList.length - 1) {
          component.find('notifLib').showToast({
            title: 'Warning!',
            variant: 'warning',
            message: 'This record has already been selected. Removing row...'
          });
          object = null;
          duplicateFound = true;
        }
      }
      if (duplicateFound) {
        matchingGiftList.splice(objectIndex, 1);
      } else {
        if (object && object.npsp__Matching_Gift__c) {
          component.find('notifLib').showToast({
            title: 'Warning!',
            variant: 'warning',
            message: 'This record has a matching gift already. Removing row...'
          });
          object = null;
          matchingGiftList.splice(objectIndex, 1);
        }
      }
      component.set('v.matchingGiftList', matchingGiftList);
    }

    component.set('v.record', record);
    console.log(component.get('v.recordSplitList'));
    
    var isLead = component.get('v.isLead');

    if (!record.AccountId && !isLead) {
      component.set('v.shouldDisableSplits', true);
    } else {
      component.set('v.shouldDisableSplits', false);
    }
  },

  handleSelectFutureGift : function(component, event, helper) {
    let futureGift = event.getParam('futureGift');
    var record = JSON.parse(JSON.stringify(component.get('v.record')));
    record.Future_Gift__c = futureGift.Id;
    record.FutureGift = futureGift;
    component.set('v.record', record);

    var campaignId = null;
    var campaignName = null;
    if (component.get('v.campaignIsLocked') == true){
      campaignId = component.get('v.recordSplitList')[0].Campaign != null
        ? component.get('v.recordSplitList')[0].Campaign.Id
        : null;
      campaignName = component.get('v.recordSplitList')[0].Campaign != null
        ? component.get('v.recordSplitList')[0].Campaign.Name
        : null;
    }

    // Delete existing GAU allocations and replace with FA allocations
    var recordSplitList = component.get('v.recordSplitList');
    var deleteRecordSplitList = component.get('v.deleteRecordSplitList');
    for (var i = 0; i < recordSplitList.length; i++){
      if (recordSplitList[i].Id) {
        deleteRecordSplitList.push({
          Id: recordSplitList[i].Id
        });
      }
    }
    component.set('v.deleteRecordSplitList', deleteRecordSplitList);
    var recordSplitList = [];

    if (futureGift.Future_Gift_Allocations__r) {
      var index = recordSplitList.length; 

      for (var i = 0; i < futureGift.Future_Gift_Allocations__r.length; i++) {
        var allocation = futureGift.Future_Gift_Allocations__r[i];
        if (allocation.Campaign__c != null){
          campaignId = allocation.Campaign__r.Id;
          campaignName = allocation.Campaign__r.Name;
        }
        recordSplitList.push({
          Id: null,
          Original_Amount__c: allocation.Allocation_Amount__c,
          Original_Currency__c: futureGift.Original_Currency__c,
          index: index + i,
          Tax_Deductible__c: allocation.Tax_Deductible__c,
          Fund: {
            Id: allocation.General_Accounting_Unit__r.Id,
            Name: allocation.General_Accounting_Unit__r.Name
          },
          glAcct: {
            Id: allocation.General_Accounting_Unit__r.Default_Fund_GL_Account__r.Id,
            Name: allocation.General_Accounting_Unit__r.Default_Fund_GL_Account__r.Name
          },
          Description__c: allocation.Description__c ? allocation.Description__c : null,
          Campaign: campaignId != null
            ? {Id: campaignId, Name: campaignName}
            : undefined
        });
      }
    } else {
      recordSplitList.push({
        Id: null,
        Original_Amount__c: record.Original_Amount__c,
        Original_Currency__c: futureGift.Original_Currency__c,
        index: 0,
        Description__c: null,
        Tax_Deductible__c: true,
        Campaign: {
          Id: campaignId,
          Name: campaignName
        }
      });
    }
    component.set('v.recordSplitList', recordSplitList);
    component.set('v.shouldDisableSplits', false);
  },

  updateAllocationAmount: function (component, event, helper) {
    console.log('\nCAND_BT_Form.updateAllocationAmount');
    var recordSplitList = JSON.parse(JSON.stringify(component.get('v.recordSplitList')));
    var record = JSON.parse(JSON.stringify(component.get('v.record')));

    if (record.Original_Amount__c != null && record.Original_Amount__c != '' && recordSplitList[0].Original_Amount__c == '') {
      recordSplitList[0].Original_Amount__c = record.Original_Amount__c;
      recordSplitList[0].Tax_Deductible__c = true;
      component.set('v.recordSplitList', recordSplitList);
    }
  },

  onclickToggleCloseDateLock: function (component, event, helper) {
    component.set('v.closeDateIsLocked', !component.get('v.closeDateIsLocked'));
  },

  onclickTogglePaymentMethodLock: function (component, event, helper) {
    component.set('v.paymentMethodIsLocked', !component.get('v.paymentMethodIsLocked'));
    var record = JSON.parse(JSON.stringify(component.get('v.record')));
    var parentRecord = JSON.parse(JSON.stringify(component.get('v.parentRecord')));
    if (record && record.Payment_Method__c && record.Payment_Method__c == 'Check' && parentRecord.Opportunity_Type__c === 'Indirect Donor or Estate Gift') {
      component.set('v.checkIsDisabled', !component.get('v.checkIsDisabled'));
    }
  },

  onclickToggleSinglePayorLock: function (component, event, helper) {
    component.set('v.singlePayorIsLocked', !component.get('v.singlePayorIsLocked'));
  },

  onclickToggleGivingMethodLock: function (component, event, helper) {
    component.set('v.givingMethodIsLocked', !component.get('v.givingMethodIsLocked'));
  },

  onclickToggleGAULock: function (component, event, helper) {
    component.set('v.gauIsLocked', !component.get('v.gauIsLocked'));
  },

  onclickToggleCampaignLock: function(component, event, helper){
    component.set('v.campaignIsLocked', !component.get('v.campaignIsLocked'));
  },

  onChangePaymentMethod: function (component, event, helper) {
    console.log('\nCAND_BT_Form.onChangePaymentMethod');
    if (component.get('v.record.Payment_Method__c') !== 'Check') {
      component.set('v.record.Payment_Reference_Number__c', '');
    }
  },

  linkToReport: function (component, event, helper) {
    var action = component.get('c.getReconciliationReportId');
    action.setCallback(this, (result) => {
      if (result.getState() == 'SUCCESS') {
        var parentRecord = component.get('v.parentRecord');
        component.find("navService").navigate({
          type: "standard__webPage",
          attributes: {
            url: '/lightning/r/Report/' + result.getReturnValue() + '/view?fv0=' + parentRecord.Id
          }
        });
      } else {
        component.find('notifLib').showNotice({
          header: 'Error!',
          variant: 'error',
          message: 'Error: Uh-oh! There is an issue linking out to the Report.'
        });
      }
    });

    $A.enqueueAction(action);
  },

  
  linkToGauReport: function (component, event, helper) {
    var action = component.get('c.getGauReportId');
    action.setCallback(this, (result) => {
      if (result.getState() == 'SUCCESS') {
        var parentRecord = component.get('v.parentRecord');
        window.open(location.href.substring(0, location.href.indexOf('/', 14)) 
          + '/lightning/r/Report/' + result.getReturnValue() + '/view?fv0=' + parentRecord.Name);
      } else {
        component.find('notifLib').showNotice({
          header: 'Error!',
          variant: 'error',
          message: 'Error: Uh-oh! There is an issue linking out to the Report.'
        });
      }
    });

    $A.enqueueAction(action);
  },

  showDonorSearchModal: function (component, event, helper) {
    var modal = component.find("donorSearchModal")
    modal.toggleDisplay();
  },

  showReceiptSearchModal: function (component, event, helper) {
    var modal = component.find("receiptSearchModal")
    modal.toggleDisplay();
  },

  onClickAddSplit: function (component, event, helper) {
    helper._manageRecordSplitRows(component);
  },

  onClickRemoveSplit: function (component, event, helper) {
    console.log("CAND_BT_FormController.OnClickRemoveSplit")

    var index = event.getSource().get('v.value');
    var recordSplitList = component.get('v.recordSplitList');
    var deleteRecordSplitList = component.get('v.deleteRecordSplitList');
    if (recordSplitList[index].Id) {
      deleteRecordSplitList.push({
        Id: recordSplitList[index].Id
      });
      component.set('v.deleteRecordSplitList', deleteRecordSplitList);
    }

    recordSplitList.splice(index, 1);
    component.set('v.recordSplitList', recordSplitList);
  },

  onClickAddGift: function (component, event, helper) {
    var matchingGiftList = component.get('v.matchingGiftList');
    matchingGiftList.push({});
    component.set('v.matchingGiftList', matchingGiftList);
  },

  onClickRemoveGift: function (component, event, helper) {
    console.log("CAND_BT_FormController.OnClickRemoveGift")

    var index = event.getSource().get('v.value');
    var matchingGiftList = component.get('v.matchingGiftList');
    var deleteMatchingGiftList = component.get('v.deleteMatchingGiftList');
    if (matchingGiftList[index].Gift && matchingGiftList[index].Gift.npsp__Matching_Gift__c) {
      deleteMatchingGiftList.push({
        Id: matchingGiftList[index].Gift.Id
      });
      component.set('v.deleteMatchingGiftList', deleteMatchingGiftList);
    }

    matchingGiftList.splice(index, 1);
    component.set('v.matchingGiftList', matchingGiftList);
  },

  setAllocationsToAnonymous: function (component, event, helper) {
    console.log('CAND_BT_FormController.setAllocationsToAnonymous');
    var splitList = component.get('v.recordSplitList');
    var isAnonymous = component.get('v.record.Is_Anonymous__c');
    for (var i = 0; i < splitList.length; i++) {
      splitList[i].Anonymous__c = isAnonymous;
    }
    component.set('v.recordSplitList', splitList);
  },

  handleFilloutForm: function (component, event, helper) {
    console.log('\nCAND_BT_Form.handleFilloutForm');
    var oppId = event.getParam("opportunity");

    component.set('v.editingOpportunity', true);
    component.set('v.isLead', false);

    var action = component.get('c.getOppRecord');
    action.setParams({
      oppId: oppId
    });

    action.setCallback(this, (result) => {
      if (result.getState() === "SUCCESS") {
        var opp = result.getReturnValue();
        helper.filloutOppForm(component, opp[0]);
        component.set('v.campaignIsLocked', false);
        component.set('v.gauIsLocked', false);
      }
    });

    $A.enqueueAction(action);
  },

  handleFilloutAllocations: function (component, event, helper) {
    console.log('\nCAND_BT_Form.handleFilloutAllocations');
    var oppId = event.getParam("opportunity");
    var parentRecord = JSON.parse(JSON.stringify(component.get('v.parentRecord')));

    var action = component.get('c.getOppRecord');
    action.setParams({
      oppId: oppId
    });

    action.setCallback(this, (result) => {
      if (result.getState() === "SUCCESS") {
        var opp = result.getReturnValue()[0];
        if (parentRecord.Type__c !== 'Adjustments') {
          helper.filloutOppForm(component, opp);
          var record = JSON.parse(JSON.stringify(component.get('v.record')));
          record.Id = null;
          var recordSplitList = component.get('v.recordSplitList');
          for (var i = 0; i < recordSplitList.length; i++) {
            recordSplitList[i].Id = null;
          }
          record.CloseDate = parentRecord.Date__c;
          component.set('v.record', record);
        } else {
          component.set('v.isAdjustment', true);
          helper.createReversal(component, opp);
          var record = JSON.parse(JSON.stringify(component.get('v.record')));
          component.set('v.record', record);
        }
      }
    });

    $A.enqueueAction(action);

    component.set('v.shouldDisableSplits', false);
  },

  onClickClearForm: function (component, event, helper) {
    helper._initializeRecord(component);
  },

  // This function contains a lot of org-specific actions
  // that are required before submitting the form data.
  onSaveClicked: function (component, event, helper) {
    console.log('\nCAND_BT_FormController.onSaveClicked');

    var valid = true;
    var btSettings = JSON.parse(JSON.stringify(component.get('v.btSettings')));
    var isLead = component.get('v.isLead');

    if (!btSettings || !btSettings.form) {
      component.find('notifLib').showNotice({
        header: 'Error!',
        variant: 'error',
        message: 'Error saving record: Custom Metadata Type Configuration Required!'
      });
      valid = false;
      return;
    }

    component.find('notifLib').showToast({
      message: 'Saving...'
    });

    var requiredFields = btSettings.form.requiredFields;
    var parentRecord = component.get('v.parentRecord');

    if (parentRecord.Opportunity_Type__c === 'Indirect Donor or Estate Gift') {
      requiredFields.push('Paid_by__c');
    }
    if (parentRecord.Opportunity_Type__c === 'In-Kind Gift') {
      requiredFields.push('npsp__Fair_Market_Value__c');
      requiredFields.push('npsp__In_Kind_Type__c');
    }

    var record = JSON.parse(JSON.stringify(component.get('v.record')));
    var recordSplitList = JSON.parse(JSON.stringify(component.get('v.recordSplitList')));

    var recordList = [];
    var missingFields = {}; // used to avoid duplicate toasts
    var sum = 0;
    var totalAmount = record.Original_Amount__c;

    if (parentRecord.Opportunity_Type__c === 'Indirect Donor or Estate Gift' && record.Paid_By__r) {
      record.Paid_By__c = record.Paid_By__r.Id;
    }

    // Ensure that the required fields are populated
    for (let r in requiredFields) {
      if (!record[requiredFields[r]] && !missingFields[requiredFields[r]]) {
        var field = '';
        switch (requiredFields[r]) {
          case 'AccountId':
            field = 'Account'
            break;
          case 'StageName':
            field = 'Stage Name'
            break;
          case 'CloseDate':
            field = 'Close Date'
            break;
          case 'Name':
            field = 'Name'
            break;
          case 'Amount':
            field = 'Total Gift Amount'
            break;
          case 'Cash_Batch__c':
            field = 'Batch Record'
            break;
          case 'Paid_By__c':
            field = 'Payor or Estate Account'
            break;
          case 'Keyer__c':
            field = 'Keyer'
            break;
          case 'Payment_Method__c':
            field = 'Choose Payment Method'
            break;
          case 'npsp__Fair_Market_Value__c':
            field = 'Fair Market Value'
            break;
          case 'npsp__In_Kind_Type__c':
            field = 'In-Kind Type'
            break;
          case 'Donation_Source__c':
            field = 'Donation Source'
            break;
        }
        if (field != ''){
          if (field != 'Account' && !isLead){
            component.find('notifLib').showToast({
              title: 'Error!',
              variant: 'error',
              message: 'Missing required field: ' + field
            });
            valid = false;
            missingFields[requiredFields[r]] = true;
          }
        }
      }
    }

    if (component.find("Payment_Method__c").get("v.value") == 'Select an Option...') {
      valid = false;
      component.find('notifLib').showToast({
        title: 'Error!',
        variant: 'error',
        message: 'Missing required field: Payment Method'
      });
    }

    if (!valid) {
      // Missing required fields so there's no need to continue
      return;
    }

    // Clean up some data
    if (record.FutureGift) {
      record.Future_Gift__c = record.FutureGift.Id;
    }
    if (record.DoNotAcknowledge && record.DoNotAcknowledge == true) {
      record.npsp__Acknowledgment_Status__c = "Do Not Acknowledge";
    }
    if (parentRecord.Opportunity_Type__c === 'Matching Gift') {
      record.RecordTypeId = component.get('v.matchingGiftTypeId');
    } else if (parentRecord.Opportunity_Type__c === 'In-Kind Gift') {
      record.RecordTypeId = component.get('v.inKindGiftTypeId');
    }

    delete record.DoNotAcknowledge;
    delete record.FutureGift;
    delete record.Contact;
    delete record.Account;
    delete record.Campaign;
    delete record.Paid_By__r;
    delete record.Keyer;

    // Handle Split Logic
    var allocationList = [];
    var updateAllocationList = [];
    var maxLength = component.get('v.maxReceiptLength');
    for (let i in recordSplitList) {
      var split = recordSplitList[i];
      if (!split.Fund) {
        component.find('notifLib').showToast({
          title: 'Error!',
          variant: 'error',
          message: 'Missing required field: General Accounting Unit'
        });
        valid = false;
        break;
      }
      
      if (!split.Campaign) {
        component.find('notifLib').showToast({
          title: 'Error!',
          variant: 'error',
          message: 'Missing required field: Campaign'
        });
        valid = false;
        break;
      }
      
      if (!split.glAcct) {
        component.find('notifLib').showToast({
          title: 'Error!',
          variant: 'error',
          message: 'Missing required field: Fund GL Account'
        });
        valid = false;
        break;
      }
      
      if (split.Description__c && split.Description__c.length > maxLength) {
        component.find('notifLib').showToast({
          title: 'Error!',
          variant: 'error',
          message: split.Fund.Name + "'s Description is longer than " + maxLength + ' characters.'
        });
        valid = false;
        continue;
      }

      if (!split.Fund.Id || !split.Original_Amount__c) {
        recordSplitList.splice(i, 1);
        continue;
      }
      var allocation;

      if (split.Id) {
        allocation = {
          npsp__General_Accounting_Unit__c: split.Fund.Id,
          Fund_GL_Account__c: split.glAcct.Id,
          Campaign__c: split.Campaign && split.Campaign.Id ? split.Campaign.Id : null,
          Original_Amount__c: parseFloat(split.Original_Amount__c),
          Original_Currency__c : parentRecord && parentRecord.Original_Currency__c ? parentRecord.Original_Currency__c : 'USD',
          Description__c: split.Description__c != null ? split.Description__c : null,
          Tax_Deductible__c: split.Tax_Deductible__c,
          Id: split.Id
        }
      } else {
        allocation = {
          npsp__General_Accounting_Unit__c: split.Fund.Id,
          Fund_GL_Account__c: split.glAcct.Id,
          Campaign__c: split.Campaign && split.Campaign.Id ? split.Campaign.Id : null,
          Original_Amount__c: parseFloat(split.Original_Amount__c),
          Original_Currency__c : parentRecord && parentRecord.Original_Currency__c ? parentRecord.Original_Currency__c : 'USD',
          Description__c: split.Description__c != null ? split.Description__c : null,
          Tax_Deductible__c: split.Tax_Deductible__c
        }
      }

      sum += parseFloat(allocation.Original_Amount__c);
      !split.Id ?
        allocationList.push(allocation) :
        updateAllocationList.push(allocation);
    }

    if (parseFloat(sum.toFixed(2)) !== parseFloat(totalAmount) && valid) {
      component.find('notifLib').showToast({
        title: 'Error!',
        variant: 'error',
        message: 'The sum of Allocations must equal the total Opportunity Amount!'
      });
      valid = false;
    }
    if ((totalAmount == 0 || sum == 0) && !component.get('v.isAdjustment') && valid) {
      component.find('notifLib').showToast({
        title: 'Error!',
        variant: 'error',
        message: 'The Amount must be greater than zero!'
      });
      valid = false;
    }

    //needed because you can't have allocation Total higher than opp Amount
    var originalAmountHigher = false;
    if (record.Original_Amount__c >= component.get('v.editOriginalAmount')) {
      originalAmountHigher = true;
    }

    if (component.get('v.isAdjustment')) {
      if (record.Original_Amount__c > 0) { // for adjustments
        record.StageName = 'Posted';
      }
    }

    var accountRecordId = isLead && !record.AccountId ? null : record.AccountId;
    var ongoingDonor = record.OngoingCheckDonor;

    console.log('Valid Record? ', valid);
    console.log('Record(s): ', record);

    if (valid && record) {
      component.get('v.editingOpportunity') == false ?
        helper.saveRecord(component, record, allocationList, accountRecordId, ongoingDonor) :
        helper.editRecord(component, record, allocationList, updateAllocationList, originalAmountHigher, accountRecordId, ongoingDonor);
    }
  },

  closeUploadFileModal : function(component, event, helper){
    console.log('\nCAND_BT_FormController.closeUploadFileModal');

    component.set('v.uploadFileOnSave', false);
    component.set('v.uploadFileModal', false);
    component.set('v.uploadFileOppId', null);
  }
})