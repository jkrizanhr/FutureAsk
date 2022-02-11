({
  fetchDonationPageDataHelper : function(component, idParam) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var _fetchData = component.get("c.fetchDonationPageInformation");
      _fetchData.setParams({
        idParam: idParam
      });

      _fetchData.setCallback(this, function(res) {
        if(res.getState() === "ERROR") {
          reject(res.getError());
        } else {
          resolve(res.getReturnValue());
        }
      });
      $A.enqueueAction(_fetchData);
    }));
  },
  createDonationFormSubmissionHelper : function(component, submission) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var _submitDFS = component.get("c.createDonationFormSubmission");
      _submitDFS.setParams({
        submission: submission
      });

      _submitDFS.setCallback(this, function(res) {
        if(res.getState() === "ERROR") {
          reject(res.getError());
        } else {
          resolve(res.getReturnValue());
        }
      });
      $A.enqueueAction(_submitDFS);
    }));
  },
  getURLParamsHelper : function(){
    // Get the whole decoded URL of the page.
    // Split by & so the key value pairs are stored separately in a list
    var sPageURL = decodeURIComponent(window.location.search.substring(1)); 
    var sURLVariables = sPageURL.split('&'); 

    for (var i = 0; i < sURLVariables.length; i++) {
      // Split the key from the value
      var tempParamName = sURLVariables[i].split('='); 

      // Look for param name (oppId) return the value
      if (tempParamName[0] === 'oppId') { 
        return tempParamName[1] === undefined ? 'Not found' : tempParamName[1];
        break;
      }
      if (tempParamName[0] === 'gauId') { 
        return tempParamName[1] === undefined ? 'Not found' : tempParamName[1];
        break;
      }
    }
  },
  validateContactHelper : function(contact){
    if (
      contact.FirstName != null && contact.FirstName != "" &&
      contact.LastName != null && contact.LastName != "" &&
      contact.Email != null && contact.Email != "" &&
      contact.Phone != null && contact.Phone != "" &&
      contact.MailingStreet != null && contact.MailingStreet != "" &&
      contact.MailingCity != null && contact.MailingCity != "" &&
      contact.MailingState != null && contact.MailingState != "" &&
      contact.MailingPostalCode != null && contact.MailingPostalCode != "" &&
      contact.MailingCountry != null && contact.MailingCountry != ""
    ){
      return true;
    } else {
      return false;
    }
  },
  buildPaymentMethodListHelper : function(paymentMethods){
    var methods = [];
    for (var i=0; i < paymentMethods.length; i++){
      var pm = paymentMethods[i];
      if (pm.paymentMethod == 'Credit Card'){
        pm.label = pm.cardType
          ? pm.cardType + ' ' + pm.cardLastFour
          : 'Credit Card ' + pm.cardLastFour;
      } else {
        pm.label = 'EFT ' + pm.accountNumber;
      }
      methods.push(pm);
    }
    return methods;
  },
  handleProcessingFeesHelper : function(component, subtotal, fees){
    var exchangeRates = component.get('v.donationPageInfo').exchangeRates;
    var currency = component.get('v.currency');
    var exgRate;

    if (fees){
      switch(currency){
        case 'USD':
          exgRate = 1;
          break;
        case 'CAD':
          exgRate = exchangeRates.CAD / exchangeRates.USD;
          break;
        case 'EUR':
          exgRate = exchangeRates.EUR / exchangeRates.USD;
          break;
        case 'GBP':
          exgRate = exchangeRates.GBP / exchangeRates.USD;
          break;
        case 'INR':
          exgRate = exchangeRates.INR / exchangeRates.USD;
          break;
        case 'KES':
          exgRate = exchangeRates.KES / exchangeRates.USD;
          break;
      }
      subtotal = subtotal * exgRate * 100;
      var total = fees
        ? parseInt((subtotal + ((subtotal * .029)/.971)+30.9)) / 100
        : parseInt(subtotal) / 100;
      total = total / exgRate;
      component.set('v.total', total);
    } 
    
    else {
      component.set('v.total', subtotal);
    }
  }
})