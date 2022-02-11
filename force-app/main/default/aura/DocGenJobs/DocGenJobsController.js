({
  doInit: function(component, event, helper) {
    helper.deleteDocGenJobLogs(component);
    helper.loadData(component);

    var loadDataInterval = setInterval(
      $A.getCallback(function() {
        if (component.get('v.jobInProgress') || component.get('v.attempts') < 3) {
          helper.loadData(component);
        } else {
          clearInterval(loadDataInterval);
        }
      }), 10000 // 10 seconds
    );
  },

  onclickViewMoreDetails: function(component, event, helper) {
    let jobId = event.getSource().get('v.value');
    var url = '/one/one.app?#/sObject/' + jobId + '/view/';
    window.open(url);
  },

  onclickAbortApexJob: function(component, event, helper) {
    let apexJobId = event.getSource().get('v.value');
    helper.abortApexJob(component, apexJobId);
  },

  onClickDownloadAllFiles: function(component, event, helper) {
    let jobId = event.getSource().get('v.value');

    helper.fetchContentVersions(component, jobId)
      .then($A.getCallback(function(contentVersions) {
        helper.downloadContent(component, contentVersions);
      }))
      .catch($A.getCallback(function(err) {
        console.log(err);
        alert(err);
      }));
  }
});