({
    onchangeQuery: function(component, event, helper) {
        var colConfig = component.get('v.colConfig');
        colConfig.selectIndex = 0;
        component.set('v.colConfig', colConfig);
        var fieldSelectList = component.get('v.fieldSelectList');
        component.set('v.fieldSelectList', []);
        component.set('v.fieldSelectList', fieldSelectList);
    },

    onchangeField: function(component, event, helper) {
        var evt = component.getEvent('updateColumnEvent');
        var column = component.get('v.colConfig');
        column.index = component.get('v.idx');
        evt.setParams({
            column: column,
            action: 'changeField'
        });
        evt.fire();
    },

    onchangeNumSubColumns: function(component, event, helper) {
        var value = event.getSource().get('v.value');

        var evt = component.getEvent('updateColumnEvent');
        var column = component.get('v.colConfig');
        column.numResults += parseInt(value);

        if (parseInt(column.numResults) < 1) {
            return;
        }

        var action;
        if (parseInt(value) === 1) {
            action = 'addResult';
        } else {
            action = 'subtractResult';
        }

        column.index = component.get('v.idx');
        evt.setParams({
            column: column,
            action: action
        });
        evt.fire();
    },

    onclickAddSubColumn: function(component, event, helper) {
        var evt = component.getEvent('updateColumnEvent');
        var column = component.get('v.colConfig');
        evt.setParams({
            column: column,
            action: 'addNewSubcolumn'
        });
        evt.fire();
    },

    onclickToggleAggregateSubColumns: function(component, event, helper) {
        component.set('v.showAggregateSubColumns', !component.get('v.showAggregateSubColumns'));
    }
})