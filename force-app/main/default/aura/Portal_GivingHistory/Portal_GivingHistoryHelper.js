({
  fetchDataHelper : function (component) {      
    return new Promise($A.getCallback(function(resolve, reject) {
      var _fetchData = component.get("c.fetchAllocations");

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
  fetchReceiptTemplateHelper : function (component) {      
    return new Promise($A.getCallback(function(resolve, reject) {
      var _fetchData = component.get("c.fetchReceiptTemplate");

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
  fetchStandardReceiptTemplateHelper : function (component) {      
    return new Promise($A.getCallback(function(resolve, reject) {
      var _fetchData = component.get("c.fetchStandardReceiptTemplate");
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
  },
  handlePaginationHelper : function (component, action){
    var paginationList = [];
    var oppList = component.get('v.opportunityList');
    var pageSize = component.get('v.pageSize');
    var totalSize = component.get('v.totalSize');
    var startIndex;
    var endIndex;

    switch (action) {
      case 'first':
        startIndex = 0;
        endIndex = pageSize < totalSize 
          ? pageSize 
          : totalSize;
        break;
      case 'next':
        startIndex = component.get('v.endIndex');
        endIndex = (startIndex + pageSize) < totalSize
          ? startIndex + pageSize 
          : totalSize;
        break;
      case 'previous':
        startIndex = component.get('v.startIndex') - pageSize;
        endIndex = component.get('v.startIndex');
        break;
      case 'last':
        startIndex = totalSize % pageSize == 0
          ? totalSize - pageSize 
          : totalSize - (totalSize % pageSize);
        endIndex = totalSize;
        break;
      default:
        break;
    }
    
    for (var i = startIndex; i < endIndex; i++){
      paginationList.push(oppList[i]);
    }

    component.set('v.startIndex', startIndex);
    component.set('v.endIndex', endIndex);
    component.set('v.paginationList', paginationList);

  }
})