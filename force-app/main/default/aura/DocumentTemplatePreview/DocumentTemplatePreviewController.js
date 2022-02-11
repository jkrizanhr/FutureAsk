({
  doInit: function(component, event, helper) {
    var recId = component.get('v.recordId');
    helper.fetchTemplate(component, recId);
  },

  recordSelected: function(component, event, helper) {
    var val = component.find('templateSelect').get('v.value');
    if (val) {
      var testRecordOptions = component.get('v.testRecordOptions');
      for (var i = 0; i < testRecordOptions.length; i++) {
        if (testRecordOptions[i].Id == val) {
          component.set('v.selectedTestRecord', testRecordOptions[i]);
          break;
        }
      }
    }
  },

  showTemplatePreview: function(component, event, helper) {
    var url = event.getParam('previewUrl');
    var baseUrl = window.location.protocol + ''//' + window.location.host;
    if (url) {
      component.set('v.previewUrl', url);
    }
  },
  
  resetPreview: function(component, event, helper) {
    component.set('v.previewUrl', '');
    component.set('v.selectedTestRecord', '');
  }
})