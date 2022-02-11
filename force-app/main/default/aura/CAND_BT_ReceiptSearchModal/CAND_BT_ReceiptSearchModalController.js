({
  doInit: function (component, event, helper) {
    console.log('ReceiptSearchModalController.doInit');

  },

  toggleDisplay: function (component, event, helper) {
    var cmpTarget = component.find('ReceiptSearchModalBox');
    var cmpBack = component.find('ReceiptSearchModalBackdrop');

    $A.util.hasClass(cmpTarget, 'slds-fade-in-open') ?
      $A.util.removeClass(cmpTarget, 'slds-fade-in-open') :
      $A.util.addClass(cmpTarget, 'slds-fade-in-open');

    $A.util.hasClass(cmpBack, 'slds-backdrop--open') ?
      $A.util.removeClass(cmpBack, 'slds-backdrop--open') :
      $A.util.addClass(cmpBack, 'slds-backdrop--open');

    component.find('filterText').set('v.value', '');
    component.set('v.opportunity', '');
  },

  handleSearch: function (component, event, helper) {
    var timer = component.get('v.timer');
    clearTimeout(timer);

    timer = setTimeout($A.getCallback(() => {
      var searchText = component.find('filterText').get('v.value');
      if (searchText && searchText.length >= 2) {
        component.set('v.opportunity', null);
        helper._fetchData(component, searchText);

      } else {
        component.set('v.opportunity', null);
      }
      clearTimeout(timer);
      component.set('v.timer', null);
    }), 1000);

    component.set('v.timer', timer);
  },

  copyOppRecord: function (component, event, helper) {
    var filloutOpportunityForm = component.getEvent('CAND_BT_GetOppAllocations');
    var record = event.target.value;
    console.log(record);
    filloutOpportunityForm.setParams({
      "opportunity": record
    });
    filloutOpportunityForm.fire();

    var action = component.get('c.toggleDisplay');
    action.setParams({
      component: component,
      event: event,
      helper: helper
    });
    $A.enqueueAction(action);
  },

  clearSearch: function (component, event, helper) {
    component.find('filterText').set('v.value', '');
    component.set('v.opportunity', '');
  }
});