({
    onchangeField: function(component, event, helper) {
        var evt = component.getEvent('updateColumnEvent');
        var column = component.get('v.colConfig');
        column.index = component.get('v.idx');
        column.parentIndex = component.get('v.parentIndex');
        evt.setParams({
            column: column,
            action: 'changeField'
        });
        evt.fire();
    }
})