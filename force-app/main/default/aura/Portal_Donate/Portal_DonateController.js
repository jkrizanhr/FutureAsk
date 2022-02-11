({
  doInit : function(component, event, helper) {
    // Close Modal if coming from refresh event
    component.set('v.showModal', false); 
    component.set('v.isLoading', true);
    
    //Get OppId from URL to see if "Donate Again"
    var idParam = helper.getURLParamsHelper(); 
    component.set('v.date', new Date().toISOString().slice(0, 10));
    
    // Use OppId to pull DonationPageInfo from Salesforce
    helper.fetchDonationPageDataHelper(component, idParam)
    .then($A.getCallback(function(results) {
      component.set('v.donationPageInfo', results);
      component.set('v.paymentMethods', helper.buildPaymentMethodListHelper(results.paymentMethods));
      component.set('v.contactValid', helper.validateContactHelper(results.contact));
      component.set('v.processingFees', results.processingFees);
      if (results.previousOpp != null){
        component.set('v.currency', results.previousOpp.Original_Currency__c);
        component.set('v.subtotal', results.previousOpp.Original_Amount__c);
        component.set('v.total', results.previousOpp.Original_Amount__c);
      } else {
        component.set('v.subtotal', 0);
        component.set('v.total', 0);
      }
      component.set('v.isLoading', false);
    }));
  },
  goToMyProfilePage : function(component, event, helper){
    location.href = '/s/profile/home';
  },
  toggleModal : function(component, event, helper){
    var modal = component.get('v.title');
    if (modal != 'Action Required'){
      $A.get('e.force:refreshView').fire();
    } else {
      component.set('v.showModal', !component.get('v.showModal'));
    }
  },
  calculateTotal : function(component, event, helper){
    var funds = component.get('v.donationPageInfo').selectedFunds;
    var subtotal = 0;
    for (var i=0; i < funds.length; i++){
      subtotal = Number(subtotal) + Number(funds[i].amount);
    }
    component.set('v.subtotal', subtotal);
    var fees = component.find('processingFees').get('v.checked');
    if (subtotal > 0){
      helper.handleProcessingFeesHelper(component, subtotal, fees);
    } else {
      component.set('v.total', 0);
    }
  },
  handleSubmit : function(component, event, helper){
    // Is Processing set to true
    component.set('v.processing', true);
    // Get Start Date
    var startDate = component.get('v.date') != null
      ? component.get('v.date').toString()
      : `${today.getFullYear()}-${(today.getMonth() + 1).toString().padStart(2, "0")}-${today.getDate().toString().padStart(2, "0")}`;
    // Get Payment Method
    var pmId = component.find('pm').get('v.value');
    var methods = component.get('v.paymentMethods');
    var pm = null;
    for (var i=0; i < methods.length; i++){
      if (methods[i].id == pmId){
        pm = methods[i];
        break;
      }
    }
    // Get initial donation page info
    var dpi = component.get('v.donationPageInfo');
    // Build Submission
    var submission = {
      contact: dpi.contact,
      coverFees: component.find('processingFees').get('v.checked'),
      subtotal: component.get('v.subtotal'),
      total: component.get('v.total'),
      frequency: component.get('v.freq'),
      currencyType: component.get('v.currency'),
      startDate: startDate,
      selectedFunds: dpi.selectedFunds,
      paymentMethod: pm
    };
    submission = JSON.stringify(submission);
    helper.createDonationFormSubmissionHelper(component, submission)
    .then($A.getCallback(function(results) {
      // Error: Show Toast and Stop Spinner
      if (results.Errors__c != null && results.Errors__c != ""){          
        component.set('v.title', 'Action Required');
        component.set('v.message', results.Errors__c);
      } 
      // Success: Show Toast and Refresh Component
      else {
        component.set('v.title', 'Success');
        component.set('v.message', 'Your donation has been received successfully.');  
      }
      // Then: Stop Processing, Show Modal
      component.set('v.showModal', true);
      component.set('v.processing', false);  
    }));
  }
})