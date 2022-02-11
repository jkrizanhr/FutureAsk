({
  fetchDataHelper: function (component) {      
    return new Promise($A.getCallback(function(resolve, reject) {
      var _fetchData = component.get("c.fetchFeaturedProjects");

      _fetchData.setCallback(this, function(res) {
        if(res.getState() === "ERROR") {
          reject(res.getError());
        } else {
          resolve(res.getReturnValue());
        }
      });
      $A.enqueueAction(_fetchData);
    }));
  },
  createTwitterMessageHelper : function (component, projects){
    for (var i=0; i < projects.length; i++){
      var proj = projects[i];
      proj.twitterMessage = encodeURIComponent(proj.Public_Description__c.trim());
    }
    component.set('v.projects', projects);
  }
})