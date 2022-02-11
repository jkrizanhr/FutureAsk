({
  onObjectSelected: function(component, event, helper) {
    var evt = component.getEvent('selectedEvent');
    evt.setParams({
      object: component.get('v.lookupObject'),
    });
    evt.fire();
  },
  onEnterKeyObjectSelected : function(component, event, helper){
    var isEnterKey = event.keyCode === 13;
    if (isEnterKey){
      var evt = component.getEvent('selectedEvent');
      evt.setParams({
        object: component.get('v.lookupObject'),
      });
      evt.fire();
    }
  }
})