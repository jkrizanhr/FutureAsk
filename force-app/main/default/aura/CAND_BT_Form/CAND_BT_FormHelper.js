({
  _initializeRecord: function (component) {
    console.log('\nCAND_BT_FormHelper._initializeRecord');

    component.set('v.editingOpportunity', false);
    component.set('v.isAdjustment', false);
    component.set('v.isLead', false);
    component.set('v.deleteRecordSplitList', []);
    component.set('v.matchingGiftList', [{}]);
    var parentRecordId = component.get('v.parentRecord.Id');
    var actionRecord = component.get('c.getNewParent');
    actionRecord.setParams({
      parentRecordId: parentRecordId
    });

    actionRecord.setCallback(this, (result) => {
      if (result.getState() === 'ERROR') {
        component.find('notifLib').showNotice({
          header: 'Error!',
          variant: 'error',
          message: 'Error: ' + JSON.stringify(result.getError())
        });
      } else if (result.getState() === "SUCCESS") {
        component.set("v.parentRecord", result.getReturnValue());
      }
    });

    //update these to be one
    this.setGivingOptions(component);
    this.setReceiptTypes(component);
    this.setLanguagePreferences(component);
    this.setDonationSources(component);

    $A.enqueueAction(actionRecord);

    var parentRecord = component.get('v.parentRecord');
    if (!component.get('v.parentRecord')) {
      component.find('notifLib').showNotice({
        header: 'Error!',
        variant: 'error',
        message: 'Error: No Parent Record'
      });
      return;
    }

    component.set('v.showAmount', false);
    component.set('v.showAmount', true);
    var recordSplitList = component.get('v.recordSplitList');

    var checkValue = '';
    var record = JSON.parse(JSON.stringify(component.get('v.record')));
    if (record && record.Payment_Method__c && record.Payment_Method__c == 'Check') {
      if (component.get('v.checkIsDisabled') == true) {
        checkValue = record.Payment_Reference_Number__c;
      }
    }
    var paymentMethodValue = null;
    if (component.get('v.paymentMethodIsLocked')){
      paymentMethodValue = component.get('v.paymentMethodIsLocked') ?
      component.find("Payment_Method__c").get('v.value') :
      ''; 
    } else if (parentRecord.Type__c != null){
      switch (parentRecord.Type__c){
        case 'Credit Cards':
          paymentMethodValue = 'Credit Card';
          break;
        case 'Cash and Checks':
          paymentMethodValue = 'Check';
          break;
        case 'Recurring Credit Cards':
          paymentMethodValue = 'Credit Card'
          break;
        case 'Recurring ACH':
          paymentMethodValue = 'Bank Account'
          break;
        case 'Wire Transfer':
          paymentMethodValue = 'Bank Account'
          break;
        default:
          paymentMethodValue = component.get('v.paymentMethodIsLocked') ?
            component.find("Payment_Method__c").get('v.value') :
            ''; 
      }
    } else {
      paymentMethodValue = '';
    }
    let Paid_By__r = component.get('v.singlePayorIsLocked') ?
      component.get('v.record.Paid_By__r') :
      '';
    let givingMethodValue = component.get('v.givingMethodIsLocked') ?
      component.find("Giving_Method__c").get('v.value') :
      'Return receipt Cards'; //TO DO: Change this
    let campaignValue = component.get('v.campaignIsLocked') 
      ? recordSplitList[0].Campaign 
      : '';
    let gauValue = component.get('v.gauIsLocked') 
      ? recordSplitList[0].Fund
      : '';
    let glAcctValue = component.get('v.gauIsLocked') 
      ? recordSplitList[0].glAcct
      : '';

    var initDate = component.get('v.record.CloseDate');
    if (!component.get('v.closeDateIsLocked')) {
      var parentRecord = component.get('v.parentRecord');
      initDate = parentRecord.Date__c;
    }
    component.set('v.record', {
      Original_Amount__c: '',
      Cash_Batch__c: parentRecord.Id,
      Description: '',
      Name: 'Opportunity Data Entry',
      StageName: 'Posted',
      Donation_Source__c: 'Mail',
      Paid_By__r: Paid_By__r,
      Payment_Method__c: paymentMethodValue,
      CloseDate: initDate,
      Giving_Method__c: givingMethodValue,
      Payment_Reference_Number__c: checkValue,
      Receipt_Type__c: 'Email',
      Original_Currency__c : parentRecord.Original_Currency__c
    });
    $A.util.removeClass(component.find('splitListDiv'), 'slds-hide');

    var btSettings = component.get('v.btSettings');
    if (btSettings && btSettings.form && btSettings.form.defaultRecordTypeId) {
      component.set('v.record.RecordTypeId', btSettings.form.defaultRecordTypeId);
    }
    if (parentRecord.Opportunity_Type__c === 'In-Kind Gift') {
      component.set('v.record.Stock_Name__c', '');
      component.set('v.record.Stock_Symbol__c', '');
      component.set('v.record.Number_Of_Shares__c', '');
      component.set('v.record.Broker__c', '');
      component.set('v.record.npsp__Fair_Market_Value__c', '');
      component.set('v.record.npsp__In_Kind_Donor_Declared_Value__c', false);
      component.set('v.record.npsp__In_Kind_Type__c', 'Goods');
      component.set('v.record.npsp__In_Kind_Description__c', '');
    }


    component.set('v.recordSplitList', []);

    this._manageRecordSplitRows(component, campaignValue, gauValue, glAcctValue);

    if (component.get('v.showRelatedOpportunityList')) {
      var listView = component.find("opps");
      listView.refreshList();
    }
  },

  filloutOppForm: function (component, opp) {
    console.log('CAND_BT_FormHelper.filloutOppForm');
    console.log(opp);
    var parentRecordId = component.get('v.parentRecord.Id');
    var actionRecord = component.get('c.getNewParent');
    actionRecord.setParams({
      parentRecordId: parentRecordId
    });

    actionRecord.setCallback(this, (result) => {
      if (result.getState() === 'ERROR') {
        component.find('notifLib').showNotice({
          header: 'Error!',
          variant: 'error',
          message: 'Error: ' + JSON.stringify(result.getError())
        });
      } else if (result.getState() === "SUCCESS") {
        component.set("v.parentRecord", result.getReturnValue());
      } else {
        component.find('notifLib').showNotice({
          header: 'Error!',
          variant: 'error',
          message: 'Error: ' + JSON.stringify(result.getError())
        });
      }
    })

    $A.enqueueAction(actionRecord);

    var parentRecord = component.get('v.parentRecord');
    if (!component.get('v.parentRecord')) {
      component.find('notifLib').showNotice({
        header: 'Error!',
        variant: 'error',
        message: 'Error: No parent record!'
      });
      return;
    }

    component.set('v.showAmount', false);
    component.set('v.showAmount', true);
    component.set('v.closeDateIsLocked', false);
    component.set('v.paymentMethodIsLocked', false);
    component.set('v.singlePayorIsLocked', false);
    component.set('v.checkIsDisabled', false);

    //code below will change with Payment Method Updates
    let Payment_Method__c = (!opp.Payment_Method__c) ?
      'Select an Option...' :
      opp.Payment_Method__c;

    var DoNotAcknowledge;
    if (opp.npsp__Acknowledgment_Status__c == 'Do Not Acknowledge' && parentRecord.Type__c == 'Adjustments') {
      DoNotAcknowledge = true;
    }

    component.set('v.record', {
      Amount: opp.Amount,
      Original_Amount__c: opp.Original_Amount__c,
      Original_Currency__c: parentRecord.Original_Currency__c,
      Cash_Batch__c: parentRecord.Id,
      Description: opp.Description,
      Donation_Source__c: opp.Donation_Source__c != null ?  opp.Donation_Source__c : 'Mail',
      Name: opp.Name,
      StageName: opp.StageName,
      CloseDate: opp.CloseDate,
      AccountId: opp.AccountId,
      Account: opp.Account,
      npsp__Primary_Contact__c: opp.npsp__Primary_Contact__c,
      Contact: opp.npsp__Primary_Contact__r,
      CampaignId: opp.CampaignId,
      Campaign: opp.Campaign,
      FutureGift: opp.Future_Gift__r,
      Paid_By__c: opp.Paid_By__c,
      Paid_By__r: opp.Paid_By__r,
      Id: opp.Id,
      Is_Anonymous__c: opp.Is_Anonymous__c,
      Receipt_Type__c: opp.Receipt_Type__c,
      Language_Preference__c: 'English',
      OngoingCheckDonor: opp.Account.Is_Ongoing_Check_Donor__c,
      Giving_Method__c: opp.Giving_Method__c,
      Keyer__c: opp.Keyer__c,
      Keyer: opp.Keyer__r,
      DoNotAcknowledge: DoNotAcknowledge,
    });

    var record = JSON.parse(JSON.stringify(component.get('v.record')));
    record.Payment_Method__c = Payment_Method__c;
    if (Payment_Method__c == 'Check') {
      record.Payment_Reference_Number__c = opp.Payment_Reference_Number__c;
    }
    console.log(opp.Paid_By__c);
    console.log(record);
    component.set('v.record', record);

    //needed because you can't have allocation Total higher than opp Original_Amount__c
    component.set('v.editOriginalAmount', opp.Original_Amount__c);

    if (opp.npsp__Allocations__r) {
      var recordSplitList = [];
      for (var i = 0; i < opp.npsp__Allocations__r.length; i++) {
        var allocation = opp.npsp__Allocations__r[i];
        
        var campaign = null;
        if (allocation.Campaign__r != null){
          campaign = {
            Id: allocation.Campaign__r.Id,
            Name: allocation.Campaign__r.Name
          }
        }

        recordSplitList.push({
          Id: allocation.Id,
          Original_Amount__c: allocation.Original_Amount__c,
          index: i,
          Description__c: allocation.Description__c,
          Tax_Deductible__c: allocation.Tax_Deductible__c,
          Fund: {
            Id: allocation.npsp__General_Accounting_Unit__r.Id,
            Name: allocation.npsp__General_Accounting_Unit__r.Name,
            Warning_Message__c: allocation.npsp__General_Accounting_Unit__r.Warning_Message__c
          },
          glAcct: {
            Id: allocation.Fund_GL_Account__r.Id,
            Name: allocation.Fund_GL_Account__r.Name,
          },
          Campaign: campaign
        });
      }
      component.set('v.recordSplitList', recordSplitList);
      component.set('v.shouldDisableSplits', false);
    }

    if (parentRecord.Opportunity_Type__c === 'Matching Gift') {
      var matchingGiftList = [];
      for (var i in opp.npsp__MatchedGifts__r) {
        matchingGiftList.push({
          Gift: {
            Id: opp.npsp__MatchedGifts__r[i].Id,
            Name: opp.npsp__MatchedGifts__r[i].Name,
            npsp__Matching_Gift__c: opp.npsp__MatchedGifts__r[i].npsp__Matching_Gift__c
          }
        });
      }
      component.set('v.matchingGiftList', matchingGiftList);
    } else if (parentRecord.Opportunity_Type__c === 'In-Kind Gift') {
      component.set('v.record.Stock_Name__c', opp.Stock_Name__c);
      component.set('v.record.Stock_Symbol__c', opp.Stock_Symbol__c);
      component.set('v.record.Number_of_Shares__c', opp.Number_of_Shares__c);
      component.set('v.record.Broker__c', opp.Broker__c);
      component.set('v.record.npsp__Fair_Market_Value__c', opp.npsp__Fair_Market_Value__c);
      component.set('v.record.npsp__In_Kind_Donor_Declared_Value__c', opp.npsp__In_Kind_Donor_Declared_Value__c);
      component.set('v.record.npsp__In_Kind_Type__c', opp.npsp__In_Kind_Type__c);
      component.set('v.record.npsp__In_Kind_Description__c', opp.npsp__In_Kind_Description__c);
    }
  },

  createReversal: function (component, opp) {
    console.log('CAND_BT_FormHelper.createReversal');
    this.filloutOppForm(component, opp);
    var record = JSON.parse(JSON.stringify(component.get('v.record')));
    record.Original_Amount__c = -Math.abs(record.Original_Amount__c);
    var recordSplitList = JSON.parse(JSON.stringify(component.get('v.recordSplitList')));
    for (var i = 0; i < recordSplitList.length; i++) {
      recordSplitList[i].Original_Amount__c = -Math.abs(recordSplitList[i].Original_Amount__c);
      recordSplitList[i].Id = '';
    }

    record.Id = null;
    record.Adjusted_Opportunity__c = opp.Id;
    record.StageName = 'Adjustment';
    record.CloseDate = opp.CloseDate;

    component.set('v.originalOpp', opp);
    component.set('v.record', record);
    component.set('v.recordSplitList', recordSplitList);
  },

  _manageRecordSplitRows: function (component, campaignValue, gauValue, glAcctValue) {
    console.log('\nCAND_BT_FormHelper._manageRecordSplitRows');

    var recordSplitList = JSON.parse(JSON.stringify(component.get('v.recordSplitList')));
    var isAnonymous = component.get('v.record.Is_Anonymous__c');

    if (!recordSplitList) {
      recordSplitList = [];
    }
    var recordSplit = {
      Id: '',
      Original_Amount__c: '',
      index: recordSplitList.length,
      Anonymous__c: isAnonymous,
      Campaign: campaignValue,
      Fund: gauValue,
      glAcct: glAcctValue,
      Tax_Deductible__c: true
    };
    recordSplitList.push(recordSplit);

    if (recordSplitList.length > 1) {
      var record = JSON.parse(JSON.stringify(component.get('v.record')));
      var setAmount = 0;
      if (record.Original_Amount__c) {
        var total = 0.00;
        for (var i = 0; i < recordSplitList.length - 1; i++) {
          total += parseFloat(recordSplitList[i].Original_Amount__c);
        }
        if (record.Original_Amount__c - total >= 0) {
          setAmount = record.Original_Amount__c - total;
        }
      }
      recordSplitList[recordSplitList.length - 1].Original_Amount__c = setAmount;
      if (component.get('v.campaignIsLocked')) {
        recordSplitList[recordSplitList.length - 1].Campaign = recordSplitList[0].Campaign
      }
      if (component.get('v.gauIsLocked')) {
        recordSplitList[recordSplitList.length - 1].Fund = recordSplitList[0].Fund
        recordSplitList[recordSplitList.length - 1].glAcct = recordSplitList[0].glAcct
      }
    }

    component.set('v.recordSplitList', recordSplitList);
  },

  setGivingOptions: function (component) {
    var action = component.get('c.getGivingOptions');

    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        component.set('v.givingOptions', response.getReturnValue());
      } else {
        console.log('Could not get giving options');
      }
    });

    $A.enqueueAction(action);
  },

  setReceiptTypes: function (component) {
    var action = component.get('c.getReceiptTypes');

    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        component.set('v.receiptTypes', response.getReturnValue());
      } else {
        console.log('Could not get receipt options');
      }
    });

    $A.enqueueAction(action);
  },
  
  setLanguagePreferences: function (component) {
    var action = component.get('c.getLanguagePreferences');

    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        component.set('v.languagePreferences', response.getReturnValue());
      } else {
        console.log('Could not get language options');
      }
    });

    $A.enqueueAction(action);
  },
  
  setDonationSources: function (component) {
    var action = component.get('c.getDonationSources');

    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        component.set('v.donationSources', response.getReturnValue());
      } else {
        console.log('Could not get donation source options');
      }
    });

    $A.enqueueAction(action);
  },

  getRecordTypeIds: function (component) {
    var action = component.get('c.returnIdTypes');
    action.setCallback(this, (result) => {
      if (result.getState() == 'SUCCESS') {
        var ids = result.getReturnValue();
        component.set('v.matchingGiftTypeId', ids.matchingGift);
        component.set('v.inKindGiftTypeId', ids.inKindGift);
      } else {
        component.find('notifLib').showNotice({
          header: 'Error!',
          variant: 'error',
          message: 'Error loading record: ' + JSON.stringify(result.getError())
        });
      }
    });
    $A.enqueueAction(action);
  },

  setMatchingGift: function (component, matchingGifts, opp) {
    var action = component.get('c.setMatchingGiftLookup');
    var gifts = [];
    for (var i in matchingGifts) {
      if (matchingGifts[i].Gift && !matchingGifts[i].Gift.npsp__Matching_Gift__c) {
        gifts.push({
          Id: matchingGifts[i].Gift.Id
        });
      }
    }
    action.setParams({
      matchingGifts: gifts,
      opp: opp
    });
    action.setCallback(this, (result) => {
      if (result.getState() === 'SUCCESS') {
        console.log(result.getState());
      } else {
        component.find('notifLib').showNotice({
          header: 'Error!',
          variant: 'error',
          message: 'Something went wrong when updating the matching gifts! You will need to reassign the gifts. \nError: ' + JSON.stringify(result.getError())
        });
      }
    });
    $A.enqueueAction(action);
  },

  deleteMatchingGifts: function (component, deleteMatchingGifts) {
    var action = component.get('c.removeMatchingGiftLookup');
    action.setParams({
      deleteMatchingGifts: deleteMatchingGifts
    });
    action.setCallback(this, (result) => {
      if (result.getState() === 'SUCCESS') {
        console.log(result.getState());
        
      } else {
        component.find('notifLib').showNotice({
          header: 'Error!',
          variant: 'error',
          message: 'Something went wrong when updating the matching gifts! You will need to reassign the gifts. \nError: ' + JSON.stringify(result.getError())
        });
      }
    });
    $A.enqueueAction(action);
  },

  _convertLead : function(component, leadId){
    return new Promise($A.getCallback(function(resolve, reject){
      var convertLead = component.get('c.convertLeadRecord');
      convertLead.setParams({
        leadId: leadId
      });
      convertLead.setCallback(this, (result) => {
        if (result.getState() === 'ERROR') {
          reject(result.getError());
        } else {
          resolve(result.getReturnValue());
        }
      });
      $A.enqueueAction(convertLead);
    }));
  },

  _saveRecord : function(component, record, recordSplitList, accountRecordId, ongoingDonor){
    var updateAccount = component.get('c.updateAccountRecord');
    updateAccount.setParams({
      recordId: accountRecordId,
      ongoingDonor : ongoingDonor
    });
    $A.enqueueAction(updateAccount);
    console.log(record);
    var action = component.get('c.submitForm');
    action.setParams({
      formRecord: JSON.stringify(record),
      formRecordSplits: JSON.stringify(recordSplitList)
    });

    component.set('v.shouldShowSpinner', true);
    action.setCallback(this, (result) => {
      component.set('v.shouldShowSpinner', false);

      if (result.getState() === 'ERROR') {
        component.find('notifLib').showNotice({
          header: 'Error!',
          variant: 'error',
          message: 'Error saving record: ' + JSON.stringify(result.getError())
        });
      } else if (result.getState() === 'SUCCESS') {
        component.find('notifLib').showToast({
          title: 'Success!',
          variant: 'success',
          message: 'Successfully saved the record!'
        });
                
        var record = JSON.parse(JSON.stringify(component.get('v.record')))
        
        component.set("v.uploadFileOppId", result.getReturnValue().Id);
        
        component.set("v.uploadFileModal", component.get("v.uploadFileOnSave"));
        
        if (component.get('v.isAdjustment') && record.Original_Amount__c != 0) {
          var setStageAction = component.get('c.setStageToAdjustment');
          var opp = component.get('v.originalOpp');
          setStageAction.setParams({
            opp: opp
          });
          setStageAction.setCallback(this, (result) => {
            console.log(result.getState());
          });
          $A.enqueueAction(setStageAction);
        }
        var matchingGiftList = component.get('v.matchingGiftList');
        if (matchingGiftList && matchingGiftList.length > 0) {
          this.setMatchingGift(component, matchingGiftList, result.getReturnValue());
        }
        
        this._initializeRecord(component);
      }
    });
    $A.enqueueAction(action);
  },

  // Submit the form data to the server
  saveRecord: function (component, record, recordSplitList, accountRecordId, ongoingDonor) {
    console.log('\nCAND_BT_FormHelper.saveRecord');
    if (component.get('v.isLead')){
      var promise = this._convertLead(component, record.npsp__Primary_Contact__c);
      promise
        .then($A.getCallback((res) => {
          console.log(res);
          record.npsp__Primary_Contact__c = res.contactId;
          if (record.AccountId == null){
            record.AccountId = res.accountId;
            accountRecordId = res.accountId;
          }
        }))
        .catch($A.getCallback((res) => {
          component.find('notifLib').showNotice({
            header: 'Error!',
            variant: 'error',
            message: 'Error converting record: ' + JSON.stringify(res)
          });
        }))
        .then($A.getCallback(() => {
          this._saveRecord(component, record, recordSplitList, accountRecordId, ongoingDonor);
        }))
    } else {
      this._saveRecord(component, record, recordSplitList, accountRecordId, ongoingDonor);
    }
  },
  
  editRecord: function (component, record, recordSplitList, updateAllocationList, originalAmountHigher, accountRecordId, ongoingDonor) {
    console.log('\nCAND_BT_FormHelper.editRecord');
    var deleteRecordSplitList = component.get('v.deleteRecordSplitList');
  
    var updateAccount = component.get('c.updateAccountRecord');
    updateAccount.setParams({
      recordId: accountRecordId,
      ongoingDonor : ongoingDonor
    });
    $A.enqueueAction(updateAccount);

    var action = component.get('c.updateRecordEdit');
    action.setParams({
      formRecord: JSON.stringify(record),
      formRecordSplits: JSON.stringify(recordSplitList),
      updateSplits: JSON.stringify(updateAllocationList),
      originalAmountHigher: originalAmountHigher,
      deleteRecordSplitList: JSON.stringify(deleteRecordSplitList)
    });
    
    component.set('v.shouldShowSpinner', true);
    action.setCallback(this, (result) => {
      component.set('v.shouldShowSpinner', false);
      
      if (result.getState() === 'ERROR') {
        component.find('notifLib').showNotice({
          header: 'Error!',
          variant: 'error',
          message: 'Error saving record: ' + JSON.stringify(result.getError())
        });
      } else {
        component.find('notifLib').showToast({
          title: 'Success!',
          variant: 'success',
          message: 'Successfully saved the record!'
        });
        
        var record = JSON.parse(JSON.stringify(component.get('v.record')));
        
        component.set("v.uploadFileOppId", record.Id);
        component.set("v.uploadFileModal", component.get("v.uploadFileOnSave"));

        // if (record.Multiple_Pages__c == true) {
        //   var setReceiptAction = component.get('c.setReceiptType');
        //   var multiples = component.get('v.multiples');
        //   setReceiptAction.setParams({
        //     multiples: multiples
        //   });
        //   setReceiptAction.setCallback(this, (result) => {
        //     if (result.getState() === 'SUCCESS') {
        //       console.log("Success")
        //     } else {
        //       console.log(result.getState());
        //     }
        //   })
        //   $A.enqueueAction(setReceiptAction);
        // }
        var matchingGiftList = component.get('v.matchingGiftList');
        var deleteMatchingGiftList = component.get('v.deleteMatchingGiftList');
        if (matchingGiftList && matchingGiftList.length > 0) {
          this.setMatchingGift(component, matchingGiftList, result.getReturnValue());
        }
        if (deleteMatchingGiftList && deleteMatchingGiftList.length > 0) {
          this.deleteMatchingGifts(component, deleteMatchingGiftList);
        }

        this._initializeRecord(component);
      }
    });
    $A.enqueueAction(action);
  }

})