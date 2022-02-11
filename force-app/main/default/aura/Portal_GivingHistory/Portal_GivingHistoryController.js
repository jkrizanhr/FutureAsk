({
  init: function (component, event, helper) {
    var isMobile = helper.detectMobileHelper();
    component.set('v.isMobile', isMobile);
    
    // get current year as default, then add last five years to picklist also
    var yr = new Date().getFullYear();
    component.set('v.year', yr.toString());
    var yrs = [];
    for (var i = 0; i < 6; i++){
      yrs.push(
        {label: yr - i, 
        value: yr - i}
      );
    }
    component.set('v.yearOptions', yrs);

    // get data from salesforce, list of GAU allocations grouped by opp
    helper.fetchDataHelper(component)
      .then($A.getCallback(function(results) {
        var totalSize = results.length;
        component.set('v.totalSize', totalSize);
        component.set('v.opportunityList', results);
        helper.handlePaginationHelper(component, 'first');
      }));
  },
	onSelectChange : function(component, event, helper) {
    var pageSize = parseInt(component.find('records').get('v.value'));
    component.set('v.pageSize', pageSize);
    helper.handlePaginationHelper(component, 'first');
  },
  handlePagination : function(component, event, helper){
    var action = event.getSource().get('v.value');
    helper.handlePaginationHelper(component, action);
  },
  printYearEndReceipt : function(component, event, helper){
    var year = component.get('v.year');
    helper.fetchReceiptTemplateHelper(component)
      .then($A.getCallback(function(results) {
        if (results){
          var URLstring = '/apex/BiblicaEndOfYearReceiptPortalUsersPDF?'
          + 'recordIds=' + results.acctId
          + '&templateId=' + results.templateId
          + '&deliveryOption=PDF - Direct Download'
          + '&isTestMode=true'
          + '&' + results.questOneId + '=CALENDAR_YEAR(Close_Date__c) = ' + year
          + '&thisYear=calendar_year(close_date__c) = ' + year
          + '&' + results.questTwoId + "=Year__c = '" + year + "'";
          window.open(URLstring);
        } else {
          var toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams({
            title: "Oops! Something went wrong.",
            message: "The End of Year Receipt template was not found.",
            type: "error"
          });
          toastEvent.fire();
        }
      }));
  },
  printStandardReceipt : function(component, event, helper){
    var gauId = event.getSource().get('v.value');
    helper.fetchStandardReceiptTemplateHelper(component)
      .then($A.getCallback(function(results) {
        if (results){
          var URLstring = '/apex/BiblicaStandardReceiptPortalUsersPDF?'
          + 'recordIds=' + gauId
          + '&templateId=' + results
          + '&deliveryOption=PDF - Direct Download'
          + '&isTestMode=true';
          window.open(URLstring);
        } else {
          var toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams({
            title: "Oops! Something went wrong.",
            message: "The Standard Receipt template was not found.",
            type: "error"
          });
          toastEvent.fire();
        }
      }));
  },
  goToGivePage : function(component, event, helper){
    location.href = '/s/give?oppId=' + event.getSource().get('v.value');
  },
  goToMyProfilePage : function(component, event, helper){
    location.href = '/s/profile/home';
  }
})