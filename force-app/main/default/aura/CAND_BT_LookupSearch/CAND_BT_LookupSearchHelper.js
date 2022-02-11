({
  fireChangeEvent: function (component) {
    var index = component.get('v.objectIndex') ? component.get('v.objectIndex') : 0;
    var evt = component.getEvent('searchEvent');
    evt.setParams({
      fieldAPIName: component.get('v.fieldAPIName'),
      object: component.get('v.selectedObject'),
      objectAPIName: component.get('v.objectAPIName'),
      objectIndex: index
    });
    evt.fire();
  },

  search: function (component, searchText) {
    console.log('\nCAND_BT_LookupSearchHelper.search');

    // Get Form Fields from Custom Metadata
    var btSettings = component.get('v.btSettings');
    console.log('btSettings:', btSettings);
    
    var fieldAPIName = component.get('v.fieldAPIName');
    console.log('bt', JSON.parse(JSON.stringify(btSettings.form.formFieldMap)));
    // If the Form Field is not found - through error.
    if (!btSettings.form ||
      !btSettings.form.formFieldMap ||
      !btSettings.form.formFieldMap[fieldAPIName]) {
      alert('Custom Metadata Type Configuration Not Found!!');
      return;
    }

    // Check if using SOSL or SOQL
    var field = btSettings.form.formFieldMap[fieldAPIName];
    if (field.useSOSL){
      this._searchSOSL(component, searchText, field, btSettings);
    } else {
      this._searchSOQL(component, searchText, field);
    }
  },

  _searchSOSL : function(component, searchText, field, btSettings){
    // Build SELECT statement for query
    var selectFields = this._buildSelectStatement(component, field);
    // Get FROM object for query
    var fromObject = component.get('v.objectAPIName');
    // Build WHERE clause for query
    var whereClause = this._buildWhereClause(component, searchText, field);

    // Build additional SOSL queries
    var adtlQueries = [];
    if (field.additionalSoslQuery != null && field.additionalSoslQuery != ''){
      var tempList = field.additionalSoslQuery.split(',');
      for (var i = 0; i < tempList.length; i++){
        if(btSettings.form.formFieldMap[tempList[i]] != null){
          var queryField = btSettings.form.formFieldMap[tempList[i]];
          var adtlQuery = this._buildQuery(component, queryField, searchText);
          adtlQueries.push(adtlQuery);
        }  
      }
    }

    // Set queryParams to pass to Apex
    var queryParams = {
      selectFields: selectFields,
      fromObject: fromObject,
      whereClause: whereClause,
      orderBy: field && field.lookupOrderBy ? field.lookupOrderBy : '',
      lim: field && field.maxNumberOfResultsDisplayed ? field.maxNumberOfResultsDisplayed : 10,
      searchText: searchText,
      searchValues: searchText.split(' '),
      additionalSoslQueries: adtlQueries,
      soslSearchGroup: field.soslSearchGroup
    };

    // Do the SOSL query
    var action = component.get('c.searchData');
    action.setParams({
      queryParamsJSON: JSON.stringify(queryParams)
    });
    action.setCallback(this, (result) => {
      if (result.getState() === 'ERROR') {
        alert('Error while searching for records: ' + JSON.stringify(result.getError()));
      } else {
        var data = JSON.parse(JSON.stringify(result.getReturnValue()));
        var flatData = this._flattenData(component, data);
        console.log('Flat Data:', flatData);
        component.set('v.objects', flatData);
      }
    });
    $A.enqueueAction(action);
  },

  _searchSOQL : function(component, searchText, field){
    // Build SELECT statement for query
    var selectFields = this._buildSelectStatement(component, field);
    // Get FROM object for query
    var fromObject = component.get('v.objectAPIName');
    // Build the WHERE clause for query
    var whereClause = this._buildWhereClause(component, searchText, field);

    // Set queryParams to pass to Apex
    var queryParams = {
      selectFields: selectFields,
      fromObject: fromObject,
      whereClause: whereClause,
      orderBy: field && field.lookupOrderBy ? field.lookupOrderBy : '',
      lim: field && field.maxNumberOfResultsDisplayed ? field.maxNumberOfResultsDisplayed : 10,
      searchText: searchText,
      searchValues: searchText.split(' '),
    };

    // Do the SOQL query
    var action = component.get('c.fetchData');
    action.setParams({
      queryParamsJSON: JSON.stringify(queryParams)
    });
    action.setCallback(this, (result) => {
      if (result.getState() === 'ERROR') {
        alert('Error while searching for records: ' + JSON.stringify(result.getError()));
      } else {
        var data = JSON.parse(JSON.stringify(result.getReturnValue()));
        var flatData = this._flattenData(component, data);
        console.log('Flat Data:', flatData);
        component.set('v.objects', flatData);
      }
    });
    $A.enqueueAction(action);
  },

  // Build Select Statement for SOQL query
  _buildSelectStatement : function(component, field){
    var objectAPIName = field.objectAPIName;
    var selectFields = ['Id', 'Name'];

    if (objectAPIName == 'Contact'){
      selectFields.push('Receipt_Type__c', 'Account.Receipt_Type__c');
    }
    if (objectAPIName == 'Account'){
      selectFields.push('Is_Ongoing_Check_Donor__c','Receipt_Type__c', 'npe01__One2OneContact__r.Receipt_Type__c', 'Language_Preference__c');
    }
    if (objectAPIName == 'Campaign'){
      selectFields.push('Batch_Tool_Purpose_Code_Default__c', 'Batch_Tool_Purpose_Code_Default__r.Name', 'Batch_Tool_Purpose_Code_Default__r.Id', 'Batch_Tool_Purpose_Code_Default__r.Default_Fund_GL_Account__c', 'Batch_Tool_Purpose_Code_Default__r.Default_Fund_GL_Account__r.Name', 'Batch_Tool_Purpose_Code_Default__r.Default_Fund_GL_Account__r.Id');
    }
    if (objectAPIName == 'npsp__General_Accounting_Unit__c'){
      selectFields.push('Default_Fund_GL_Account__c', 'Default_Fund_GL_Account__r.Name', 'Default_Fund_GL_Account__r.Id');
    }

    for (let fld in field.lookupDialogs) {
      if (!selectFields.includes(field.lookupDialogs[fld].fieldPath)) {
        selectFields.push(field.lookupDialogs[fld].fieldPath);
      }
    }
    
    return selectFields;
  },

  _buildWhereClause: function(component, searchText, field){
    console.log('searchText:', searchText);
    // Set Variables
    var fld = '';
    var whereClause = field.lookupWhereClause;
    var startIndex;
    var endIndex;

    // Flatten the record so that we can use it like a map
    var record = JSON.parse(JSON.stringify(component.get('v.record')));
    if (record){
      record = this._flattenData(component, [record])[0];
    }

    // Pull WHERE clause from Form Field metadata settings
    if (field.lookupWhereClause) {
      for (let i = 0; i <= field.lookupWhereClause.length; i++) {
        if (!startIndex && field.lookupWhereClause[i] === '{') {
          fld = '';
          startIndex = i;
        } 
        else if (!endIndex && field.lookupWhereClause[i] === '}') {
          endIndex = i;
          fld = field.lookupWhereClause.substring(startIndex, endIndex + 1);
          console.log('fld:', fld);
          var actualField = fld.substring(1, fld.length - 1);
          console.log('actualField:', actualField);
          var value = record[actualField];
          console.log('value:', value);
          
          if (value) {
            whereClause = whereClause.replace(fld, value);
          } 
          else if (fld !== '{searchText}' && fld !== '{gauId}') {
            // Where clause invalid because we do not have the value to replace the field in the query
            var msg = 'Missing required field for search ' + fld;
            component.find('notifLib').showToast({
              variant: 'warning',
              message: msg
            });
            return;
          }
          fld = '';
          startIndex = null;
          endIndex = null;
        }
      }
      
      // Substitute SearchText and GauId into the WHERE Clause if needed
      whereClause = whereClause.split('{searchText}').join(searchText);
      if (whereClause.includes('{gauId}')){
        if (component.get('v.gauId') != "" && component.get('v.gauId') != null){
          whereClause = whereClause.split('{gauId}').join(component.get('v.gauId'));
        } else {
          component.find('notifLib').showToast({
            variant: 'error',
            message: 'A General Accounting Unit must be selected before the Fund GL Account.'
          });
          component.set('v.searchKey', null);
          return;        
        }
      }
    }
    return whereClause;
  },

  _buildQuery: function(component, queryField, searchText){
    // Build SELECT statement for query
    var selectFields = this._buildSelectStatement(component, queryField);
    // Get FROM object for query
    var fromObject = queryField.objectAPIName;
    // Build the WHERE clause for query
    var whereClause = this._buildWhereClause(component, searchText, queryField);
    // Get the ORDER BY for query
    var orderBy = queryField && queryField.lookupOrderBy ? queryField.lookupOrderBy : '';
    // Get the LIMIT for query
    var limit = queryField && queryField.maxNumberOfResultsDisplayed ? queryField.maxNumberOfResultsDisplayed : 20;
    // Construct Query as String;
    var query = fromObject + '(';
    query += selectFields.join(',');
    query += whereClause != null && whereClause != '' ? ' WHERE ' + whereClause : '';
    query += orderBy != null && orderBy != '' ? ' ORDER BY ' + orderBy : '';
    query += limit != null && limit != '' ? ' LIMIT ' + limit : '';
    query += ')';
    return query;
  },

  _flattenData: function (component, data) {
    console.log('\nCAND_BT_ListViewHelper._flattenData');

    for (let o in data) { // Loop through records
      this._traverseObject(data, o, data[o], '');
    }
    return this._buildObjectDetails(component, data);
  },

  _traverseObject: function (data, idx, obj, currentPath) {
    console.log('\nCAND_BT_ListViewHelper._traverseObject');
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

  _buildObjectDetails: function (component, resultRecords) {
    console.log('\nCAND_BT_LookupSearchHelper._buildObjectDetails');

    var btSettings = component.get('v.btSettings');

    if (btSettings && btSettings.form &&
      btSettings.form.formFieldMap &&
      btSettings.form.formFieldMap[component.get('v.fieldAPIName')] &&
      btSettings.form.formFieldMap[component.get('v.fieldAPIName')].isLookup) {
      // Build lookup dialog details
      var lookupDialogs = btSettings.form.formFieldMap[component.get('v.fieldAPIName')].lookupDialogs;

      for (let rec in resultRecords) {
        var record = resultRecords[rec];
        var fields = Object.keys(record);
        resultRecords[rec].Details = [];

        for (let field in lookupDialogs) {
          var dialog = lookupDialogs[field];
          var fieldPath = JSON.parse(JSON.stringify(dialog.fieldPath));
          if (dialog.lineNumber && resultRecords[rec].Details[dialog.lineNumber - 1] && record[dialog.fieldPath]) {
            resultRecords[rec].Details[dialog.lineNumber - 1] += ' ' + record[dialog.fieldPath];
          } else if (record[dialog.fieldPath]) {
            resultRecords[rec].Details.push(record[dialog.fieldPath]);
          }
        }
      }
    }
    $A.util.addClass(component.find('searchContainer'), 'slds-is-open');
    return resultRecords;
  }
})