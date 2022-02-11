({
    doInit : function(component, event, helper) {
      var isMobile = helper.detectMobile();
      component.set('v.isMobile', isMobile);
    }
})