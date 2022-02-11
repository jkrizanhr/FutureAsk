({
  doInit: function(component, event, helper) {
    component.set('v.objects', []);

    var btSettings = component.get('v.btSettings');
    // console.log('btSettings: ', btSettings);

    if (!btSettings) {
      alert('Custom Metadata Type Configuration Required!');
      return;
    }

    if (component.get('v.objectLabel') === 'Account') {
      setTimeout(function() {
       if (component.find('searchInput') != null && component.find('searchInput').getElement() != null) {
          component.find('searchInput').getElement().focus();
        }
      }, 200);
    }
  },

  searchKeyChange: function (component, event, helper) {
    console.log('\nCAND_BT_LookupSearchController.searchKeyChange');
    var searchTextInput = component.find('searchInput').getElement();
    var timer = component.get('v.timer');
    clearTimeout(timer);

    timer = setTimeout($A.getCallback(() => {
      var searchText = searchTextInput.value;
      if (searchText && searchText.length >= 2) {
        component.set('v.objects', []);
        helper.search(component, searchText);

      } else {
        component.set('v.objects', []);
        $A.util.removeClass(component.find('searchContainer'), 'slds-is-open');
      }
      clearTimeout(timer);
      component.set('v.timer', null);
    }), 500);

    component.set('v.timer', timer);
  },

  handleLookupItemSelected: function (component, event, helper) {
    // console.log('\nCAND_BT_LookupSearchController.handleLookupItemSelected');
    var selectedObject = event.getParam('object');
    if (selectedObject !== null) {
      component.set('v.selectedObject', selectedObject);
      $A.util.removeClass(component.find('searchContainer'), 'slds-is-open');
      helper.fireChangeEvent(component);
    }
  },

  onClickEditLookupRecord: function (component, event, helper) {
    var editRecordEvent = $A.get('e.force:editRecord');
    editRecordEvent.setParams({
      recordId: component.get('v.selectedObject.Id')
    });
    editRecordEvent.fire();
  },

  removeSelectedObject: function (component, event, helper) {
    component.set('v.selectedObject', null);
    helper.fireChangeEvent(component);
  },

  onBlur: function (component, event, helper) {
    setTimeout($A.getCallback(function () {
      $A.util.removeClass(component.find('searchContainer'), 'slds-is-open');
    }), 200);
  }
})