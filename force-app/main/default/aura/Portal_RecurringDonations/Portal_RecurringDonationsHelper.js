({
  fetchDataHelper: function (component) {      
    return new Promise($A.getCallback(function(resolve, reject) {
      var _fetchData = component.get("c.fetchActiveRecurringDonations");

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
  setDaysOfMonthSuffixHelper : function (component){
    var specialCases = {st: ["1", "21", "31"], nd: ["2", "22"], rd: ["3", "23"]};
    var rds = component.get('v.recurringDonations');
    
    for (var i=0; i < rds.length; i++){
      var suffix = 'th';
      // Special Case: Last Day of the Month stored in SF as 'Last_Day' change to Last Day of month
      if (rds[i].npsp__Day_of_Month__c == 'Last_Day'){
        rds[i].npsp__Day_of_Month__c = new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0).getDate();
      }
      
      // make sure the ending is correct, i.e. 1st, 2nd, 3rd, 4th
      if (specialCases.st.includes(rds[i].npsp__Day_of_Month__c)){
        suffix = 'st';
      } else if (specialCases.nd.includes(rds[i].npsp__Day_of_Month__c)){
        suffix = 'nd';
      } else if (specialCases.rd.includes(rds[i].npsp__Day_of_Month__c)){
        suffix = 'rd'
      } 
      rds[i].suffix = suffix;
    }
    component.set('v.recurringDonations', rds);
  },
  detectMobileHelper : function(){
    const toMatch = [
      /Android/i,
      /webOS/i,
      /iPhone/i,
      /iPad/i,
      /iPod/i,
      /BlackBerry/i,
      /Windows Phone/i
    ];
    return toMatch.some((toMatchItem) => {
      return navigator.userAgent.match(toMatchItem);
    });
  }
})