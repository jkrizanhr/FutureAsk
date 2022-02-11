({
  _fetchData: function (component, searchText) {
    var action = component.get('c.donorSearch');
    action.setParams({
      searchTerms: searchText.split(' ')
    });

    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        var res = response.getReturnValue();
        if (res.length > 0) {
          component.set('v.accounts', res);
        } else {
          component.set('v.accounts', []);
        }
      } else {
        console.log('Nothing has been found');
        component.set('v.accounts', []);
      }
    });

    $A.enqueueAction(action);
  }
})