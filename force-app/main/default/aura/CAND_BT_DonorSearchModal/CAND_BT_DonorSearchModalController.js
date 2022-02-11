({
  doInit: function (component, event, helper) {
    console.log('DonorSearchModalController.doInit');

  },

  toggleDisplay: function (component, event, helper) {
    var cmpTarget = component.find('DonorSearchModalBox');
    var cmpBack = component.find('DonorSearchModalBackdrop');

    console.log('cmpBack', cmpBack);
    console.log('cmpTarger', cmpTarget);

    $A.util.hasClass(cmpTarget, 'slds-fade-in-open') ?
      $A.util.removeClass(cmpTarget, 'slds-fade-in-open') :
      $A.util.addClass(cmpTarget, 'slds-fade-in-open');

    $A.util.hasClass(cmpBack, 'slds-backdrop--open') ?
      $A.util.removeClass(cmpBack, 'slds-backdrop--open') :
      $A.util.addClass(cmpBack, 'slds-backdrop--open');

    component.find('filterText').set('v.value', '');
    component.set('v.accounts', []);
    setTimeout($A.getCallback(() => {
      component.find('filterText').focus();
    }), 100);
  },

  handleSearch: function (component, event, helper) {
    var timer = component.get('v.timer');
    clearTimeout(timer);

    component.set('v.accounts', []);
    timer = setTimeout($A.getCallback(() => {
      var text = component.find('filterText').get('v.value');
      if (text && text.length >= 2) {
        helper._fetchData(component, text);
      } else if (!text) {
        component.set('v.accounts', []);
      }
      clearTimeout(timer);
      component.set('v.timer', null);
    }), 500);

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
  }
})