({
    fetchDocumentTemplate: function(component) {
        return new Promise(function(resolve, reject) {
          var action = component.get('c.fetchDocumentTemplates');
           action.setParams({
              docTempId: component.get('v.recordId')
          });
          action.setCallback(this, (result) => {
            if (result.getState() === 'ERROR') {
                reject(result.getError());
            } else {
                var documentTemplates = result.getReturnValue();
                resolve(documentTemplates);
            }
          });
          $A.enqueueAction(action);
        }.bind(this));
    },

    fetchTemplateQueries: function(component) {
        return new Promise(function(resolve, reject) {
          var action = component.get('c.fetchTemplateQueries');
          action.setParams({
              docTempId: component.get('v.recordId')
          });
          action.setCallback(this, (result) => {
            if (result.getState() === 'ERROR') {
                reject(result.getError());
            } else {
                var templateQueries = result.getReturnValue();
                component.set('v.templateQueries', templateQueries);
                var aggregateQueries = [];
                for (var q in templateQueries) {
                    if (templateQueries[q].RecordType.Name === 'Primary SOQL Query') {
                        component.set('v.primarySOQLQuery', templateQueries[q].SOQL_Query__c);
                    } else {
                        aggregateQueries.push(templateQueries[q]);
                    }
                }
                component.set('v.aggregateQueries', aggregateQueries);
                resolve();
            }
          });
          $A.enqueueAction(action);
        }.bind(this));
    },

  fetchDefaultCSVConfig: function(component) {
    var docTemp = JSON.parse(JSON.stringify(component.get('v.documentTemplate')));
    return new Promise(function(resolve, reject) {
      var action = component.get('c.fetchDefaultCSVConfig');
      action.setParams({
         docTempId: docTemp.Id
      });
      action.setCallback(this, (res) => {
        if (res.getState() === 'ERROR') {
            reject(res.getError());
        } else {
          var result = res.getReturnValue();
          resolve(result);
        }
      });
      $A.enqueueAction(action);
     }.bind(this));
  },

  buildFieldSelectList: function(component, defaultCSVConfig) {
    var fieldSelectList = [{
        queryId: '',
        field: '--SELECT--',
        selectIndex: '',
        key: ''
    }];
    for (var i in defaultCSVConfig) {
        fieldSelectList.push(defaultCSVConfig[i]);
        if (defaultCSVConfig[i].subColumns && defaultCSVConfig[i].subColumns.length > 0) {
            for (var j in defaultCSVConfig[i].subColumns) {
                var subCol = defaultCSVConfig[i].subColumns[j];
                fieldSelectList.push(subCol);
            }
        }
    }
    component.set('v.fieldSelectList', fieldSelectList);
  },

   completeConfiguration: function(component, csvColumnConfig) {
        var columnNumber = 0;

        /*
            Iterate over the primary query column configs, subquery parent column configs,
            and aggregate parent column configs
        */
        for (var i in csvColumnConfig) {
            csvColumnConfig[i].index = i; // Index of the primary query column, subquery grouping, or aggregate grouping index
            csvColumnConfig[i].columnNum = columnNumber; // Actual column number in csv
            if (!csvColumnConfig[i].subColumns
                  || csvColumnConfig[i].subColumns === undefined
                  || csvColumnConfig[i].subColumns.length == 0
                  || !csvColumnConfig[i].numResults) {
                columnNumber++;

            } else if (csvColumnConfig[i].apiName === 'Aggregate' && csvColumnConfig[i].subColumns) {
                for (var j = 0; j < csvColumnConfig[i].subColumns.length; j++) {
                   csvColumnConfig[i].subColumns[j].index = j; // Sub column index
                    csvColumnConfig[i].subColumns[j].parentIndex = i; // Parent grouping's index
                    csvColumnConfig[i].subColumns[j].columnNum = columnNumber; // Actual column number in csv
                    columnNumber++;
                }

            } else if (csvColumnConfig[i].subColumns &&
                    (csvColumnConfig[i].apiName === 'Subquery' || csvColumnConfig[i].apiName === 'Secondary')) {
                // It's a subquery or aggregate parent column config
                var subColumnsCopy = JSON.parse(JSON.stringify(csvColumnConfig[i].subColumns));
                var numSubColumns = subColumnsCopy.length;
                var numResults = csvColumnConfig[i].numResults;
                var groupZeroSubqueryColumns = [];
                var newSubColumnArray = [];

                // Iterate over the child column configs
                for (var j = 0; j < csvColumnConfig[i].subColumns.length; j++) {
                    var subCol = csvColumnConfig[i].subColumns[j];
                    if (parseInt(subCol.groupingValue) >= numResults) {
                        break;
                    }

                    subCol.index = j; // Sub column index
                    subCol.parentIndex = i; // Parent grouping's index
                    subCol.columnNum = columnNumber; // Actual column number in csv
                    columnNumber++;

                    if (subCol.groupingValue
                        && subCol.groupingValue !== undefined
                        && parseInt(subCol.groupingValue) === 0) {
                            var subColCopy = JSON.parse(JSON.stringify(subCol));
                            groupZeroSubqueryColumns.push(subColCopy);
                    }
                    newSubColumnArray.push(subCol);
                }

                var lastGroupingValue = parseInt(subColumnsCopy[numSubColumns-1].groupingValue);
                var numToCreate = numResults - (lastGroupingValue+1);

                // Validate that we have all of the subcolumns and create any needed
                if (numToCreate > 0) {
                    // Create missing subcolumns
                    var lastIndex = newSubColumnArray.length-1;

                    for (var m = 0; m < numToCreate; m++) {
                        for (var n = 0; n < groupZeroSubqueryColumns.length; n++) {
                            var newCol = {};
                            Object.assign(newCol, groupZeroSubqueryColumns[n]);
                            newCol.index = lastIndex + 1;
                            newCol.columnNum = columnNumber;
                            newCol.groupingValue = lastGroupingValue + 1 + m;
                            if (newCol.label.indexOf('[0]') !== -1) {
                               newCol.label = newCol.label.replace('[0]', '['+ newCol.groupingValue + ']');
                               newCol.key = newCol.key.replace('[0]', '['+ newCol.groupingValue + ']');
                               newCol.apiName = newCol.apiName.replace('[0]', '['+ newCol.groupingValue + ']');
                            } else {
                               newCol.label = newCol.label + ' ' + newCol.groupingValue;
                            }
                            lastIndex++;
                            columnNumber++;
                            newSubColumnArray.push(newCol);
                        }
                    }
                }
                csvColumnConfig[i].subColumns = JSON.parse(JSON.stringify(newSubColumnArray));
            }
        }
        return csvColumnConfig;
    }
})