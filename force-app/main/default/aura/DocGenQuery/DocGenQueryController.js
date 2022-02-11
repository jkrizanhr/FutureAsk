({
  onClickTogglePrimaryQueryDisplay: function(component, event, helper) {
    component.set('v.showPrimaryQuery', !component.get('v.showPrimaryQuery'));
  },

  onClickToggleSecondaryQueryDisplay: function(component, event, helper) {
    var val = event.getSource().get('v.value');
    var secondaryQueryDisplayList = component.get('v.secondaryQueryDisplayList');
    console.log('secondaryQueryDisplayList: ', secondaryQueryDisplayList);
    var v = !secondaryQueryDisplayList[val];
    secondaryQueryDisplayList[val] = v;
    console.log('v: ', v);
    console.log('secondaryQueryDisplayList: ', secondaryQueryDisplayList);
    component.set('v.secondaryQueryDisplayList', secondaryQueryDisplayList);
  },

  onClickToggleAggregateQueryDisplay: function(component, event, helper) {
    var val = event.getSource().get('v.value');
    var aggregateQueryDisplayList = component.get('v.aggregateQueryDisplayList');
    console.log('aggregateQueryDisplayList: ', aggregateQueryDisplayList);
    var v = !aggregateQueryDisplayList[val];
    aggregateQueryDisplayList[val] = v;
    console.log('v: ', v);
    console.log('aggregateQueryDisplayList: ', aggregateQueryDisplayList);
    component.set('v.aggregateQueryDisplayList', aggregateQueryDisplayList);
  },

  onClickToggleCustomMetadataQueryDisplay: function(component, event, helper) {
    var val = event.getSource().get('v.value');
    var customMetadataQueryDisplayList = component.get('v.customMetadataQueryDisplayList');
    console.log('customMetadataQueryDisplayList: ', customMetadataQueryDisplayList);
    var v = !customMetadataQueryDisplayList[val];
    customMetadataQueryDisplayList[val] = v;
    console.log('v: ', v);
    console.log('customMetadataQueryDisplayList: ', customMetadataQueryDisplayList);
    component.set('v.customMetadataQueryDisplayList', customMetadataQueryDisplayList);
  }
});