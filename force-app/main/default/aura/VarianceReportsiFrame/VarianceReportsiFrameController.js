({
  checkLoad : function(component, event){
    try {
      var doc = document.getElementById("iframe").document;
      component.set('v.isLoaded', doc != null);
    } catch (error) {
      component.set('v.isLoaded', false);
    }
  }
})