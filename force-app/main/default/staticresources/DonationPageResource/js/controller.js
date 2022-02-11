angular.module('app.controllers', [])

  .controller('appCtrl', function($scope, $q, $sce, $filter, $timeout, $interval, $window, $document, $uibModal, appService, $http) {
    var campaignId = window.DONATION_PAGE_APP.campaignId && window.DONATION_PAGE_APP.campaignId !== '' ? window.DONATION_PAGE_APP.campaignId : null;
    var refreshInterval;
    var registeredHeight = 0;
    var stripe, card;

    $scope.donationOptions = [];
    $scope.donationOptionGroups = [];
    $scope.expirationYears = [];
    $scope.selectedStartDate = {
      date: new Date()
    };
    $scope.selectedBirthdate = {
      date: undefined
    };

    var today = new Date();
    function calculateLatestRecurringDate() {
      let year = today.getFullYear();
      let month = today.getMonth();
      let day = today.getDate();

      let endMonth = month + 3;
      let endYear = year;
      if(endMonth > 11) {
        endMonth = endMonth - 12;
        endYear = endYear + 1;
      }

      return new Date(endYear, endMonth, day);
    }
    
    $scope.dateOptions = {
      minDate: new Date(),
      maxDate: calculateLatestRecurringDate()
    };
    $scope.birthdateOptions = {
      minDate: new Date(1900, 0, 1),
      maxDate: new Date()
    };
    $scope.recurringStartDatepicker = {
      opened: false
    };
    $scope.birthdatepicker = {
      opened: false
    };
    $scope.altInputFormats = ['M!/d!/yyyy', 'M!/d!/yy', 'M!-d!-yyyy', 'M!-d!-yy', 'yyyy-M!-d!', 'yy-M!-d!'];
    $scope.numberOfPayments = {value: undefined};
    $scope.payment = {};
    $scope.formSubmitting = false;
    $scope.fieldErrors = false;
    $scope.creditCardReady = false;
    $scope.donationOptionProvidedInUrl = false;
    $scope.donationTotal = 0;
    $scope.useContactInfoForBilling = false;
    $scope.selectedDonationOption = {};
    $scope.redirectURL = null;
    $scope.registerURL = '';
    $scope.internalDonation = false;
    $scope.embedded = false;
    $scope.frequencyOptions = ['One-time'];
    $scope.recurringLevelOptions = [{label: 'I want my recurring donation to continue forever', value: 9999, foreverGiving: true}, {label: 'I want to end my recurring donation after this many payments', value: undefined, foreverGiving: false}];
    $scope.selectedRecurringLevelOption = {};
    $scope.parentFrameMessage = {};
    $scope.form = {
      campaignId: campaignId,
      dfs: {},
      chosenOptions: []
    };
    $scope.progressTotalAmount = 0;
    $scope.progressLabel = 0;
    $scope.progressPercentage = 0;
    $scope.currencyOptions = [
      {label: 'USD', symbol: "$", exchangeRate: 1},
      {label: 'CAD', symbol: "CAD$", exchangeRate: null},
      {label: 'GBP', symbol: "£", exchangeRate: null},
      {label: 'EUR', symbol: "€", exchangeRate: null},
      {label: 'INR', symbol: '₹', exchangeRate: null},
      {label: 'KES', symbol: 'Ksh', exchangeRate: null}
    ];
    $scope.chosenCurrency = {currency: $scope.currencyOptions[0]};
    // Used when campaign is not active or ID doesn't exist.
    $scope.pageFail = false;
    $scope.languageOptions = null;
    $scope.chosenLanguage = {language: {}};
    $scope.creditCardType = null;

    function initController() {
      // //Get URL params from imediate URL. For stand alone donation page
      // getParamsFromWindow(window.location.search.split("?")[1]);

      // // Listen for params from parent iframe embed code
      window.addEventListener('message', function (e) {
        if (e.data && Array.isArray(e.data) && e.data[0].type === 'donationPageParams') {
          $scope.embedded = true;
          $scope.parentFrameMessage = e.data;
        }
      });

      $scope.busyPromise = appService.loadData(campaignId)
        .then(function(donationPageData) {
          if(donationPageData.campaign.IsActive) {
            $scope.campaign = donationPageData.campaign;
            $scope.pageSettings = $scope.campaign.Donation_Page_Settings__r;
            handlePageAttributeSetup(donationPageData);
            $scope.publishableKey = donationPageData.stripePublicKey;
            $scope.authNetClientKey = donationPageData.authNetClientKey;
            $scope.authNetAPILoginId = donationPageData.authNetAPILoginId;
            $scope.redirectURL = $scope.pageSettings.Post_Submission_Redirect_URL__c;

            if($scope.pageSettings.Payment_Processor__c === 'Stripe') {
              initializeStripe();
            }
            else if($scope.pageSettings.Payment_Processor__c === 'Authorize.net') {
              initializeAuthNet();
            }
            if ($scope.pageSettings.Allow_Foreign_Transactions__c) {
              $scope.fetchExchangeRates();
            }
            $interval(iframe_resize, 200);
          } else {
            // Don't load form
            $scope.pageFail = true;
          }
          $http.get(`${window.DONATION_PAGE_APP.resourceUrl}/js/languages.json`).then(res => {
            $scope.languageOptions = res.data;
            $scope.chosenLanguage.language = $scope.languageOptions[0];
          });
          if($scope.campaign.Fundraising_Goal__c != null && $scope.campaign.Fundraising_Goal__c > 0) {
            $scope.progressPercentage = (($scope.campaign.AmountWonOpportunities / $scope.campaign.Fundraising_Goal__c) * 100).toFixed(0);
            $scope.progressTotalAmount = $scope.campaign.Fundraising_Goal__c;
            $scope.progressLabel = $scope.campaign.AmountWonOpportunities.toFixed(0);
          }

          //Get URL params from imediate URL. For stand alone donation page
          console.log('getParams');
          getParamsFromWindow(window.location.search.split("?")[1]);

          // Listen for params from parent iframe embed code
          if($scope.embedded && $scope.parentFrameMessage) {
            getParamsFromIframe($scope.parentFrameMessage);
          }
        })
        .catch(function(err) {
          // Don't load form
          $scope.pageFail = true;
          console.log(err);
        });
    }

    $scope.getMatchedAmount = function() {
      return ($scope.getSubtotal() * ($scope.pageSettings.Matching_Multiplier__c - 1)).toFixed(2);
    }

    $scope.getMatchedTotal = function() {
      return ($scope.getSubtotal() * $scope.pageSettings.Matching_Multiplier__c).toFixed(2);
    }

    $scope.getNumberOfDonationUnits = function() {
      var total;
      if ($scope.pageSettings.Allow_Foreign_Transactions__c) {
        total = ((($scope.getSubtotal() * $scope.chosenCurrency.currency.exchangeRate) * $scope.pageSettings.Matching_Multiplier__c) / $scope.pageSettings.Donation_Option_Unit_Cost__c);
      } else {
        total = (($scope.getSubtotal() * $scope.pageSettings.Matching_Multiplier__c) / $scope.pageSettings.Donation_Option_Unit_Cost__c);
      }
      return Math.floor(total);
    };

    $scope.getCurrencyAmount = function() {
      if ($scope.pageSettings.Allow_Foreign_Transactions__c) {
        return (($scope.pageSettings.Donation_Option_Unit_Cost__c / $scope.chosenCurrency.currency.exchangeRate)).toFixed(2);
      } else {
        return ($scope.pageSettings.Donation_Option_Unit_Cost__c).toFixed(2);
      }
    };

    $scope.getOptionLabel = function(donOpt) {
      var symbol = $scope.chosenCurrency.currency.symbol;
      var moneyAmount;
      // if ($scope.pageSettings.Allow_Foreign_Transactions__c) {
      //   moneyAmount = (donOpt.option.Amount__c / $scope.chosenCurrency.currency.exchangeRate).toFixed(0);
      // } else {
        moneyAmount = donOpt.option.Amount__c;
      // }
      var units = '';
      if ($scope.pageSettings.Donation_Option_Unit_Cost__c) {
        if ($scope.pageSettings.Allow_Foreign_Transactions__c) {
          units = ' = ' + Math.floor((donOpt.option.Amount__c / ($scope.pageSettings.Donation_Option_Unit_Cost__c / $scope.chosenCurrency.currency.exchangeRate))) + ' ' + $scope.pageSettings.Donation_Option_Unit_Type__c;
        } else {
          units = ' = ' + Math.floor((donOpt.option.Amount__c / $scope.pageSettings.Donation_Option_Unit_Cost__c)) + ' ' + $scope.pageSettings.Donation_Option_Unit_Type__c;
        }
      }

      return symbol + moneyAmount + units;
    }

    $scope.fetchExchangeRates = function() {
      for(let currency of $scope.currencyOptions) {
        if(!currency.exchangeRate) {
          $scope.busyPromise = appService.convertDonationAmount(100, currency.label).then(function(newAmount) {
            currency.exchangeRate = (newAmount / 100).toFixed(6);
            console.log('Amount: ' + newAmount + '; Rate: ' + currency.label + ' ' + (newAmount / 100).toFixed(6));
          }).catch(function(err) {
            console.log(err);
          });
        }
      }
    }

    $scope.optIsChosen = function(id) {
      var selected = false;
      for (let opt of $scope.form.chosenOptions) {
        if (id === opt.option.Id) {
          selected = true;
        }
      }
      return selected;
    }

    // prevents Enter, e, +, and - from functioning on the input that calls the method
    $scope.checkKey = function(keyEvent) {
      if(keyEvent.which === 69 || keyEvent.which === 189 || keyEvent.which === 187) {
        keyEvent.preventDefault();
      }
    };
    
    $scope.preventSubmitOnEnter = function(keyEvent) {
      if(keyEvent.which === 13) {
        keyEvent.preventDefault();
      }
    };

    function handlePageAttributeSetup(donationPageData) {
      $scope.emailVisible = $scope.pageSettings.Email_Visibility__c !== 'Hidden' ? true : false;
      $scope.contactAddressVisible = $scope.pageSettings.Donor_Contact_Address_Visibility__c !== 'Hidden' ? true : false;
      $scope.billingAddressVisible = $scope.pageSettings.Donor_Billing_Address_Visibility__c !== 'Hidden' ? true : false;
      $scope.tributeAddressVisible = $scope.pageSettings.Donor_Tribute_Address_Visibility__c !== 'Hidden' ? true : false;
      $scope.contactCountryVisible = $scope.pageSettings.Donor_Contact_Country_Visibility__c !== 'Hidden' ? true : false;
      $scope.billingCountryVisible = $scope.pageSettings.Donor_Billing_Country_Visibility__c !== 'Hidden' ? true : false;
      $scope.tributeCountryVisible = $scope.pageSettings.Donor_Tribute_Country_Visibility__c !== 'Hidden' ? true : false;
      $scope.birthdateVisible = $scope.pageSettings.Donor_Birthdate_Visibility__c !== 'Hidden' ? true : false;
      $scope.contactPhoneVisible = $scope.pageSettings.Donor_Contact_Phone_Visibility__c !== 'Hidden' ? true : false;
      $scope.billingPhoneVisible = $scope.pageSettings.Donor_Billing_Phone_Visibility__c !== 'Hidden' ? true : false;
      $scope.tributePhoneVisible = $scope.pageSettings.Donor_Tribute_Phone_Visibility__c !== 'Hidden' ? true : false;
      $scope.hearAboutUsVisible = $scope.pageSettings.How_Did_You_Hear_About_Us_Visibility__c !== 'Hidden' ? true : false;
      $scope.emailRequired = $scope.pageSettings.Email_Visibility__c === 'Required' ? true : false;
      $scope.contactAddressRequired = $scope.pageSettings.Donor_Contact_Address_Visibility__c === 'Required' ? true : false;
      $scope.billingAddressRequired = $scope.pageSettings.Donor_Billing_Address_Visibility__c === 'Required' ? true : false;
      $scope.tributeAddressRequired = $scope.pageSettings.Donor_Tribute_Address_Visibility__c === 'Required' ? true : false;
      $scope.contactCountryRequired = $scope.pageSettings.Donor_Contact_Country_Visibility__c === 'Required' ? true : false;
      $scope.billingCountryRequired = $scope.pageSettings.Donor_Billing_Country_Visibility__c === 'Required' ? true : false;
      $scope.tributeCountryRequired = $scope.pageSettings.Donor_Tribute_Country_Visibility__c === 'Required' ? true : false;
      $scope.birthdateRequired = $scope.pageSettings.Donor_Birthdate_Visibility__c === 'Required' ? true : false;
      $scope.contactPhoneRequired = $scope.pageSettings.Donor_Contact_Phone_Visibility__c === 'Required' ? true : false;
      $scope.billingPhoneRequired = $scope.pageSettings.Donor_Billing_Phone_Visibility__c === 'Required' ? true : false;
      $scope.tributePhoneRequired = $scope.pageSettings.Donor_Tribute_Phone_Visibility__c === 'Required' ? true : false;
      $scope.hearAboutUsRequired = $scope.pageSettings.How_Did_You_Hear_About_Us_Visibility__c === 'Required' ? true : false;

      $scope.paymentMethods = $scope.pageSettings.Payment_Methods__c ? $scope.pageSettings.Payment_Methods__c.split(';') : [];
      $scope.frequencyOptions = $scope.pageSettings.Recurring_Donation_Options__c ? $scope.pageSettings.Recurring_Donation_Options__c.split(';') : ['One-time'];

      // preselect the first payment method
      if ($scope.paymentMethods && $scope.paymentMethods.length) {
        $scope.form.dfs.Payment_Method__c = $scope.paymentMethods[0];
      }
      // preselect the first frequency option
      if ($scope.frequencyOptions && $scope.frequencyOptions.length) {
        $scope.form.dfs.Frequency__c = $scope.frequencyOptions[0];
        $scope.form.dfs.Frequency_Interval__c = $scope.form.dfs.Frequency__c === 'Quarterly' ? 3 : 1;
      }
      // prefill the country dropdowns if a default was specified
      if($scope.pageSettings.Default_Country_Selection__c) {
        $scope.form.dfs.Selected_Country__c = $scope.pageSettings.Default_Country_Selection__c;
        $scope.form.dfs.Selected_Billing_Country__c = $scope.pageSettings.Default_Country_Selection__c;
        $scope.form.dfs.Selected_Notify_Country__c = $scope.pageSettings.Default_Country_Selection__c;
      }
      $scope.selectOptions = donationPageData.selectOptions;
      $scope.donationOptions = donationPageData.donationOptions;
      // check a single option by default if it is the only one available
      if($scope.donationOptions.length == 1) {
        $scope.donationOptions[0].option.Checked_by_Default__c = true;
      }
      // preselect all default-checked donation options
      $scope.donationOptions.forEach(function(opt) {
        opt.frequency = $scope.form.dfs.Frequency__c;
        opt.frequencyInterval = $scope.form.dfs.Frequency__c === 'Quarterly' ? 3 : 1;
        if(opt.option.Checked_by_Default__c) {
          if($scope.pageSettings.Allow_Multiple_Designations__c) {
            $scope.selectedDonationOption['checkbox_' + opt.option.Id] = true;
            $scope.form.chosenOptions.push(opt);
          }
          else {
            $scope.selectedDonationOption.radio = opt.option.Id;
            $scope.form.chosenOptions = [opt];
          }
        }
      });
    }

    function initializeAuthNet() {
      var today = new Date();
      var currentYear = today.getFullYear();
      var numberOfYears = 0;
      for (var i = numberOfYears; i <= 15; i++) {
        var year = currentYear + i;
        var yearStr = year.toString();
        yearStr = yearStr.slice(2,4);
        var yearObj = {
          label: year,
          value: yearStr
        };
        $scope.expirationYears.push(yearObj);
      }
    }

    function initializeStripe() {
      var theInterval = $interval(function() {
        console.log('initializeStripe');
        var exists = document.getElementById('card-element');
        if(!exists) {
          return;
        }
        $interval.cancel(theInterval);
        stripe = Stripe($scope.publishableKey);
        var elements = stripe.elements();
        var style = {
          theme: 'light-outline'
        };
        card = elements.create('card', {
          style: style,
          hidePostalCode: true
        });
        card.mount('#card-element');
        card.addEventListener('change', function(event) {
          $scope.$apply(function() {
            var displayError = document.getElementById('card-errors');
            if (event.error) {
              displayError.textContent = event.error.message;
            } else {
              displayError.textContent = '';
            }
            $scope.creditCardReady = event.complete;

            switch (event.brand) {
              case 'visa':
                $scope.form.dfs.Credit_Card_Type__c = 'Visa';
                break;
              case 'mastercard':
                $scope.form.dfs.Credit_Card_Type__c = 'MasterCard';
                break;
              case 'discover':
                $scope.form.dfs.Credit_Card_Type__c = 'Discover';
                break;
              case 'amex':
                $scope.form.dfs.Credit_Card_Type__c = 'American Express';
                break;
              default:
                $scope.form.dfs.Credit_Card_Type__c = undefined;
            }
          });
        });
      }, 10);
    }

    $scope.trustAsHtml = function(string) {
      return $sce.trustAsHtml(string);
    }

    function iframe_resize() {
      var body = document.body;
      var html = document.documentElement;
      // var currentheight = Math.max(body.scrollHeight, body.offsetHeight, html.clientHeight, html.scrollHeight, html.offsetHeight);
      var currentHeight = document.body.scrollHeight;

      if (currentHeight != registeredHeight && parent.postMessage) {
        registeredHeight = currentHeight;
        parent.postMessage(currentHeight, '*');
        return;
      }
    }

    function getParamsFromIframe(paramsFromIframe) {
      paramsFromIframe = paramsFromIframe.sort().reverse();
      for (let param of paramsFromIframe) {
        console.log('param', param);
        setOptionsFromParams(param.type, param.value);
      }
    }

    function getParamsFromWindow(windowSearch) {
      let params = windowSearch.split("&");
      params = params.sort().reverse();
      for (let param of params) {
        console.log('param', param);
        var splitParam = param.split('=');
        setOptionsFromParams(splitParam[0], splitParam[1]);
      }
    }

    function setOptionsFromParams(param, value) {
      console.log(param);
      switch (param) {
        case 'utm_campaign':
          $scope.form.dfs.utm_campaign__c = value;
          break;
        case 'utm_source':
          $scope.form.dfs.utm_source__c = value;
          break;
        case 'utm_medium':
          $scope.form.dfs.utm_medium__c = value;
          break;
        case 'account_id':
          $scope.busyPromise = appService.getAccountData(value).then(function(account) {
            $scope.form.dfs.Organization_Donation__c = true;
            $scope.form.dfs.Organization_Name__c = account.Name;
            $scope.form.dfs.First_Name__c = account.npe01__One2OneContact__r.FirstName;
            $scope.form.dfs.Last_Name__c = account.npe01__One2OneContact__r.LastName;
            $scope.form.dfs.Street_Address__c = account.npe01__One2OneContact__r.MailingStreet;
            $scope.form.dfs.State_Province__c = account.npe01__One2OneContact__r.MailingState;
            $scope.form.dfs.City__c = account.npe01__One2OneContact__r.MailingCity;
            $scope.form.dfs.Selected_Country__c = account.npe01__One2OneContact__r.MailingCountry;
            $scope.form.dfs.Phone__c = account.npe01__One2OneContact__r.HomePhone;
            $scope.form.dfs.Email__c = account.npe01__One2OneContact__r.Email;
            $scope.form.dfs.Postal_Code__c = cleanZipCode(account.npe01__One2OneContact__r.MailingPostalCode);
            $scope.emailConfirm = account.npe01__One2OneContact__r.Email;
            $scope.form.dfs.Billing_First_Name__c = account.npe01__One2OneContact__r.FirstName;
            $scope.form.dfs.Billing_Last_Name__c = account.npe01__One2OneContact__r.LastName;
            $scope.form.dfs.Billing_Street_Address__c = account.BillingStreet;
            $scope.form.dfs.Billing_State_Province__c = account.BillingState;
            $scope.form.dfs.Billing_City__c = account.BillingCity;
            $scope.form.dfs.Selected_Billing_Country__c = account.BillingCountry;
            $scope.form.dfs.Billing_Postal_Code__c = cleanZipCode(account.BillingPostalCode);
            $scope.form.dfs.Billing_Phone__c = account.Phone;
            $scope.form.dfs.Billing_Email__c = account.npe01__One2OneContact__r.Email;
            $scope.billingEmailConfirm = account.npe01__One2OneContact__r.Email;
            $scope.internalDonation = true;
          });
          break;
        case 'contact_id':
          $scope.busyPromise = appService.getContactData(value).then(function(contact) {
            $scope.form.dfs.First_Name__c = contact.FirstName;
            $scope.form.dfs.Last_Name__c = contact.LastName;
            $scope.form.dfs.Street_Address__c = contact.MailingStreet;
            $scope.form.dfs.State_Province__c = contact.MailingState;
            $scope.form.dfs.City__c = contact.MailingCity;
            $scope.form.dfs.Selected_Country__c = contact.MailingCountry;
            $scope.form.dfs.Phone__c = contact.HomePhone;
            $scope.form.dfs.Email__c = contact.Email;
            $scope.form.dfs.Postal_Code__c = cleanZipCode(contact.MailingPostalCode);
            $scope.emailConfirm = contact.Email;
            $scope.useContactInfoForBilling = true;
            $scope.copyContactInfo();
            $scope.internalDonation = true;
          });
          break;
        case 'donation_option':
          if (value) {
            // var theInterval = $interval(function() {
              var exists = $scope.donationOptions.length > 0;
              if(!exists) {
                return;
              }
              // $interval.cancel(theInterval);
              for (let opt of $scope.donationOptions) {
                if (opt.option.Id === value) {
                  $scope.donationOptionProvidedInUrl = true;
                  console.log('in the switch = ' + $scope.donationOptionProvidedInUrl);
                  $scope.handleDonationOptionChange(opt, $scope.pageSettings.Allow_Multiple_Designations__c);
                  break;
                }
              }
            // }, 10);
          }
          break;
        case 'donation_amount':
          if (!$scope.donationOptionProvidedInUrl && value && parseInt(value) > 0) {
            // var theInterval = $interval(function() {
              var exists = $scope.donationOptions.length > 0;
              if(!exists) {
                return;
              }
              // $interval.cancel(theInterval);
              for (let opt of $scope.donationOptions) {
                if (opt.option.Allow_Custom_Amount__c) {
                  opt.amount = parseInt(value);
                  $scope.handleDonationOptionChange(opt, $scope.pageSettings.Allow_Multiple_Designations__c);
                  break;
                }
              }
            // }, 10);
          }
          break;
        case 'source':
          $scope.form.dfs.Donation_Page_Source__c = value && value === 'mail' ? 'Mail' : 'Online';
          break;
        case 'parent_url':
          $scope.parent_url = decodeURIComponent(value);
          break;
        default:
      }
      console.log('donationOptionProvidedInUrl = ' + $scope.donationOptionProvidedInUrl);
    }

    function cleanZipCode(zipCode) {
      if(!zipCode) {
        return undefined;
      }
      zipCode = zipCode.replace(/-/gi, '');
      zipCode = zipCode.substring(0, 5);
      return zipCode;
    }

    $scope.isOrgDonation = function() {
      if ($scope.form.dfs.Organization_Donation__c) {
        return true;
      } else {
        return false;
      }
    }

    $scope.openDatepicker = function() {
      $scope.recurringStartDatepicker.opened = true;
    };

    $scope.openBirthdatepicker = function() {
      $scope.birthdatepicker.opened = true;
    };

    $scope.copyContactInfo = function() {
      console.log('$scope.useContactInfoForBilling in copy method: ' + $scope.useContactInfoForBilling);
      if($scope.useContactInfoForBilling) {
        $scope.form.dfs.Billing_First_Name__c = $scope.form.dfs.First_Name__c;
        $scope.form.dfs.Billing_Last_Name__c = $scope.form.dfs.Last_Name__c;
        $scope.form.dfs.Billing_Suffix__c = $scope.form.dfs.Suffix__c;
        $scope.form.dfs.Billing_Street_Address__c = $scope.form.dfs.Street_Address__c;
        $scope.form.dfs.Billing_City__c = $scope.form.dfs.City__c;
        $scope.form.dfs.Billing_State_Province__c = $scope.form.dfs.State_Province__c;
        $scope.form.dfs.Billing_Postal_Code__c = $scope.form.dfs.Postal_Code__c;
        $scope.form.dfs.Selected_Billing_Country__c = $scope.form.dfs.Selected_Country__c;
        $scope.form.dfs.Billing_Email__c = $scope.form.dfs.Email__c;
        $scope.form.dfs.Billing_Phone__c = $scope.form.dfs.Phone__c;
        $scope.billingEmailConfirm = $scope.emailConfirm;
      }
      else {
        $scope.form.dfs.Billing_First_Name__c = undefined;
        $scope.form.dfs.Billing_Last_Name__c = undefined;
        $scope.form.dfs.Billing_Suffix__c = undefined;
        $scope.form.dfs.Billing_Street_Address__c = undefined;
        $scope.form.dfs.Billing_City__c = undefined;
        $scope.form.dfs.Billing_State_Province__c = undefined;
        $scope.form.dfs.Billing_Postal_Code__c = undefined;
        $scope.form.dfs.Selected_Billing_Country__c = undefined;
        $scope.form.dfs.Billing_Email__c = undefined;
        $scope.form.dfs.Billing_Phone__c = undefined;
        $scope.billingEmailConfirm = $scope.form.dfs.Billing_Email__c;
      }
      iframe_resize(); //handles fitting the iframe to the content if the content changes from this method or its checkbox
    };

    $scope.selectFrequency = function(freq) {
      $scope.form.dfs.Frequency__c = freq;
      $scope.form.dfs.Frequency_Interval__c = $scope.form.dfs.Frequency__c === 'Quarterly' ? 3 : 1;
      for(var i=0; i<$scope.form.chosenOptions.length; i++) {
        $scope.form.chosenOptions[i].frequency = freq;
        $scope.form.chosenOptions[i].frequencyInterval = $scope.form.dfs.Frequency_Interval__c;
      }
    };

    $scope.selectOptionFrequency = function(optionId, freq) {
      for(var i=0; i<$scope.form.chosenOptions.length; i++) {
        if($scope.form.chosenOptions[i].option && $scope.form.chosenOptions[i].option.Id === optionId) {
          $scope.form.chosenOptions[i].frequency = freq;
          $scope.form.chosenOptions[i].frequencyInterval = freq === 'Quarterly' ? 3 : 1;
          break;
        }
      }
    };

    $scope.selectPaymentMethod = function(paymentMethod) {
      $scope.form.dfs.Payment_Method__c = paymentMethod;
      if($scope.pageSettings.Payment_Processor__c === 'Stripe' && $scope.form.dfs.Payment_Method__c === 'Credit Card') {
        initializeStripe();
      }
    };

    $scope.selectHearAboutUs = function(option) {
      $scope.form.dfs.How_Did_You_Hear_About_Us__c = option;
    };

    $scope.handleDonationOptionChange = function(donOpt, allowMultiple) {
      if(!allowMultiple) {
        $scope.form.chosenOptions = [donOpt];
      }
      else {
        // if option is already chosen, then remove it from the array
        for(var i=0; i<$scope.form.chosenOptions.length; i++) {
          if($scope.form.chosenOptions[i].option.Id === donOpt.option.Id) {
            $scope.form.chosenOptions.splice(i, 1);
            return;
          }
        }
        // if option was not already chosen, then add it to the array
        $scope.form.chosenOptions.push(donOpt);
      }
    };

    $scope.getSubtotal = function() {
      var subtotal = 0;

      $scope.form.chosenOptions.forEach(function(co) {
        subtotal += isNaN(co.amount) ? 0 : co.amount;
      });
      return subtotal.toFixed(2);
      // return $scope.pageSettings &&
      //   $scope.pageSettings.Allow_Foreign_Transactions__c ?
      //   (subtotal / $scope.chosenCurrency.currency.exchangeRate).toFixed(2) : subtotal.toFixed(2);
    };

    $scope.getTotal = function() {
      var total = $scope.getSubtotal();

      if ($scope.form.dfs.Will_Cover_Processing_Fees__c) {
        if($scope.pageSettings.Payment_Processor__c === 'Stripe') {
          total = total * 100;
          total = parseInt((total + ((total * .029)/.971)+30.9)) / 100;
        }
        else {
          // total = (total + (total * 0.03));
          total = total * 100;
          total = (parseInt((total + ((total * .029)/.971)+30.9)) / 100).toFixed(2);
        }
      }

      if(isNaN(total)) {
        total = 0.00;
      }

      return total;
    };

    $scope.cardDateIsExpired = function() {
      let dateError = false;
      if(today.getFullYear() > (parseInt($scope.payment.cardExpirationYear) + 2000)) {
        dateError = true;
      }
      else if(today.getFullYear() === (parseInt($scope.payment.cardExpirationYear) + 2000)) {
        if(today.getMonth() >= parseInt($scope.payment.cardExpirationMonth) - 1) {
          dateError = true;
        }
      }
      return dateError;
    };

    $scope.submitForm = function(donationForm) {
      $scope.formSubmitting = true;
      console.log($scope.form.dfs);
      console.log('$scope.useContactInfoForBilling on submit: ' + $scope.useContactInfoForBilling);
      if($scope.useContactInfoForBilling) {
        $scope.copyContactInfo();
      }
      
      if($scope.pageSettings.Options_Have_Multiple_Frequencies__c) {
        $scope.form.dfs.Frequency__c = 'Multi-Frequency';
      } else if($scope.form.dfs.Frequency__c && $scope.form.dfs.Frequency__c !== 'One-time') {
        let recurringStartDate = moment($scope.selectedStartDate.date);
        let recDateString = recurringStartDate.format('YYYY-MM-DD');
        $scope.form.dfs.Recurring_Start_Date_String__c = recDateString === 'Invalid date' ? undefined : recDateString;

        if($scope.form.dfs.Payment_Method__c === 'Credit Card') {
          let dateError = false;
          if(recurringStartDate.year() > (parseInt($scope.payment.cardExpirationYear) + 2000)) {
            dateError = true;
          }
          else if(recurringStartDate.year() === (parseInt($scope.payment.cardExpirationYear) + 2000)) {
            if(recurringStartDate.month() >= parseInt($scope.payment.cardExpirationMonth) - 1) {
              dateError = true;
            }
          }

          if(dateError) {
            var msg = 'The provided credit card will expire before the recurring donation begins. Please choose a new start date for the donation or use a different credit card.'
            Swal.fire({title: 'Action Required', text: msg, icon: 'error', position: $scope.embedded ? 'bottom' : 'center'});
            $scope.fieldErrors = true;
            $scope.formSubmitting = false;
            return;
          }
        }
      }

      if($scope.form.dfs.Payment_Method__c === 'Credit Card') {
        if($scope.cardDateIsExpired()) {
          var msg = 'The provided credit card has expired.'
          Swal.fire({title: 'Action Required', text: msg, icon: 'error', position: $scope.embedded ? 'bottom' : 'center'});
          $scope.fieldErrors = true;
          $scope.formSubmitting = false;
          return;
        }
      }
      
      if($scope.selectedBirthdate.date !== undefined) {
        let dob = moment($scope.selectedBirthdate.date);

        if(dob.isAfter(today)) {
          var msg = 'The value entered in the birthdate field is in the future. Please check the year and ensure it is valid.'
          Swal.fire({title: 'Action Required', text: msg, icon: 'error', position: $scope.embedded ? 'bottom' : 'center'});
          $scope.fieldErrors = true;
          $scope.formSubmitting = false;
          return;
        }

        let birthdateString = dob.format('YYYY-MM-DD');
        $scope.form.dfs.Donor_Birthdate_String__c = birthdateString === 'Invalid date' ? undefined : birthdateString;
      }

      console.log($scope.form.dfs);
      $scope.fieldErrors = false;
      $scope.fieldErrorsString = '';
      if (!donationForm.$valid) {
        console.log(donationForm);
        if(donationForm.$error && donationForm.$error.required) {
          angular.forEach(donationForm, function (field) {
            if (field && field.$invalid) {
              let fieldName = field.$name;
              let spacedFieldName = fieldName.replace( /([A-Z])/g, " $1" );
              let fieldProperCase = spacedFieldName.charAt(0).toUpperCase() + spacedFieldName.slice(1);
              fieldProperCase = fieldProperCase.indexOf('Cvv') !== -1 ? fieldProperCase.replace('Cvv','CVV') : fieldProperCase;
              field.$setDirty();
              $scope.fieldErrors = true;
              $scope.fieldErrorsString += fieldProperCase + ', ';
            }
          })
          var msg = 'Please complete all required fields.';
        } else if(donationForm.$error && donationForm.$error.date) {
          var msg = 'Please enter birthdate in a valid format (MM/DD/YYYY).';
        } else if(donationForm.$error && donationForm.$error.validator) {
          if(donationForm.$error.validator[0].$name === 'emailConfirm') {
            var msg = 'The values in the email and confirm email fields do not match.';
          } else if(donationForm.$error.validator[0].$name === 'billingEmailConfirm') {
            var msg = 'The values in the billing email and confirm billing email fields do not match.';
          } else if(donationForm.$error.validator[0].$name === 'notifyEmailConfirm') {
            var msg = 'The values in the notify email and confirm notify email fields do not match.';
          }
        } else if(donationForm.$error && donationForm.$error.step) {
          var msg = 'The amount entered is invalid. Please ensure at most 2 decimal places are used in the entered amount.';
        } else if(donationForm.$error && donationForm.$error.ccNumber) {
          var msg = 'The provided credit card number is invalid.';
        } else if(donationForm.$error && donationForm.$error.ccCvc) {
          var msg = 'The provided credit card CVV code is invalid.';
        } else if(donationForm.$error) {
          var msg = 'An unexpected error has occurred. Please send a screenshot of this error to donor.services@biblica.com.';
          debugger;
          for(var key in donationForm.$error) {
            if(donationForm.$error[key] && donationForm.$error[key].length) {
              for(var i=0; i<donationForm.$error[key].length; i++) {
                msg += ' Error: ' + donationForm.$error[key][i].$name + ' - ' + JSON.stringify(donationForm.$error[key][i].$error);
              }
            }
          }
        }
        donationForm.$setDirty(true);
        Swal.fire({title: 'Action Required', text: msg, icon: 'error', position: $scope.embedded ? 'bottom' : 'center'});
        $scope.formSubmitting = false;
        return;
      }

      if (!$scope.form.chosenOptions || !$scope.form.chosenOptions.length || isNaN($scope.getSubtotal()) || $scope.getSubtotal() === 0) {
        var msg = 'Please choose at least one option in the Amount section and ensure your total is greater than $0.'
        Swal.fire({title: 'Action Required', text: msg, icon: 'error', position: $scope.embedded ? 'bottom' : 'center'});
        $scope.fieldErrors = true;
        $scope.formSubmitting = false;
        return;
      }

      let optionWithoutAmount = false;
      for(let i=0; i<$scope.form.chosenOptions.length; i++) {
        if(!$scope.form.chosenOptions[i].amount) {
          optionWithoutAmount = true;
          break;
        }
      }

      if(optionWithoutAmount) {
        var msg = 'Please choose at least one option in the Amount section and ensure your total is greater than $0.'
        Swal.fire({title: 'Action Required', text: msg, icon: 'error', position: $scope.embedded ? 'bottom' : 'center'});
        $scope.fieldErrors = true;
        $scope.formSubmitting = false;
        return;
      }

      if($scope.pageSettings.Payment_Processor__c === 'Stripe' && $scope.form.dfs.Payment_Method__c === 'Credit Card' && !$scope.creditCardReady) {
        var msg = 'Please complete the credit card fields and try again.'
        Swal.fire({title: 'Action Required', text: msg, icon: 'error', position: $scope.embedded ? 'bottom' : 'center'});
        $scope.fieldErrors = true;
        $scope.formSubmitting = false;
        return;
      }
      
      if($scope.form.dfs.Payment_Method__c === 'Credit Card' && donationForm.creditCardNumber.$ccEagerType !== 'American Express' && $scope.payment.cardCVVCode.length > 3) {
        var msg = 'The CVV code is invalid for the provided card number.'
        Swal.fire({title: 'Action Required', text: msg, icon: 'error', position: $scope.embedded ? 'bottom' : 'center'});
        $scope.fieldErrors = true;
        $scope.formSubmitting = false;
        return;
      }

      $scope.form.dfs.Browser_Information__c = window.navigator.userAgent ? window.navigator.userAgent.substring(0, 255) : undefined;
      $scope.form.dfs.Donation_Amount__c = $scope.getSubtotal();
      $scope.form.dfs.Total_Amount__c = $scope.getTotal();
      $scope.form.dfs.Original_Amount__c = $scope.getSubtotal();
      $scope.form.dfs.Original_Amount_with_Fees__c = $scope.getTotal();
      $scope.form.submissionTimestamp = new Date().getTime();
      $scope.form.submissionDate = moment().format('YYYY-MM-DDTHH:mm:ssZ');

      if($scope.form.dfs.Frequency__c !== 'One-time' && !$scope.form.dfs.Number_of_Recurring_Payments__c) {
        $scope.form.dfs.Number_of_Recurring_Payments__c = $scope.numberOfPayments.value;
      }
      if(!$scope.form.dfs.Donation_Page_Source__c) {
        // Set to online if not set by URL
        $scope.form.dfs.Donation_Page_Source__c = 'Online';
      }
      var donation = angular.copy($scope.form);
      donation.dfs.Original_Currency__c = $scope.chosenCurrency.currency.label;
      donation.dfs.Language_Preference__c = $scope.chosenLanguage.language.name;
      if ($scope.form.dfs.Payment_Method__c === 'Check') {
        handleCheckPayment(donation);
      } else if ($scope.form.dfs.Payment_Method__c === 'Credit Card') {
        donation.dfs.Credit_Card_Type__c = donationForm.creditCardNumber.$ccEagerType;
        handleCreditCardPayment(donation);
      } else if ($scope.form.dfs.Payment_Method__c === 'EFT') {
        handleBankAccountPayment(donation);
      }
    };

    function handleCheckPayment(donation) {
      $scope.busyPromise = appService.submitForm(donation)
        .then(function(res) {
          if (res.error && res.error.message) {
            return $q.reject(res.error);
          }
          donation.dfs.Id = res.donationFormSubmissionId;
          donation.dfs.Total_Amount__c = res.totalAmount;
          donation.dfs.Donation_Amount__c = res.donationAmount;
          return appService.processDonation(donation.dfs.Id);
        })
        .then(function() {
          showCompleteModal();
          fireAnalytics(donation.dfs.Id);
        })
        .catch(function(err) {
          showErrorModal(err);
          $scope.formSubmitting = false;
        })
    }

    function createAuthNetToken(secureData) {
      var deferred = $q.defer();
      Accept.dispatchData(secureData, function(res) {
          if (res.messages.resultCode === 'Ok') {
            deferred.resolve(res);
          } else {
            var errors = '';
            for(var i=0; i<res.messages.message.length; i++) {
              errors += res.messages.message[i].text + '\r\n';
            }
            deferred.reject(new Error(errors));
          }
      });
      return deferred.promise;
    }

    function getCreditCardData(processor) {
      if(processor === 'Stripe') {
        var cardData = {
          name: $scope.form.dfs.Billing_First_Name__c + ' ' + $scope.form.dfs.Billing_Last_Name__c,
          address_line1: $scope.form.dfs.Billing_Street_Address__c,
          address_city: $scope.form.dfs.Billing_City__c,
          address_state: $scope.form.dfs.Billing_State_Province__c,
          address_zip: $scope.form.dfs.Billing_Zip_Code__c,
          address_country: $scope.form.dfs.Selected_Billing_Country__c
        };
        return cardData;
      }
      else if(processor === 'Authorize.net') {
        var secureData = {};
        var authData = {
          clientKey: $scope.authNetClientKey,
          apiLoginID: $scope.authNetAPILoginId
        };
        var cardData = {
          cardNumber: $scope.payment.cardNumber,
          month: $scope.payment.cardExpirationMonth,
          year: $scope.payment.cardExpirationYear,
          cardCode: $scope.payment.cardCVVCode ? $scope.payment.cardCVVCode : ''
        };
        secureData.authData = authData;
        secureData.cardData = cardData;
        return secureData;
      }
    }

    function getSourceData(processor) {
      if(processor === 'Stripe') {
        var sourceData = {
          type: 'card',
          currency: 'usd',
          owner: {
            name: $scope.form.dfs.Billing_First_Name__c + ' ' + $scope.form.dfs.Billing_Last_Name__c,
            email: $scope.form.dfs.Billing_Email__c
          },
          usage: 'reusable'
        };
        return sourceData;
      }
      return null;
    }

    function handleCreditCardPayment(donation) {
      var cardData = {};
      var sourceData = {};
      var secureData = {};
      if($scope.pageSettings.Payment_Processor__c === 'Stripe') {
        if($scope.form.dfs.Frequency__c === 'Multi-Frequency') {
          sourceData = getSourceData('Stripe');
        }
        else {
          cardData = getCreditCardData('Stripe');
        }
      }
      else if($scope.pageSettings.Payment_Processor__c === 'Authorize.net') {
        secureData = getCreditCardData('Authorize.net');
      }

      donation.dfs.Credit_Card_Last_Four__c = secureData.cardData.cardNumber.slice(-4);
      donation.dfs.Credit_Card_Exp_Date__c = secureData.cardData.month + '/' + secureData.cardData.year;


      $scope.busyPromise = appService.submitForm(donation)
        .then(function(res) {
          if (!res.success && res.error) {
            return $q.reject(new Error(res.error));
          }
          donation.dfs.Id = res.donationFormSubmissionId;
          donation.dfs.Total_Amount__c = res.totalAmount;
          donation.dfs.Donation_Amount__c = res.donationAmount;
          if($scope.pageSettings.Payment_Processor__c === 'Stripe') {
            if($scope.form.dfs.Frequency__c === 'Multi-Frequency') {
              return $q.when(stripe.createSource(card, sourceData));
            }
            else {
              return $q.when(stripe.createToken(card, cardData));
            }
          }
          else if($scope.pageSettings.Payment_Processor__c === 'Authorize.net') {
            return createAuthNetToken(secureData);
          }
        })
        .then(function(res) {
          if($scope.pageSettings.Payment_Processor__c === 'Stripe') {
            if (res.error) {
              return $q.reject(res.error);
            }
            if($scope.form.dfs.Frequency__c === 'Multi-Frequency') {
              donation.stripeSourceId = res.source.id;
            }
            else {
              donation.stripeToken = res.token.id;
            }
          }
          else if($scope.pageSettings.Payment_Processor__c === 'Authorize.net') {
            donation.authNetOpaqueDataDescriptor = res.opaqueData.dataDescriptor;
            donation.authNetOpaqueDataDataValue = res.opaqueData.dataValue;
            donation.dfs.Credit_Card_Hash__c = res.opaqueData.dataValue;
          }
          return appService.submitPayment(donation);
        })
        .then(function(res) {
          if (!res.success && res.error) {
            return $q.reject(new Error(res.error));
          }
          return appService.processDonation(donation.dfs.Id);
        })
        .then(function(res) {
          showCompleteModal();
          fireAnalytics(donation.dfs.Id);
        })
        .catch(function(err) {
          console.log(err);
          showErrorModal(err);
          $scope.formSubmitting = false;
        })
    }

    function getBankAccountData(processor) {
      if(processor === 'Authorize.net') {
        var secureData = {};
        var authData = {
          clientKey: $scope.authNetClientKey,
          apiLoginID: $scope.authNetAPILoginId
        };
        var bankData = {
          accountNumber: $scope.payment.accountNumber,
          routingNumber: $scope.payment.routingNumber,
          nameOnAccount: $scope.payment.nameOnAccount,
          accountType: $scope.payment.accountType
        };
        secureData.authData = authData;
        secureData.bankData = bankData;
        return secureData;
      }
    }

    function handleBankAccountPayment(donation) {
      var cardData = {};
      var secureData = {};
      if($scope.pageSettings.Payment_Processor__c === 'Stripe') {
        cardData = getCreditCardData('Stripe');
      }
      else if($scope.pageSettings.Payment_Processor__c === 'Authorize.net') {
        secureData = getBankAccountData('Authorize.net');
      }

      $scope.busyPromise = appService.submitForm(donation)
        .then(function(res) {
          if (!res.success && res.error) {
            return $q.reject(new Error(res.error));
          }
          donation.dfs.Id = res.donationFormSubmissionId;
          donation.dfs.Total_Amount__c = res.totalAmount;
          donation.dfs.Donation_Amount__c = res.donationAmount;
          if($scope.pageSettings.Payment_Processor__c === 'Stripe') {
            return $q.when(stripe.createToken(card, cardData));
          }
          else if($scope.pageSettings.Payment_Processor__c === 'Authorize.net') {
            return createAuthNetToken(secureData);
          }
        })
        .then(function(res) {
          if($scope.pageSettings.Payment_Processor__c === 'Stripe') {
            if (res.error) {
              return $q.reject(res.error);
            }
            donation.stripeToken = res.token.id;
          }
          else if($scope.pageSettings.Payment_Processor__c === 'Authorize.net') {
            donation.authNetOpaqueDataDescriptor = res.opaqueData.dataDescriptor;
            donation.authNetOpaqueDataDataValue = res.opaqueData.dataValue;
          }
          return appService.submitPayment(donation);
        })
        .then(function(res) {
          if (!res.success && res.error) {
            return $q.reject(new Error(res.error));
          }
          return appService.processDonation(donation.dfs.Id);
        })
        .then(function(res) {
          showCompleteModal();
          fireAnalytics(donation.dfs.Id);
        })
        .catch(function(err) {
          console.log(err);
          showErrorModal(err);
          $scope.formSubmitting = false;
        })
    }

    function fireAnalytics(donationId) {
      var message = {
        type: 'messageFromForm',
        value: {
          donationId: donationId,
          idOrUtm: $scope.form.dfs.utm_campaign__c ? $scope.form.dfs.utm_campaign__c : campaignId,
          total: $scope.getTotal(),
          currency: $scope.chosenCurrency.currency.label
        }
      };
      var originUrl = $scope.parent_url ? $scope.parent_url : window.origin;
      parent.postMessage(message, originUrl);
      // fbq('track', 'Donate', {
      //   currency: $scope.chosenCurrency.currency.label,
      //   value: $scope.getTotal(),
      //   content_name: $scope.form.dfs.utm_campaign__c ? $scope.form.dfs.utm_campaign__c : campaignId
      // });
      // ga('send', 'event', 'Donor Conversion', $scope.form.dfs.utm_campaign__c ? $scope.form.dfs.utm_campaign__c : campaignId);  // Campaign Name or Code along with conversion type: Name or Donor.
      // ga('require', 'ecommerce');
      // ga('ecommerce:addTransaction', {
      // 'id': donationId,                            // DFS ID.
      // 'revenue': $scope.getTotal(),                     // Grand Total - without a dollar sign.
      // 'currency': $scope.chosenCurrency.currency.label  // Currency Code.
      // });
      // ga('ecommerce:send');
    }

    function showCompleteModal() {
      let successEmail = !$scope.pageSettings.Page_Contact_Email__c ? 'donor.services@biblica.com' : $scope.pageSettings.Page_Contact_Email__c;
      let modalText = `<p>Thank you for your donation. If you have additional questions or concerns, please contact us at
                        <a href="mailto:${successEmail}">${successEmail}</a>
                      </p>`;
      if($scope.pageSettings.facebook_campaign_url__c || $scope.pageSettings.twitter_campaign_url__c) {
        modalText += `<h3>Share</h3>
        <div class="social-button-container success-modal-social">`;
        if($scope.pageSettings.facebook_campaign_url__c) {
          modalText += `<div class="social-button" onclick="OpenSocialPopup('${$scope.pageSettings.facebook_campaign_url__c}', 'Facebook')">
          <i class="fa fa-f fa-facebook-f"></i>
          </div>`;
        }
        if($scope.pageSettings.twitter_campaign_url__c) {
          modalText += `<div class="social-button" onclick="OpenSocialPopup('${$scope.pageSettings.twitter_campaign_url__c}', 'Twitter')">
          <i class="fa fa-f fa-twitter"></i>
          </div>`
        }
        `</div>`;
      }
      Swal.fire({
        title: 'Success!',
        html: modalText,
        icon: 'success',
        position: $scope.embedded ? 'bottom' : 'center',
        closeOnConfirm: false,
        confirmButtonText: 'Donate Again',
      }).then(function(submitAnother) {
        $scope.formSubmitting = false;
        if (submitAnother) {
          window.location.reload();
        } else {
          var redirectURL = 'https://www.biblica.com/';
          if ($scope.redirectURL) {
            window.location.href = $scope.redirectURL;
          } else {
            window.location.href = redirectURL;
          }
        }
      });
    }

    function showErrorModal(err) {
      Swal.fire({title: 'Error', text: 'There was an error trying to submit your donation.\r\n' + err.message, icon: 'error', position: $scope.embedded ? 'bottom' : 'center'});
    }

    // This function allows the new window to be opened from the main donate page. It is also replicated in the head of
    // the donate page to allow the social buttons in the success popup to work.
    $scope.OpenSocialPopup = function (url, socialName) {
      $window.open(url, socialName, "width=600,height=500,left=10,top=150");
    }

    $scope.goToSection = function(sectionId) {
      var someElement = angular.element(document.getElementById(sectionId));
      $document.scrollToElement(someElement, 20, 1000);
    };

    $scope.getResourceUrl = function(urlExt) {
      return window.DONATION_PAGE_APP.resourceUrl + urlExt;
    };

    $window.onfocus = function() {
      if (angular.isDefined(refreshInterval)) {
        $interval.cancel(refreshInterval);
        refreshInterval = undefined;
      }
    };

    initController();
  });