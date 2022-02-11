({
  /** Document Template Preview:
   * Fetch Document Templates
   * Set the selected document template id since we are on the document template record page
   * Set the delivery options
   * Fetch Document Template Queries
   * Assign Document Template Queries
   * Fetch Document Template Questions
   * Fetch Document Template Question Options
   * Build Question Option Map
   * Stop Loading Spinner
   */
  handlePreviewInit: function(component, helper) {
    helper.fetchDocumentTemplates(component)
      .then($A.getCallback(function(documentTemplates) {
        component.set('v.documentTemplates', documentTemplates);
        helper.handleSelectedDocumentTemplate(component, component.get('v.selectedDocumentTemplateId'));
        return helper.fetchDocumentTemplateQueries(component);
      }))
      .then($A.getCallback(function(queries) {
        helper.assignDocumentTemplateQueries(component, queries);
        return helper.fetchDocumentTemplateQuestions(component);
      }))
      .then($A.getCallback(function(questions) {
        component.set('v.documentTemplate.Document_Template_Questions__r', questions);
        return helper.fetchDocumentTemplateQuestionOptions(component);
      }))
      .then($A.getCallback(function(questionOptions) {
        component.set('v.documentTemplate.Document_Template_Question_Options__r', questionOptions);
        helper.buildQuestionOptionMap(component);
        component.set('v.shouldShowSpinner', false);
      }))
      .catch($A.getCallback(function(err) {
        component.set('v.shouldShowSpinner', false);
        alert(err);
      }));
  },

  /** One-off Document Generation
   * Fetch Document Templates
   * Assign Document Template options
   * Stop Loading Spinner
   */
  handleOneOffInit: function(component, helper) {
    component.set('v.isOneOff', true);
    helper.fetchDocumentTemplates(component)
      .then($A.getCallback(function(documentTemplates) {
        let documentTemplateSelect = helper.assignDocumentTemplates(component, documentTemplates);
        helper.setPicklistOptions(component, 'documentTemplateSelect', documentTemplateSelect);
        component.set('v.shouldShowSpinner', false);
        if (component.get('v.selectedDocumentTemplateId') != null) {
          var a = component.get('c.onchangeDocumentTemplate');
          $A.enqueueAction(a);
        }
      }))
      .catch($A.getCallback(function(err) {
        component.set('v.shouldShowSpinner', false);
        alert(err);
      }));
  },

  /** Bulk Document Generation
   * Fetch Document Templates
   * Assign Document Template options
   * Stop Loading Spinner
   */
  handleBulkInit: function(component, helper) {
    helper.fetchDocumentTemplates(component)
      .then($A.getCallback(function(documentTemplates) {
        let documentTemplateSelect = helper.assignDocumentTemplates(component, documentTemplates);
        helper.setPicklistOptions(component, 'documentTemplateSelect', documentTemplateSelect);
        component.set('v.shouldShowSpinner', false);
        if (component.get('v.selectedDocumentTemplateId') != null) {
          var a = component.get('c.onchangeDocumentTemplate');
          $A.enqueueAction(a);
        }
      }))
      .catch($A.getCallback(function(err) {
        component.set('v.shouldShowSpinner', false);
        alert(err);
      }));
  },

  setPicklistOptions: function(component, auraId, values) {
    let selectCmp = component.find(auraId);
    if (!selectCmp) {
      return;
    }
    let selectedDocumentTemplateId = component.get('v.selectedDocumentTemplateId');
    selectCmp.set('v.body', []);
    let selectBody = selectCmp.get('v.body');
    values.forEach((val) => {
      let option = {
        value: val.Id ? val.Id : val,
        text: val.Name ? val.Name : val
      };

      if (values[0] === val 
          && (!selectedDocumentTemplateId || auraId !== 'documentTemplateSelect')) {
        // Default to the first picklist option
        option.selected = true;       
      } else if (auraId === 'documentTemplateSelect'
          && selectedDocumentTemplateId != null 
          && val.Id === selectedDocumentTemplateId) {
        option.selected = true;       
      } else if (component.get('v.isOneOff') 
          && auraId === 'deliveryOptionSelect' 
          && val === 'PDF - Direct Download') {
        option.selected = true;
      }
      
      if (option.selected && auraId === 'deliveryOptionSelect') {
        component.set('v.deliveryOptionSelect', val);
      }

      console.log('option = ', option);
      $A.createComponent(
        'aura:html', {
          tag: 'option',
          HTMLAttributes: option
        }, (newOption) => {
          if (selectCmp.isValid()) {
            selectBody.push(newOption);
            selectCmp.set('v.body', selectBody);
          }
        }
      );
    });
  },

  fetchDocumentTemplates: function(component) {
    console.log('fetchDocumentTemplates');
    return new Promise(function(resolve, reject) {
      let action = component.get('c.fetchDocumentTemplates');
      action.setParams({
        sObjectName: component.get('v.sObjectName'),
        isOneOff: component.get('v.recordId') != null ? true : false
      });
      action.setCallback(this, (result) => {
        if (result.getState() === 'ERROR') {
          reject(JSON.stringify(result.getError()));
        } else {
          console.log('check');
          console.log(result.getReturnValue());
          resolve(result.getReturnValue());
        }
      });
      $A.enqueueAction(action);
    }.bind(this));
  },

  assignDocumentTemplates: function(component, documentTemplates) {
    component.set('v.documentTemplates', documentTemplates);

    if (!documentTemplates || documentTemplates.length === 0) {
      component.set('v.message', 'No document template available.');
    }

    let documentTemplateSelect = [];
    // documentTemplateSelect.push({
    //   Id: '',
    //   Name: '--SELECT--'
    // });
    for (let r in documentTemplates) {
      // console.log(documentTemplates[r]);
      if (!documentTemplates[r].Delivery_Options__c) {
        continue;
      }

      if (component.get('v.isOneOff') && documentTemplates[r].Delivery_Options__c.indexOf('PDF') === -1) {
        continue;
      }

      documentTemplateSelect.push({
        Id: documentTemplates[r].Id,
        Name: documentTemplates[r].Name
      });

      if (documentTemplates[r].Is_Default__c) {
        component.set('v.selectedDocumentTemplateId', documentTemplates[r].Id);
        component.set('v.documentTemplate', documentTemplates[r]);
      }
    }

    if (!component.get('v.selectedDocumentTemplateId')) {
      let defaultTemplateSelection = {
        Id: '',
        Name: '--SELECT--'
      };
      documentTemplateSelect.unshift(defaultTemplateSelection);
    }
    console.log(documentTemplateSelect);
    return documentTemplateSelect;
  },

  handleSelectedDocumentTemplate: function(component, selectedDocumentTemplateId) {
    // Set the document template
    let documentTemplates = component.get('v.documentTemplates');
    for (let i in documentTemplates) {
      if (selectedDocumentTemplateId === documentTemplates[i].Id) {
        component.set('v.documentTemplate', documentTemplates[i]);
        break;
      }
    }

    if (!component.get('v.documentTemplate')) {
      console.log('ERROR: No Document Template!');
      return;
    }

    // Set the delivery options
    let deliveryOptionValues = this.setDeliveryOptions(component);
    this.setPicklistOptions(component, 'deliveryOptionSelect', deliveryOptionValues);

    if (component.get('v.isOneOff') && deliveryOptionValues.indexOf('PDF - Direct Download') !== -1) {
      this.handleShowIsTestMode(component, 'PDF - Direct Download');
    } else {
      this.handleShowIsTestMode(component, deliveryOptionValues[0]);
    }
  },

  setDeliveryOptions: function(component) {
    console.log('setDeliveryOptions');
    let deliveryOptionValues = [];
    let docTemp = component.get('v.documentTemplate');
    if (docTemp.Delivery_Options__c && docTemp.Delivery_Options__c !== 'undefined') {
      deliveryOptionValues = docTemp.Delivery_Options__c.split(';')
    }

    console.log('deliveryOptionValues =', deliveryOptionValues);

    // Don't allow CSV - Direct Download for one-off document generation
    if (component.get('v.isOneOff') && deliveryOptionValues.indexOf('CSV - Direct Download') !== -1) {
      deliveryOptionValues.splice(deliveryOptionValues.indexOf('CSV - Direct Download'), 1);
    }
    // Don't allow CSV - Email for one-off document generation
    if (component.get('v.isOneOff') && deliveryOptionValues.indexOf('CSV - Email') !== -1) {
      deliveryOptionValues.splice(deliveryOptionValues.indexOf('CSV - Email'), 1);
    }

    if (!docTemp.Visualforce_Page__c) {
      if (deliveryOptionValues.indexOf('PDF - Email') !== -1) {
        console.log('No visualforce page, so we are removing the PDF - Email delivery option');
        deliveryOptionValues.splice(deliveryOptionValues.indexOf('PDF - Email'), 1);
      }
      if (deliveryOptionValues.indexOf('PDF - Direct Download') !== -1) {
        console.log('No visualforce page, so we are removing the PDF - Direct Download delivery option');
        deliveryOptionValues.splice(deliveryOptionValues.indexOf('PDF - Direct Download'), 1);
      }
    }
    console.log('returning deliveryOptionValues =', deliveryOptionValues);
    return deliveryOptionValues;
  },

  handleShowIsTestMode: function(component, selectedDeliveryOption) {
    let documentTemplate = component.get('v.documentTemplate');
    let showIsTestMode = false;

    if (documentTemplate &&
      documentTemplate.Document_Post_Generation_Methods__r &&
      documentTemplate.Document_Post_Generation_Methods__r.length > 0) {
      for (let i in documentTemplate.Document_Post_Generation_Methods__r) {
        let deliveryOptionString = documentTemplate.Document_Post_Generation_Methods__r[i].Delivery_Options__c;
        if (deliveryOptionString != null) {
          let deliveryOptions = deliveryOptionString.split(';');
          for (let j in deliveryOptions) {
            if (deliveryOptions[j] === selectedDeliveryOption) {
              showIsTestMode = true;
              break;
            }
          }
        }
      }
    }
    component.set('v.showIsTestMode', showIsTestMode);
  },

  fetchDocumentTemplateQueries: function(component) {
    return new Promise(function(resolve, reject) {
      let action = component.get('c.fetchTemplateQueries');
      action.setParams({
        docTempId: component.get('v.selectedDocumentTemplateId')
      });
      action.setCallback(this, (result) => {
        if (result.getState() === 'ERROR') {
          reject(JSON.stringify(result.getError()));
        } else {
          resolve(result.getReturnValue());
        }
      });
      $A.enqueueAction(action);
    }.bind(this));
  },

  assignDocumentTemplateQueries: function(component, queries) {
    component.set('v.primarySOQLQuery', null);
    let aggregateQueries = [];
    let customMetadataQueries = [];
    let secondaryQueries = [];
    let aggregateQueryDisplayList = [];
    let customMetadataQueryDisplayList = [];
    let secondaryQueryDisplayList = [];

    for (let q in queries) {
      if (!queries[q].RecordType || !queries[q].RecordType.Name) {
        continue;
      }
      if (queries[q].RecordType.Name === 'Primary SOQL Query') {
        component.set('v.primarySOQLQuery', queries[q].SOQL_Query__c);
      } else if (queries[q].RecordType.Name === 'Custom Metadata SOQL Query') {
        customMetadataQueries.push(queries[q].SOQL_Query__c);
        customMetadataQueryDisplayList.push(false);
      } else if (queries[q].RecordType.Name === 'Secondary SOQL Query') {
        secondaryQueries.push(queries[q].SOQL_Query__c);
        secondaryQueryDisplayList.push(false);
      } else if (queries[q].RecordType.Name === 'Aggregate SOQL Query') {
        aggregateQueries.push(queries[q].SOQL_Query__c);
        aggregateQueryDisplayList.push(false);
      }
    }

    component.set('v.aggregateQueryDisplayList', aggregateQueryDisplayList);
    component.set('v.customMetadataQueryDisplayList', customMetadataQueryDisplayList);
    component.set('v.secondaryQueryDisplayList', secondaryQueryDisplayList);
    component.set('v.customMetadataQueries', customMetadataQueries);
    component.set('v.secondaryQueries', secondaryQueries);
    component.set('v.aggregateQueries', aggregateQueries);
  },

  fetchDocumentTemplateQuestions: function(component) {
    return new Promise(function(resolve, reject) {
      let action = component.get('c.fetchQuestions');
      action.setParams({
        docTempId: component.get('v.selectedDocumentTemplateId'),
        isOneOff: component.get('v.isOneOff')
      });
      action.setCallback(this, (result) => {
        if (result.getState() === 'ERROR') {
          reject(JSON.stringify(result.getError()));
        } else {
          let results = result.getReturnValue();
          resolve(results);
        }
      });
      $A.enqueueAction(action);
    }.bind(this));
  },

  fetchDocumentTemplateQuestionOptions: function(component) {
    return new Promise(function(resolve, reject) {
      let action = component.get('c.fetchQuestionOptions');
      action.setParams({
        docTempId: component.get('v.selectedDocumentTemplateId'),
        isOneOff: component.get('v.isOneOff')
      });
      action.setCallback(this, (result) => {
        if (result.getState() === 'ERROR') {
          reject(JSON.stringify(result.getError()));
        } else {
          let results = result.getReturnValue();
          resolve(results);
        }
      });
      $A.enqueueAction(action);
    }.bind(this));
  },

  // Create a map of the questions and their answer options
  buildQuestionOptionMap: function(component) {
    let template = component.get('v.documentTemplate');
    let optionMap = {};
    let defaultAnswerMap = {};

    if (template.Document_Template_Questions__r != null &&
      template.Document_Template_Question_Options__r != null) {
      for (let i in template.Document_Template_Question_Options__r) {
        let option = template.Document_Template_Question_Options__r[i];
        if (!optionMap[option.Document_Template_Question__c]) {
          optionMap[option.Document_Template_Question__c] = [];
          // Set the first option found as the default answer
          defaultAnswerMap[option.Document_Template_Question__c] = option;
        }
        // If option.Default_Option__c = true, then let's override that as the default answer
        if (option.Default_Option__c) {
          defaultAnswerMap[option.Document_Template_Question__c] = option;
        }
        optionMap[option.Document_Template_Question__c].push(option);
      }

      let questions = template.Document_Template_Questions__r;
      for (let i in questions) {
        if (optionMap[questions[i].Id]) {
          if (defaultAnswerMap[questions[i].Id].Default_Option__c === false) {
            let opt = {
              Name: '--SELECT--',
              Option_Value__c: '',
              Default_Option__c: false,
              Document_Template_Question__c: questions[i].Id
            };
            defaultAnswerMap[questions[i].Id] = '';
            optionMap[questions[i].Id].unshift(opt);
          }
          questions[i].answer = defaultAnswerMap[questions[i].Id].Option_Value__c;
          questions[i].Document_Template_Question_Options__r = optionMap[questions[i].Id];
        }
      }
      component.set('v.documentTemplate.Document_Template_Questions__r', questions);
    }
  },

  verifyAllQuestionsAnswered: function(component, template) {
    let allQuestionsAnswered = true;
    if (template && template.Document_Template_Questions__r) {
      let questions = template.Document_Template_Questions__r;
      for (let i in questions) {
        if (!questions[i].answer && questions[i].Is_Required__c) {
          allQuestionsAnswered = false;
        }
      }
    }

    console.log('All questions answered? ', allQuestionsAnswered);
    return allQuestionsAnswered;
  },

  buildQuestionMap: function(component) {
    let template = component.get('v.documentTemplate');
    let questionAnswerMap = {};

    if (template && template.Document_Template_Questions__r != null) {
      let questions = template.Document_Template_Questions__r;
      for (let i in questions) {
        questionAnswerMap[questions[i].Id] = questions[i].answer;
      }
    }
    component.set('v.questionAnswerMap', questionAnswerMap);
  },

  validatePrimaryQueryResults: function(component) {
    return new Promise(function(resolve, reject) {
      let documentTemplate = component.get('v.documentTemplate');
      let params = {
        isTestMode: component.get('v.isTestMode'),
        deliveryOption: component.get('v.deliveryOptionSelect'),
        questionAnswerMapJSON: JSON.stringify(component.get('v.questionAnswerMap')),
        recordId: component.get('v.recordId'),
        templateId: documentTemplate.Id
      };

      let action = component.get('c.validatePrimaryQuery');
      action.setParams({
        paramModelJSON: JSON.stringify(params)
      });
      action.setCallback(this, (result) => {
        if (result.getState() === 'ERROR' || !result.getReturnValue()) {
          reject(JSON.stringify(result.getError()));
        } else if (result.getReturnValue()) {
          resolve(result.getReturnValue());
        } else {
          reject('Failed to validate primary query!');
        }
      });
      $A.enqueueAction(action);
    }.bind(this));
  },

  handleValidationResults: function(component, validationResults, submissionType) {
    // If no results from the server or from the query then
    // toast an error message and display the primary query.
    let pqValidator = JSON.parse(validationResults);

    if (pqValidator && pqValidator.isValid == false && pqValidator.primaryQueryString != null) {
      component.find('notifLib').showNotice({
        variant: 'warning',
        header: 'Attention!',
        title: pqValidator.statusMessage,
        message: '\r\nPrimary SOQL Query:\r\n\r\n' + pqValidator.primaryQueryString
      });
      return false;
    } else if (pqValidator && pqValidator.isValid == true) {
      if (submissionType === 'validate') {
        component.find('notifLib').showNotice({
          variant: 'info',
          header: 'Validation Successful!',
          title: 'Successfully validated primary query!',
          message: '\r\nPrimary SOQL Query:\r\n\r\n' + pqValidator.primaryQueryString +
            '\r\n\r\nSelect Count Query:\r\n\r\n' + pqValidator.selectCountQueryString +
            '\r\n\r\nCount: ' + pqValidator.count
        });
      }
      return true;
    }

    component.find('notifLib').showNotice({
      variant: 'error',
      header: 'Error!',
      message: 'Error validating primary query!'
    });
    return isValid;
  },

  generateSinglePDFDocument: function(component) {
    let isTestMode = component.get('v.isTestMode');
    let documentTemplate = component.get('v.documentTemplate');
    let selectedDocumentTemplateId = '';
    let page = '';
    let inTemplatePreviewTestMode = component.get('v.inTemplatePreviewTestMode');

    if (documentTemplate) {
      selectedDocumentTemplateId = documentTemplate.Id;
      page = documentTemplate.Visualforce_Page__c;
    }

    let questionAnswerMap = component.get('v.questionAnswerMap');
    let urlArr = [
      '/apex/',
      page,
      '?',
      'recordIds=',
      component.get('v.recordId'),
      '&templateId=',
      selectedDocumentTemplateId,
      '&deliveryOption=PDF - Direct Download'
    ];

    if (documentTemplate.Attach_PDF_to_Primary_Record__c) {
      urlArr.push('&attachFile=true');
    }

    if (isTestMode) {
      urlArr.push('&isTestMode=' + isTestMode);
    }

    let questionMap = {};
    for (let q in documentTemplate.Document_Template_Questions__r) {
      let index = documentTemplate.Document_Template_Questions__r[q].Id;
      questionMap[index] = documentTemplate.Document_Template_Questions__r[q];
    }

    // Add the questionAnswerMap to the URL
    for (let i in questionAnswerMap) {
      if (questionAnswerMap[i] === undefined) {
        continue;
      }

      urlArr.push('&' + i + '=' + questionAnswerMap[i]);

      if (questionMap[i].URL_Parameter__c && questionMap[i].URL_Parameter__c !== undefined) {
        urlArr.push('&' + questionMap[i].URL_Parameter__c + '=' + questionAnswerMap[i].toLowerCase());
      }
    }

    console.log(urlArr);

    let urlString = urlArr.join('');
    if (inTemplatePreviewTestMode) {
      let generateDocPreviewEvent = component.getEvent('generateDocumentPreview');
      generateDocPreviewEvent.setParams({
        previewUrl: urlString
      }).fire();
    } else {
      window.open(urlString);
    }
  },

  emailSingleDocument: function(component) {
    console.log('\nDocumentGeneratorHelper.emailSingleDocument');
    let isTestMode = component.get('v.isTestMode');
    console.log('isTestMode: ', isTestMode);
    let documentTemplate = component.get('v.documentTemplate');
    console.log('documentTemplate: ', documentTemplate);
    let questionAnswerMap = component.get('v.questionAnswerMap');
    console.log('questionAnswerMap: ', questionAnswerMap);

    let paramModel = {
      isTestMode: isTestMode,
      deliveryOption: component.get('v.deliveryOptionSelect'),
      questionAnswerMapJSON: JSON.stringify(questionAnswerMap),
      recordId: component.get('v.recordId'),
      templateId: documentTemplate.Id
    };

    let action = component.get('c.initSingleDocumentEmail');
    action.setParams({
      paramModelJSON: JSON.stringify(paramModel)
    });

    component.set('v.shouldShowSpinner', true);
    action.setCallback(this, (result) => {
      component.set('v.shouldShowSpinner', false);

      if (result.getState() === 'ERROR') {
        alert('Error generating documents: ' + JSON.stringify(result.getError()));
      } else {
        console.log('Successfully generating documents');
        let results = result.getReturnValue();
        console.log(results);
        component.find('notifLib').showToast({
          title: 'Success!',
          variant: 'success',
          message: 'Successfully generating documents!'
        });
      }
    });
    $A.enqueueAction(action);
  },

  generateMassDocuments: function(component) {
    let questionAnswerMap = component.get('v.questionAnswerMap');

    let paramModel = {
      isTestMode: component.get('v.isTestMode'),
      deliveryOption: component.get('v.deliveryOptionSelect'),
      questionAnswerMapJSON: JSON.stringify(questionAnswerMap),
      templateId: component.get('v.documentTemplate').Id
    };

    let action = component.get('c.processMassDocuments');
    action.setParams({
      paramModelJSON: JSON.stringify(paramModel)
    });

    component.set('v.shouldShowSpinner', true);
    action.setCallback(this, (result) => {
      component.set('v.shouldShowSpinner', false);

      if (result.getState() === 'ERROR') {
        alert('Error generating documents: ' + JSON.stringify(result.getError()));
      } else {
        component.set('v.jobInProgress', true);
        component.find('docGenJobs').init();
        component.find('notifLib').showToast({
          variant: 'successs',
          message: 'Generating documents!'
        });
      }
    });
    $A.enqueueAction(action);
  }
})