({
  doInit: function(component, event, helper) {
    component.set('v.shouldShowSpinner', true);
    if (component.get('v.inTemplatePreviewTestMode') && component.get('v.recordId')) {
      helper.handlePreviewInit(component, helper);
    } else if (component.get('v.recordId')) {
      helper.handleOneOffInit(component, helper);
    } else {
      helper.handleBulkInit(component, helper);
    }
  },

  onchangeDocumentTemplate: function(component, event, helper) {
    console.log('onchangeDocumentTemplate');

    let selectedDocumentTemplateId = component.get('v.selectedDocumentTemplateId');
    console.log('selectedDocumentTemplateId =', selectedDocumentTemplateId);

    if (!selectedDocumentTemplateId || selectedDocumentTemplateId === '[object Object]') {
      component.set('v.documentTemplate', {});
      console.log('Returning because there is no Document Template Id!');
      return;
    }

    helper.handleSelectedDocumentTemplate(component, selectedDocumentTemplateId);

    component.set('v.shouldShowSpinner', true);
    helper.fetchDocumentTemplateQueries(component)
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
        console.log(err);
        component.set('v.shouldShowSpinner', false);
        alert(err);
      }));
  },

  onchangeDeliveryOption: function(component, event, helper) {
    helper.handleShowIsTestMode(component, component.get('v.deliveryOptionSelect'));
  },

  onchangeTestModeCheckbox: function(component, event, helper) {
    component.set('v.isTestMode', !component.get('v.isTestMode'));
  },

  generateDocument: function(component, event, helper) {
    let submissionType = event.getSource().get('v.value');

    helper.buildQuestionMap(component);

    let deliveryOptionSelect = component.get('v.deliveryOptionSelect');

    let docTemp = component.get('v.documentTemplate');
    let isOneOff = component.get('v.isOneOff') ?
      component.get('v.isOneOff') :
      false;

    let validDeliveryOption = true;

    if (!deliveryOptionSelect || deliveryOptionSelect === '--SELECT--') {
      component.find('notifLib').showToast({
        variant: 'error',
        message: 'Delivery option required!'
      });
      validDeliveryOption = false;
    }

    // Ensure that all of the questions have been answered
    let allQuestionsAnswered = helper.verifyAllQuestionsAnswered(component, docTemp);

    if (allQuestionsAnswered && validDeliveryOption) {
      // Ensure that at least 1 record is returned from the primary soql query
      component.set('v.shouldShowSpinner', true);

      helper.validatePrimaryQueryResults(component)
        .then($A.getCallback(function(validationResults) {
          component.set('v.shouldShowSpinner', false);

          let primaryQueryIsValid = helper.handleValidationResults(component, validationResults, submissionType);

          if (submissionType && submissionType === 'generate' && primaryQueryIsValid) {
            if (isOneOff && deliveryOptionSelect === 'PDF - Direct Download') {
              helper.generateSinglePDFDocument(component);
              // NOTE: Not needed to support email delivery options
            } else if (isOneOff && deliveryOptionSelect && deliveryOptionSelect.indexOf('Email') !== -1) {
              helper.emailSingleDocument(component);
            } else if (!isOneOff) {
              helper.generateMassDocuments(component);
            }
          }
        }))
        .catch($A.getCallback(function(err) {
          console.log(err);
          component.set('v.shouldShowSpinner', false);
          alert(err);
        }));
    } else {
      component.find('notifLib').showToast({
        variant: 'error',
        message: 'Please answer all questions before generating the document(s)!'
      });
    }
  },

  toggleAdvanced: function(component, event, helper) {
    component.set('v.showAdvanced', !component.get('v.showAdvanced'));
  }
})