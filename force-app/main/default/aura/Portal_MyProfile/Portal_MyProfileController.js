({
  init: function (component, event, helper) {
    helper.fetchDataHelper(component)
      .then($A.getCallback(function(results) {
        if (!results.MailingCountry){
          results.MailingCountry = 'United States';
        }
        if (results.MailingCountry == 'United States' && results.MailingState){
          component.set('v.state', results.MailingState);
        }
        component.set('v.contact', results);
        component.set('v.country', results.MailingCountry);
        helper.setPhoneFieldHelper(component, results.PreferredPhone);
        helper.setEmailFieldHelper(component, results.PreferredEmail);
      }));
    helper.fetchPicklistDataHelper(component)
      .then($A.getCallback(function(results) {
        // Override standard picklist values since we're not using all the values
        results.npe01__PreferredPhone__c.picklistValues = [
          {label: 'Home', value: 'Home'},
          {label: 'Work', value: 'Work'},
          {label: 'Mobile', value: 'Mobile'}
        ];
        results.npe01__Preferred_Email__c.picklistValues = [
          {label: 'Personal', value: 'Personal'},
          {label: 'Work', value: 'Work'},
          {label: 'Alternate', value: 'Alternate'}
        ];
        component.set('v.picklists', results);
        component.set('v.states', helper.getStatesHelper());
        component.set('v.countries', helper.getCountriesHelper());
        component.set('v.isLoading', false);
      }));
  },
  setPhoneField : function(component, event, helper){
    var phoneType = event.getSource().get('v.value');
    helper.setPhoneFieldHelper(component, phoneType);
  },
  setEmailField : function(component, event, helper){
    var emailType = event.getSource().get('v.value');
    helper.setEmailFieldHelper(component, emailType);
  },
  updateState : function(component, event, helper){
    var contact = component.get('v.contact');
    contact.MailingState = component.get('v.state');
    component.set('v.contact', contact);
  },
  editRecord : function(component, event, helper){
    component.set('v.isEditing', !component.get('v.isEditing'));
    if (component.get('v.isEditing') == true){
      helper.initializeEditFormHelper(component, component.get('v.contact'));
    }
  },
  handleSubmit : function(component, event, helper){
		debugger;
      event.preventDefault();
    component.set('v.isSaving', true);
    var error = helper.validateFormHelper(component, event);

    if (error){
      component.set('v.errorMessage', 'All fields must be completed before saving.');
      component.set('v.isSaving', false);
    } else {
      // Update Account Fields
      var account = {
        Id: component.get('v.contact').AccountId,
        Language_Preference__c: component.find('receiptLanguage').get('v.value'),
        Receipt_Type__c: component.find('receiptType').get('v.value')
      }
      helper.updateAccountHelper(component, account);
      
      // Update Contact Fields
      var contact = component.get('v.contact');
      var fields = event.getParam('fields');
      
      fields.Id = contact.rpuId != null ? contact.rpuId : null;
      fields.Update_Status__c = 'Waiting for Approval';
      // Set Salutation Field
      fields.Prefix__c = component.find('Salutation').get('v.value');
      fields.First_Name__c = (contact.FirstName && contact.FirstName.length != 0)
        ? contact.FirstName : null;
      fields.Last_Name__c = (contact.LastName && contact.LastName.length != 0)
        ? contact.LastName : null;
      fields.Suffix__c = (contact.Suffix && contact.Suffix.length != 0)
        ? contact.Suffix : null;
      // Set Phone Fields
      fields.Preferred_Phone__c = component.find('PreferredPhone').get('v.value');
      fields.Home_Phone__c = (contact.HomePhone && contact.HomePhone.length != 0)
        ? contact.HomePhone : null;
      fields.Work_Phone__c = (contact.WorkPhone && contact.WorkPhone.length != 0)
        ? contact.WorkPhone : null;
      fields.Mobile_Phone__c = (contact.MobilePhone && contact.MobilePhone.length != 0)
        ? contact.MobilePhone : null;
      // Set Email Fields
      fields.Preferred_Email__c = component.find('PreferredEmail').get('v.value');
      fields.Personal_Email__c = (contact.PersonalEmail && contact.PersonalEmail.length != 0)
        ? contact.PersonalEmail : null;
      fields.Work_Email__c = (contact.WorkEmail && contact.WorkEmail.length != 0)
        ? contact.WorkEmail : null;
      fields.Alternate_Email__c = (contact.AlternateEmail && contact.AlternateEmail.length != 0)
        ? contact.AlternateEmail : null;
      // Set Address Fields
      fields.Street__c = (contact.MailingStreet && contact.MailingStreet.length != 0)
      ? contact.MailingStreet : null;
      fields.Postal_Code__c = (contact.MailingPostalCode && contact.MailingPostalCode.length != 0)
      ? contact.MailingPostalCode : null;
      fields.City__c = (contact.MailingCity && contact.MailingCity.length != 0)
      ? contact.MailingCity : null;
      fields.Country__c = component.find('MailingCountry').get('v.value');
      fields.State__c = contact.MailingCountry == 'United States' 
        ? component.get('v.state') : fields.MailingState;
      component.find('myRecordForm').submit(fields);
    }
  },
  handleSuccess : function(component, event, helper){
    debugger;
      component.set('v.isSaving', false);
    component.set('v.errorMessage', null);
    component.set('v.isEditing', !component.get('v.isEditing'));
  }
})