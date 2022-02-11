({
  deleteDocGenJobLogs: function(component) {
    let action = component.get('c.deleteOldJobLogs');
    action.setCallback(this, (result) => {
      if (result.getState() === 'ERROR') {
        alert(JSON.stringify(result.getError()));
      }
    });
    $A.enqueueAction(action);
  },

  loadData: function(component) {
    let helper = this;

    helper.loadCurrentJobLogs(component)
      .then($A.getCallback(function(jobLogs) {
        component.set('v.jobLogs', jobLogs);
        let apexJobIds = helper.buildApexJobIdList(component, jobLogs);
        return helper.loadApexJobs(component, apexJobIds);
      }))
      .then($A.getCallback(function(apexJobs) {
        component.set('v.apexJobs', apexJobs);
        helper.handleDocGenJobLogs(component);
      }))
      .catch($A.getCallback(function(err) {
        console.log(err);
        alert(err);
      }));
  },

  loadCurrentJobLogs: function(component) {
    return new Promise(function(resolve, reject) {
      if (!component.isValid()) {
        resolve();
      }
      let action = component.get('c.fetchJobLogs');
      action.setCallback(this, (result) => {
        if (result.getState() === 'ERROR') {
          reject(JSON.stringify(result.getError()));
        } else {
          resolve(result.getReturnValue());
        }
      });
      $A.enqueueAction(action);
    }.bind(this));
  },

  buildApexJobIdList: function(component, jobLogs) {
    let apexJobIds = [];
    for (let i in jobLogs) {
      apexJobIds.push(jobLogs[i].Async_Apex_Job_Id__c);
      if (jobLogs[i].Post_Generation_Job_Id__c) {
        apexJobIds.push(jobLogs[i].Post_Generation_Job_Id__c);
      }
    }
    return apexJobIds;
  },

  loadApexJobs: function(component, apexJobIds) {
    return new Promise(function(resolve, reject) {
      if (!component.isValid()) {
        resolve();
      }
      let action = component.get('c.fetchApexJobs');
      action.setParams({
        apexJobIds: apexJobIds
      });
      action.setCallback(this, (result) => {
        if (result.getState() === 'ERROR') {
          reject(JSON.stringify(result.getError()));
        } else {
          resolve(result.getReturnValue());
        }
      });
      $A.enqueueAction(action);
    }.bind(this));
  },

  handleDocGenJobLogs: function(component) {
    if (!component.isValid()) {
      return;
    }

    let jobLogs = component.get('v.jobLogs');
    let apexJobs = component.get('v.apexJobs');
    let docGenJobs = [];
    let jobInProgress = false;

    for (let i in jobLogs) {
      let docGenJob = JSON.parse(JSON.stringify(jobLogs[i]));
      docGenJob.apexJob = {};
      docGenJob.postGenJob = {};

      for (let j in apexJobs) {
        let inProgressStatuses = ['Holding', 'Queued', 'Preparing', 'Processing'];
        if (inProgressStatuses.indexOf(apexJobs[j].Status) !== -1) {
          jobInProgress = true;
        }

        if (!apexJobs[j].JobItemsProcessed) apexJobs[j].JobItemsProcessed = 0;
        if (!apexJobs[j].TotalJobItems) apexJobs[j].TotalJobItems = 0;

        if (apexJobs[j].Id.substring(0, 15) === jobLogs[i].Async_Apex_Job_Id__c) {
          docGenJob.apexJob.Id = apexJobs[j].Id;
          docGenJob.apexJob.CreatedDate = apexJobs[j].CreatedDate;
          docGenJob.apexJob.JobItemsProcessed = parseInt(apexJobs[j].JobItemsProcessed);
          docGenJob.apexJob.TotalJobItems = parseInt(apexJobs[j].TotalJobItems);
          docGenJob.apexJob.NumberOfErrors = parseInt(apexJobs[j].NumberOfErrors);
          // AsyncApexJob Status: Holding, Queued, Preparing, Processing, Aborted, Completed, Failed
          docGenJob.apexJob.Status = apexJobs[j].Status;
          let percentComplete = parseFloat(apexJobs[j].JobItemsProcessed)/parseFloat(apexJobs[j].TotalJobItems);
          if (parseFloat(apexJobs[j].TotalJobItems) === 0) {
            docGenJob.apexJob.percentComplete = 0;
          } else {
            docGenJob.apexJob.percentComplete = parseInt(100 * (percentComplete));
          }
          if (docGenJob.apexJob.Status === 'Completed') {
            docGenJob.apexJob.percentComplete = 100;
          }

        } else if (jobLogs[i].Post_Generation_Job_Id__c
              && apexJobs[j].Id.substring(0, 15) === jobLogs[i].Post_Generation_Job_Id__c) {
           docGenJob.postGenJob.Id = apexJobs[j].Id;
          docGenJob.postGenJob.CreatedDate = apexJobs[j].CreatedDate;
          docGenJob.postGenJob.JobItemsProcessed = parseInt(apexJobs[j].JobItemsProcessed);
          docGenJob.postGenJob.TotalJobItems = parseInt(apexJobs[j].TotalJobItems);
          docGenJob.postGenJob.NumberOfErrors = parseInt(apexJobs[j].NumberOfErrors);
          docGenJob.postGenJob.Status = apexJobs[j].Status;
          let percentComplete = parseFloat(apexJobs[j].JobItemsProcessed)/parseFloat(apexJobs[j].TotalJobItems);
          docGenJob.postGenJob.percentComplete = parseInt(100 * (percentComplete));
          if (docGenJob.postGenJob.Status === 'Completed') {
            docGenJob.postGenJob.percentComplete = 100;
          }
        }
      }
      docGenJobs.push(docGenJob);
    }
    component.set('v.docGenJobs', docGenJobs);

    if (component.get('v.jobInProgress') && !jobInProgress) {
      component.set('v.attempts', 0);
    } else if (!component.get('v.jobInProgress') && !jobInProgress) {
      let attempts = component.get('v.attempts');
      attempts++;
      component.set('v.attempts', attempts);
    }
    component.set('v.jobInProgress', jobInProgress);
  },

  abortApexJob: function(component, jobId) {
    let action = component.get('c.abortBatchJob');
    action.setParams({
      jobId: jobId
    });
    action.setCallback(this, (result) => {
      if (result.getState() === 'ERROR') {
        alert('Error aborting apex batch job: ' + JSON.stringify(result.getError()));
      } else {
        component.find('notifLib').showToast({
          variant: 'success',
          message: 'Apex batch job successfully aborted.'
        });
      }
    });
    $A.enqueueAction(action);
  },

  fetchContentVersions: function(component, jobId) {
    return new Promise(function(resolve, reject) {
      let action = component.get('c.fetchContentVersions');
      action.setParams({
        jobId: jobId
      });
      action.setCallback(this, (result) => {
        if (result.getState() === 'ERROR') {
          reject(JSON.stringify(result.getError()));
        } else if (result.getReturnValue()) {
          resolve(result.getReturnValue());
        } else {
          reject('No content versions available for this job.');
        }
      });
      $A.enqueueAction(action);
    }.bind(this));
  },

  downloadContent: function(component, contentVersions) {
    var ids = [];
    for (var i in contentVersions) {
      ids.push(contentVersions[i].Id);
    }
    console.log(ids.join('/'));
    var urlEvent = $A.get("e.force:navigateToURL");
    urlEvent.setParams({
      "url": '/sfc/servlet.shepherd/version/download/' + ids.join('/')
    });
    urlEvent.fire();
  }
});