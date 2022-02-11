({
    onclickColumnAction: function(component, event, helper) {
        var evt = component.getEvent('updateColumnEvent');
        evt.setParams({
            column: component.get('v.column'),
            action: event.getSource().get('v.value')
        });
        evt.fire();
    }
})