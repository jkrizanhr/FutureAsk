({
  doInit: function(component, event, helper) {

    component.set('v.shouldShowSpinner', true);
    helper.fetchDocumentTemplate(component)
        .then($A.getCallback(function(documentTemplates) {
            if (documentTemplates && documentTemplates.length > 0) {
                component.set('v.documentTemplate', documentTemplates[0]);
                if (documentTemplates[0].CSV_Columns__c) {
                    var csvColumnConfig = JSON.parse(documentTemplates[0].CSV_Columns__c);
                    for (var i in csvColumnConfig) {
                        if (csvColumnConfig[i].apiName === 'Subquery' && csvColumnConfig[i].subColumns) {
                            var subColumns = [];
                            for (var j in csvColumnConfig[i].subColumns) {
                                 if (csvColumnConfig[i].subColumns[j].groupingValue && parseInt(csvColumnConfig[i].subColumns[j].groupingValue) === 0) {
                                     subColumns.push(JSON.parse(JSON.stringify(csvColumnConfig[i].subColumns[j])));
                                 }
                            }
                            csvColumnConfig[i].subColumns = JSON.parse(JSON.stringify(subColumns));
                        }
                    }
                    component.set('v.csvColumnConfig', csvColumnConfig);
                }
            }
            return helper.fetchTemplateQueries(component);
        }))
        .then($A.getCallback(function() {
            return helper.fetchDefaultCSVConfig(component);
        }))
        .then($A.getCallback(function(defaultCSVConfig) {
            component.set('v.defaultCSVConfig', defaultCSVConfig);
            helper.buildFieldSelectList(component, defaultCSVConfig);
            component.set('v.shouldShowSpinner', false);
        }))
        .catch($A.getCallback(function(err) {
            component.set('v.shouldShowSpinner', false);
            console.log(err);
        }));
  },

  onchangeSObject: function(component, event, helper) {
    component.set('v.primarySOQLQuery', 'SELECT Id\nFROM ' + component.get('v.selectedSObject'));
  },

  onclickAddAggregateQuery: function(component, event, helper) {
    var aggregateQueries = component.get('v.aggregateQueries');
    aggregateQueries.push('SELECT\nFROM');
    component.set('v.aggregateQueries', aggregateQueries);
  },

   onClickRemoveQuery: function(component, event, helper) {
    var index = event.getSource().get('v.value');
    var aggregateQueries = component.get('v.aggregateQueries');
    aggregateQueries.splice(index, 1);
    component.set('v.aggregateQueries', aggregateQueries);
  },

  saveDocumentTemplate: function(component, event, helper) {
    var docTemp = component.get('v.documentTemplate');
    var csvColumnConfig = component.get('v.csvColumnConfig');
    var completeConfigResult = helper.completeConfiguration(component, csvColumnConfig);
    docTemp.CSV_Columns__c = JSON.stringify(completeConfigResult);
    var docTempJSON = JSON.stringify(docTemp);

    var action = component.get('c.updateDocumentTemplate');
    action.setParams({
        templateJSON: docTempJSON
    });
     component.set('v.shouldShowSpinner', true);
      action.setCallback(this, (result) => {
        component.set('v.shouldShowSpinner', false);

        if (result.getState() === 'ERROR') {
            alert(JSON.stringify(result.getError()));
        } else {
            console.log('res: ', result.getReturnValue());
        }
      });
      $A.enqueueAction(action);
  },

  // Automatically populate the value based on the queried fields
  automateColumns: function(component, event, helper) {
      component.set('v.shouldShowSpinner', true);
      helper.fetchDefaultCSVConfig(component)
          .then($A.getCallback(function(csvConfig) {
              component.set('v.csvColumnConfig', JSON.parse(JSON.stringify(csvConfig)));
              component.set('v.defaultCSVConfig', JSON.parse(JSON.stringify(csvConfig)));
              component.set('v.shouldShowSpinner', false);
          }))
          .catch($A.getCallback(function(err) {
            component.set('v.shouldShowSpinner', false);
            console.log(err);
          }));
  }
})