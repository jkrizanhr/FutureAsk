({
    toggleDisplay : function(component, event, helper) {
        var cmpTarget = component.find('PaymentModal');
        var cmpBack = component.find('PaymentModalbackdrop');
    
        $A.util.hasClass(cmpTarget, 'slds-fade-in-open')
          ? $A.util.removeClass(cmpTarget, 'slds-fade-in-open')
          : $A.util.addClass(cmpTarget, 'slds-fade-in-open');
    
        $A.util.hasClass(cmpBack, 'slds-backdrop--open')
          ? $A.util.removeClass(cmpBack, 'slds-backdrop--open')
          : $A.util.addClass(cmpBack, 'slds-backdrop--open');

      }, 
})