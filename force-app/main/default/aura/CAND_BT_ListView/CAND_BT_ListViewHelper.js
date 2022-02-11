({
  buildFilterOptions: function (component) {
    console.log('buildFilterOptions');
    var btSettings = component.get('v.btSettings');
    var listView = component.get('v.sObjectAPIName');
    console.log('sobject', component.get('v.sObjectName'));
    console.log('listView = ', listView);
    var listViewSettings = btSettings.listViewMap[listView];
    console.log('listViewSettings = ', listViewSettings);
    var listViewFilters = [];

    if (listViewSettings.filters) {
      for (var i in listViewSettings.filters) {
        listViewFilters.push({
          text: i,
          value: listViewSettings.filters[i]
        });
      }

      component.set('v.selectedFilter', listViewFilters[0].value);
    }
    component.set('v.listViewFilters', listViewFilters);
  },

  buildColumns: function (component) {
    console.log('CAND_BT_ListViewHelper.buildColumns');
    var btSettings = component.get('v.btSettings');
    var listView = component.get('v.sObjectAPIName');
    component.set('v.shouldShowSpinner', true);
    var listViewSettings = btSettings.listViewMap[listView];
    var columns = [];

    var actionColumns = [];
    actionColumns.push({
      type: 'button',
      initialWidth: 75,
      typeAttributes: {
        iconName: '',
        label: 'Edit',
        name: 'editRecord',
        title: 'Edit Batch Record'
      }
    });

    if (listViewSettings.isTopLevelListView) {
      actionColumns.push({
        type: 'button',
        initialWidth: 103,
        typeAttributes: {
          iconName: '',
          label: 'Close',
          name: 'closeRecord',
          title: 'Close Batch'
        }
      }, {
        type: 'button',
        initialWidth: 90,
        typeAttributes: {
          iconName: '',
          label: 'Form',
          name: 'openForm',
          title: 'Open New Opportunity Form'
        }
      }, {
        type: 'button',
        initialWidth: 92,
        typeAttributes: {
          iconName: '',
          label: 'Report',
          name: 'viewReport',
          title: 'View Report'
        }
      });
    }

    component.set('v.actionColumns', actionColumns);

    for (let col in actionColumns) {
      columns.push(actionColumns[col]);
    }

    for (let col in listViewSettings.columns) {
      columns.push({
        label: listViewSettings.columns[col].label,
        fieldName: listViewSettings.columns[col].fieldPath,
        type: listViewSettings.columns[col].dataType.toLowerCase(),
        sortable: listViewSettings.columns[col].isSortable,
        initialWidth: 200
      });
    }

    if (!component.get('v.displayedOnBatchRecord')) {
      component.set('v.sortedDirection', 'ASC');
    }
    component.set('v.columns', columns);
    var ordering = component.get('v.sortedBy') + ' ' + component.get('v.sortedDirection');
    this._fetchData(component, ordering);
  },

  _fetchData: function (component, orderBy) {
    console.log('\n\nCAND_BT_ListViewHelper.fetchData');

    component.set('v.shouldShowSpinner', true);

    var btSettings = component.get('v.btSettings');
    var listView = component.get('v.sObjectAPIName');
    var listViewSettings = btSettings.listViewMap[listView];
    var filter = JSON.parse(JSON.stringify(component.get('v.selectedFilter')));

    // The form object
    var formRecord = component.get('v.formRecord');
    if (formRecord) {
      // Flatten the record so that we can use it like a map
      var records = [formRecord];
      records = this._flattenData(component, records);
      formRecord = records[0];
    }

    // Build the WHERE clause
    var whereClause = filter;
    var gauAllocationClause = null;

    if (filter) {
      var queryVariable;
      var startIndex;
      var endIndex;

      for (let i = 0; i <= filter.length; i++) {
        if (!startIndex && filter[i] === '{') {
          // Found start or end of the variable to replace
          startIndex = i;
          queryVariable = null; // Reset queryVariable
        } else if (!endIndex && filter[i] === '}') {
          // Must be the end of the variable
          endIndex = i;
          queryVariable = filter.substring(startIndex, endIndex + 1);
          var actualField = queryVariable.substring(1, queryVariable.length - 1);
          var value = formRecord[actualField];

          if (value) {
            whereClause = whereClause.replace(queryVariable, value);
            // Reset the queryVariable search variables
            // because there may be another one in the string
            queryVariable = null;
            startIndex = null;
            endIndex = null;
          } else {
            // The WHERE clause would be invalid because we do not have
            // the value to replace the queryVariable
            component.set('v.shouldShowSpinner', false);
            return;
          }
        }
      }
    }

    if (!component.get('v.displayedOnBatchRecord') && component.get('v.recordListToCheckForSearch').length !== 0) {
      var text = component.find('filterText').get('v.value');
      if (text) {
        gauAllocationClause = whereClause;
        gauAllocationClause += ' AND Id IN (SELECT npsp__Opportunity__c FROM npsp__Allocation__c WHERE npsp__General_Accounting_Unit__r.Name LIKE \'%' + text + '%\')';
        if (!isNaN(text)) {
          whereClause += ' AND (Name LIKE \'%' + text + '%\' OR Account.Name LIKE \'%' + text + '%\' OR Amount = ' + parseFloat(text) +
            ' OR npsp__Primary_Contact__r.Name LIKE  \'%' + text + '%\')';
        } else {
          whereClause += ' AND (Name LIKE \'%' + text + '%\' OR Account.Name LIKE \'%' + text +
            '%\' OR npsp__Primary_Contact__r.Name LIKE  \'%' + text + '%\')';
        }
      }
    }

    if (!orderBy) {
      if (!component.get('v.displayedOnBatchRecord')) {
        component.set('v.sortedDirection', 'ASC');
      }
      orderBy = component.get('v.sortedBy') + ' ' + component.get('v.sortedDirection');
    }

    var lim = listViewSettings.queryRowLimit;
    var offSet = 0;

    if (component.get('v.loadMoreStatus') === 'Loading') {
      // Calculate offset
      var recordList = component.get('v.recordList');
      var totalNumberOfRows = recordList.length;
      // offSet = totalNumberOfRows + listViewSettings.queryRowLimit;
      offSet = totalNumberOfRows;
      var lim = listViewSettings.queryRowLimit + totalNumberOfRows;


      if (offSet < 2000) {
        // Okay to use offset and predefined limit to chunk the size of the fetched data
      } else {
        offSet = 0;
        lim += totalNumberOfRows + listViewSettings.queryRowLimit;
      }
    }

    if (lim > component.get('v.maxTableSize')) {
      lim = component.get('v.maxTableSize');
    }
    component.set('v.lastChunkLimit', lim);

    if (component.get('v.batchSearch')) {
      var text = component.find('batchFilter').get('v.value');
      whereClause = "Name LIKE '%" + text + "%'";
    }
    var paramList = {
      selectFields: listViewSettings.fieldAPINames,
      fromObject: listViewSettings.objectAPIName,
      whereClause: whereClause,
      orderBy: orderBy,
      lim: lim,
      offSet: offSet
    };
    if (gauAllocationClause) {
      var gauParams = {
        selectFields: listViewSettings.fieldAPINames,
        fromObject: listViewSettings.objectAPIName,
        whereClause: gauAllocationClause,
        orderBy: orderBy,
        lim: lim,
        offSet: offSet
      }
    }

    var action = component.get('c.fetchData');
    action.setParams({
      queryParamsJSON: JSON.stringify(paramList),
      gauParamsJSON: JSON.stringify(gauParams)
    });

    action.setCallback(this, (result) => {
      component.set('v.shouldShowSpinner', false);

      if (result.getState() === 'ERROR') {
        alert('Error retrieving data: ' + JSON.stringify(result.getError()));
      } else if (result.getState() === 'SUCCESS') {
        var data = result.getReturnValue();
        data = this._flattenData(component, data);

        if (data.length === component.get('v.maxTableSize')) {
          component.set('v.enableInfiniteLoading', false);
        } else {
          component.set('v.enableInfiniteLoading', true);
        }

        if (component.get('v.loadMoreStatus') === 'Loading') {
          // Concatenate the fetched data with the current data
          var currentData = component.get('v.recordList');
          var newData = currentData.concat(data);
          component.set('v.loadMoreStatus', '');
          component.set('v.recordList', newData);
        } else {
          // Replace the current data with the fetched data
          component.set('v.recordList', data);
          component.set('v.loadMoreStatus', '');
        }
        //Sets the fully updated list with no search informaiton
        if (!component.get('v.displayedOnBatchRecord') && !whereClause.includes('AND')) {
          component.set('v.recordListToCheckForSearch', component.get('v.recordList'));
        }
        if (component.get('v.selectedFilter') == 'CreatedDate = TODAY') { //Sorted to Today's Date
          var recordList = component.get('v.recordList');
          component.set('v.recordListSize', recordList.length);
          var count = 0;
          for (var i = 0; i < recordList.length; i++) {
            if (recordList[i].Receipted_Date__c != undefined) {
              count++;
            }
          }
          component.set('v.numberReceipted', count);
        }
      } else {
        alert('Error retrieving data.');
      }
    });

    $A.enqueueAction(action);
  },

  _flattenData: function (component, data) {
    for (let o in data) { // Loop through records
      this._traverseObject(data, o, data[o], '');
    }
    return data;
  },

  _traverseObject: function (data, idx, obj, currentPath) {
    if (currentPath) {
      currentPath += '.';
    }
    Object.keys(obj).forEach(k => {
      if (obj[k] && typeof obj[k] === 'object') {
        return this._traverseObject(data, idx, obj[k], currentPath + k);
      } else {
        var pathKey = currentPath + k;
        if (!currentPath) {
          pathKey = k;
        }
        var pathRes = [pathKey, obj[k]];
        data[idx][pathKey] = obj[k];
      }
    });
  },

  openForm: function (component, row) {
    console.log('\nCAND_BT_ListViewHelper.openForm');
    if (row.Status__c === 'Approved') {
      component.find('notifLib').showToast({
        title: 'Error!',
        variant: 'error',
        message: 'Cannot enter new data because the record has already been approved!'
      });
      return;
    }

    component.set('v.loadMoreStatus', 'Navigating');

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
  },

  closeRecord: function (component, row) {
    console.log('\nCAND_BT_ListViewHelper.closeRecord');
    var btSettings = component.get('v.btSettings');
    if (!btSettings.user.Can_Approve_Batches__c) {
      component.find('notifLib').showToast({
        title: 'Error!',
        variant: 'error',
        message: 'User does not have permission, please contact an administrator to approve this record.'
      });
      return;
    }

    if (row.Status__c === 'Closed' || row.Status__c === 'Approved' || row.Status__c === 'Posted to GL') {
      component.find('notifLib').showToast({
        title: 'Error!',
        variant: 'error',
        message: 'Record has already been locked!'
      });
      return;
    }

    var action = component.get('c.updateRecord');
    action.setParams({
      record: {
        Id: row.Id,
        Status__c: 'Closed'
      }
    });

    component.set('v.shouldShowSpinner', true);
    action.setCallback(this, (result) => {
      component.set('v.shouldShowSpinner', false);

      if (result.getState() === 'ERROR') {
        alert('Error updating record: ' + JSON.stringify(result.getError()));
      } else {
        console.log('\nCAND_BT_ListViewHelper record updated!');
        var resultRecord = result.getReturnValue();
        var data = JSON.parse(JSON.stringify(component.get('v.recordList')));
        var rowIndex = component.get('v.rowIndex');

        if (rowIndex !== -1) {
          component.find('notifLib').showToast({
            title: 'Success!',
            variant: 'success',
            message: 'Record Closed!'
          });

          data[rowIndex].Status__c = resultRecord.Status__c;
          component.set('v.recordList', data);
          component.set('v.rowIndex', -1);
        }
      }
    });
    $A.enqueueAction(action);
  },

  editRecord: function (component, row) {
    if (row.Status__c === 'Approved') {
      component.find('notifLib').showToast({
        title: 'Error!',
        variant: 'error',
        message: 'Cannot edit data because the record has already been approved!'
      });
      return;
    }
    component.set('v.batchRecordId', row.Id);
    var modal = component.find("modal")
    modal.toggleDisplay();
  },
  
  receiptBatch: function (component, row) {
    if (!(row.Status__c == 'Approved' || row.Status__c == 'Posted to GL')) {
      component.find('notifLib').showToast({
        title: 'Error!',
        variant: 'error',
        message: 'Cannot receipt until the Batch is Approved!'
      });
      return;
    }
    var btSettings = component.get('v.btSettings');
    if (!btSettings.user.Can_Approve_Batches__c) {
      component.find('notifLib').showToast({
        title: 'Error!',
        variant: 'error',
        message: 'User does not have permission, please contact an administrator to receipt this record.'
      });
      return;
    }
    
    // row.Receipted_Date__c = today();
    if (row.Receipted_Date__c != undefined) {
      component.find('notifLib').showToast({
        title: 'This Batch has already been receipted.',
        variant: 'info',
        // message: 'This Batch has already been receipted.'
      });
      return;
    }
    
    var action = component.get('c.markReceipted');
    var batchIds = new Array();
    batchIds.push({
      Id: row.Id
    });
    action.setParams({
      batchIdsJSON: JSON.stringify(batchIds)
    });
    
    action.setCallback((this), (result) => {
      if (result.getState() == 'SUCCESS') {
        var data = JSON.parse(JSON.stringify(component.get('v.recordList')));
        var rowIndex = component.get('v.rowIndex');
        component.find('notifLib').showToast({
          title: 'Success!',
          variant: 'success',
          message: 'The Batch has been receipted.'
        });
        var today = new Date();
        data[rowIndex].Receipted_Date__c = $A.localizationService.formatDate(today);
        component.set('v.recordList', data);
        component.set('v.rowIndex', -1);
      } else {
        component.find('notifLib').showToast({
          title: 'Error!',
          variant: 'error',
          message: 'An unexpected error has occured! Please review this batch and try again.'
        });
      }
    })
    
    $A.enqueueAction(action);
  },

  viewReport: function (component, row) {
    var action = component.get('c.getReconciliationReportId');
    action.setCallback(this, (result) => {
      if (result.getState() == 'SUCCESS') {
        window.open(location.href.substring(0, location.href.indexOf('/', 14)) 
          + '/lightning/r/Report/' + result.getReturnValue() +'/view?fv0=' + row.Id); 
      } else {
        component.find('notifLib').showNotice({
          header: 'Error!',
          variant: 'error',
          message: 'Error: Uh-oh! There is an issue linking out to the Report.'
        });
      }
	  });
    $A.enqueueAction(action);
  }
})