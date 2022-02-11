({
  doInit: function (component, event, helper) {
    console.log('\nCAND_BT_ListViewController.doInit');
    var btSettings = component.get('v.btSettings');
    console.log(JSON.parse(JSON.stringify(btSettings)));

    if (btSettings && btSettings.listViewMap) {
      helper.buildFilterOptions(component);
      helper.buildColumns(component);
    } else {
      alert('No settings found!');
    }
  },

  sortColumns: function (component, event, helper) {
    if (event.getParam('fieldName') === component.get('v.sortedBy')) {
      // Reverse Sorting
      if (component.get('v.sortedDirection') === 'asc') {
        component.set('v.sortedDirection', 'desc');
      } else {
        component.set('v.sortedDirection', 'asc');
      }
    } else {
      // Default to Ascending
      component.set('v.sortedDirection', 'asc');
    }
    component.set('v.sortedBy', event.getParam('fieldName'));
    helper._fetchData(component);
  },

  filterRecords: function (component, event, helper) {
    component.set('v.loadMoreStatus', '');
    var filter = component.get('v.selectedFilter');
    if (filter == 'CreatedDate = TODAY') {
      component.set('v.sortedBy', 'Status__c');
    } else {
      component.set('v.sortedBy', 'CreatedDate');
    }
    helper._fetchData(component);
  },

  handleFilterSearch: function (component, evt, helper) {
    setTimeout($A.getCallback(() => {
      var text = component.find('filterText').get('v.value');
      if (text && text.length >= 2) {
        helper._fetchData(component);
      } else if (!text) {
        helper._fetchData(component);
      }
    }), 200);
  },

  handleBatchSearch: function (component, event, helper) {
    setTimeout($A.getCallback(() => {
      var text = component.find('batchFilter').get('v.value');
      if (text && text.length >= 2) {
        component.set("v.batchSearch", true);
        helper._fetchData(component);
      } else if (!text) {
        component.set("v.batchSearch", false);
        helper._fetchData(component);
      } else {
        component.set("v.batchSearch", false);
      }
    }), 200);
  },

  onClickRefresh: function (component, event, helper) {
    component.set('v.loadMoreStatus', '');
    helper._fetchData(component);
  },

  onClickCreate: function (component, event, helper) {
    component.set('v.batchRecordId', '');
    var modal = component.find("modal")
    modal.toggleDisplay();
  },

  handleRowAction: function (component, event, helper) {
    var action = event.getParam('action');
    var data = component.get('v.recordList');
    var row = event.getParam('row');
    var rowIndex = data.indexOf(event.getParam('row'));
    component.set('v.rowIndex', rowIndex);
    
    if (action.name === 'openForm') {
      helper.openForm(component, row);
    } else if (action.name === 'closeRecord') {
      helper.closeRecord(component, row);
    } else if (action.name === 'editRecord') {
      helper.editRecord(component, row);
    } else if (action.name === 'receiptBatch') {
      helper.receiptBatch(component, row);
    } else if (action.name === 'viewReport') {
      helper.viewReport(component, row);
    }
  },

  loadMoreData: function (component, event, helper) {
    console.log('CAND_BT_ListViewController.onLoadMoreData');
    if (component.get('v.loadMoreStatus') === 'Navigating') {
      return;
    }

    var recordList = component.get('v.recordList');
    console.log('record list length =', recordList.length);
    console.log('max table size =', component.get('v.maxTableSize'));
    console.log('last chunk Limit =', component.get('v.lastChunkLimit'));
    console.log('load more =', component.get('v.loadMoreStatus'));

    if (recordList.length >= component.get('v.maxTableSize')) {
      component.find('notifLib').showToast({
        message: 'Maximum limit for table rows.'
      });
    } else if (recordList.length < component.get('v.lastChunkLimit')) {
      component.set('v.enableInfiniteLoading', false);
      return;
    } else if (component.get('v.loadMoreStatus') !== 'Loading') {
      component.set('v.loadMoreStatus', 'Loading');
      helper._fetchData(component);
    }
  },

  editOppRecord: function (component, event, helper) {
    var editRecordEvent = $A.get("e.force:editRecord");
    editRecordEvent.setParams({
      "recordId": event.target.value
    });
    editRecordEvent.fire();

  },

  editOppRecordInPage: function (component, event, helper) {
    var filloutOpportunityForm = component.getEvent('CAND_BT_filloutOppForm');
    var record = event.target.value;
    filloutOpportunityForm.setParams({
      "opportunity": record
    });
    filloutOpportunityForm.fire();
  }
})