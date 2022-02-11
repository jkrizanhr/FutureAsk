var app = angular.module('app', [
  'app.controllers',
  'ngAnimate',
  'ngSanitize',
  'ui.bootstrap',
  'cgBusy',
  // 'oitozero.ngSweetAlert',
  'ui.mask',
  'ui.validate',
  'credit-cards',
  'ngMessages'
]);
app.factory('appService', function($rootScope, $q, $window) {

  var invokeActionHandler = function(result, event) {
    $rootScope.$apply(function() {
      if (event.status) {
        this.resolve(result);
      } else {
        this.reject(event);
      }
    }.bind(this));
  }

  var _loadData = function(campaignId) {
    var deferred = $q.defer();
    var action = $window.DONATION_PAGE_APP.vfRemoting.appService.loadData;
    Visualforce.remoting.Manager.invokeAction(action, campaignId, invokeActionHandler.bind(deferred), {
      buffer: true,
      escape: false,
      timeout: 30000
    });
    return deferred.promise;
  };

  var _submitForm = function(application) {
    var deferred = $q.defer();
    var action = $window.DONATION_PAGE_APP.vfRemoting.appService.submitForm;
    Visualforce.remoting.Manager.invokeAction(action, application, invokeActionHandler.bind(deferred), {
      buffer: true,
      escape: false,
      timeout: 30000
    });
    return deferred.promise;
  };

  var _submitPayment = function(paymentForm) {
    var deferred = $q.defer();
    var action = $window.DONATION_PAGE_APP.vfRemoting.appService.submitPayment;
    Visualforce.remoting.Manager.invokeAction(action, paymentForm, invokeActionHandler.bind(deferred), {
      buffer: true,
      escape: false,
      timeout: 30000
    });
    return deferred.promise;
  };

  var _processDonation = function(donationFormSubmissionId) {
    var deferred = $q.defer();
    var action = $window.DONATION_PAGE_APP.vfRemoting.appService.processDonation;
    Visualforce.remoting.Manager.invokeAction(action, donationFormSubmissionId, invokeActionHandler.bind(deferred), {
      buffer: true,
      escape: false,
      timeout: 30000
    });
    return deferred.promise;
  };

  var _convertDonationAmount = function(amount, srcCurr) {
    var deferred = $q.defer();
    var action = $window.DONATION_PAGE_APP.vfRemoting.appService.convertDonationAmount;
    Visualforce.remoting.Manager.invokeAction(action, amount, srcCurr, invokeActionHandler.bind(deferred), {
      buffer: true,
      escape: false,
      timeout: 30000
    });
    return deferred.promise;
  };

  var _getAccountData = function(id) {
    var deferred = $q.defer();
    var action = $window.DONATION_PAGE_APP.vfRemoting.appService.getAccountData;
    Visualforce.remoting.Manager.invokeAction(action, id, invokeActionHandler.bind(deferred), {
      buffer: true,
      escape: false,
      timeout: 30000
    });
    return deferred.promise;
  };

  var _getContactData = function(id) {
    var deferred = $q.defer();
    var action = $window.DONATION_PAGE_APP.vfRemoting.appService.getContactData;
    Visualforce.remoting.Manager.invokeAction(action, id, invokeActionHandler.bind(deferred), {
      buffer: true,
      escape: false,
      timeout: 30000
    });
    return deferred.promise;
  };

  return {
    loadData: _loadData,
    submitForm: _submitForm,
    submitPayment: _submitPayment,
    processDonation: _processDonation,
    convertDonationAmount: _convertDonationAmount,
    getAccountData: _getAccountData,
    getContactData: _getContactData
  };
});