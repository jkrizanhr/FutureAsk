({
  addColumn: function(component, event, helper) {
    helper.addColumn(component);
  },

  handleColumnUpdate: function(component, event, helper) {
    var action = event.getParam('action');
    var column = event.getParam('column');

    if (action === 'remove') {
      helper.removeColumn(component, column);
    } else if (action === 'moveUp') {
      helper.moveColumn(component, column, -1);
    } else if (action === 'moveDown') {
      helper.moveColumn(component, column, 1);
    } else if (action === 'changeField') {
      helper.handleFieldChange(component, column);
    } else if (action === 'addResult' || action === 'subtractResult') {
      helper.changeNumberOfSubColumnResults(component, column, action);
    } else if (action === 'addNewSubcolumn') {
      helper.addNewSubcolumn(component, column);
    }
  }
})