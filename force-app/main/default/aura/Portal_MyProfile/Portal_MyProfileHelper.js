({
  fetchDataHelper: function (component) {      
    return new Promise($A.getCallback(function(resolve, reject) {
      var _fetchData = component.get("c.fetchProfileInformation");

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
  fetchPicklistDataHelper: function (component) {      
    return new Promise($A.getCallback(function(resolve, reject) {
      var _fetchData = component.get("c.getPicklistValues");

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
  initializeEditFormHelper : function(component, results){
    component.find("firstName").set('v.value', results.FirstName);
    component.find("lastName").set('v.value', results.LastName);
    component.find("suffix").set('v.value', results.Suffix);
    component.find("mailingStreet").set('v.value', results.MailingStreet);
    component.find("mailingState").set('v.value', results.MailingState);
    component.find("mailingCity").set('v.value', results.MailingCity);
    component.find("postalCode").set('v.value', results.MailingState);
  },
  validateFormHelper : function(component, event){
    var fields = event.getParam('fields');
    var contact = component.get('v.contact');
    if (
      contact.FirstName && contact.LastName &&
      contact.MailingStreet && contact.MailingCity && contact.MailingPostalCode && 
      ((component.get('v.contact').MailingCountry == 'United States' && component.get('v.state')) ||
      (component.get('v.contact').MailingCountry != 'United States' && fields.State__c)) && 
      component.find('PreferredEmail').get('v.value') &&
      (component.get('v.contact').PersonalEmail || 
        component.get('v.contact').AlternateEmail ||
        component.get('v.contact').WorkEmail) &&
      component.find('PreferredPhone').get('v.value') &&
      (component.get('v.contact').HomePhone ||
        component.get('v.contact').WorkPhone ||
        component.get('v.contact').MobilePhone) &&
      component.find('receiptLanguage').get('v.value') &&
      component.find('receiptType').get('v.value')
    ) {
      return false; // Return false because there is no error
    } else {
      return true; // Return true because not all fields are complete
    }
  },
  updateAccountHelper : function(component, account){
    var _updateAccount = component.get("c.updateAccount");
    _updateAccount.setParams({
      account: account
    });
    _updateAccount.setCallback(this, function(res) {
      if(res.getState() === "ERROR") {
        console.log(res.getError());
      } 
    });
    $A.enqueueAction(_updateAccount);
  },
  setPhoneFieldHelper : function(component, phoneType){
    var phoneField = null;
    switch(phoneType){
      case 'Home':
        phoneField = 'HomePhone';
        break;
      case 'Work':
        phoneField = 'npe01__WorkPhone__c';
        break;
      case 'Mobile':
        phoneField = 'MobilePhone';
        break;
      case 'Other':
        phoneField = 'OtherPhone';
        break;
      default:
        phoneField = 'Phone';
    }
    component.set('v.phoneField', phoneField);
  },
  setEmailFieldHelper : function(component, emailType){
    var emailField = null;
    switch(emailType){
      case 'Personal':
        emailField = 'npe01__HomeEmail__c';
        break;
      case 'Work':
        emailField = 'npe01__WorkEmail__c';
        break;
      case 'Alternate':
        emailField = 'npe01__AlternateEmail__c';
        break;
      default:
        emailField = 'Email';
    }
    component.set('v.emailField', emailField);
  },
  getStatesHelper : function(){
    return [{label: 'Alabama', value: 'AL'},{label: 'Alaska', value: 'AK'},{label: 'Arizona', value: 'AZ'},{label: 'Arkansas', value: 'AR'},{label: 'California', value: 'CA'},{label: 'Colorado', value: 'CO'},{label: 'Connecticut', value: 'CT'},{label: 'Delaware', value: 'DE'},{label: 'Florida', value: 'FL'},{label: 'Georgia', value: 'GA'},{label: 'Hawaii', value: 'HI'},{label: 'Idaho', value: 'ID'},{label: 'Illinois', value: 'IL'},{label: 'Indiana', value: 'IN'},{label: 'Iowa', value: 'IA'},{label: 'Kansas', value: 'KS'},{label: 'Kentucky', value: 'KY'},{label: 'Louisiana', value: 'LA'},{label: 'Maine', value: 'ME'},{label: 'Maryland', value: 'MD'},{label: 'Massachusetts', value: 'MA'},{label: 'Michigan', value: 'MI'},{label: 'Minnesota', value: 'MN'},{label: 'Mississippi', value: 'MS'},{label: 'Missouri', value: 'MO'},{label: 'Montana', value: 'MT'},{label: 'Nebraska', value: 'NE'},{label: 'Nevada', value: 'NV'},{label: 'New Hampshire', value: 'NH'},{label: 'New Jersey', value: 'NJ'},{label: 'New Mexico', value: 'NM'},{label: 'New York', value: 'NY'},{label: 'North Carolina', value: 'NC'},{label: 'North Dakota', value: 'ND'},{label: 'Ohio', value: 'OH'},{label: 'Oklahoma', value: 'OK'},{label: 'Oregon', value: 'OR'},{label: 'Pennsylvania', value: 'PA'},{label: 'Rhode Island', value: 'RI'},{label: 'South Carolina', value: 'SC'},{label: 'South Dakota', value: 'SD'},{label: 'Tennessee', value: 'TN'},{label: 'Texas', value: 'TX'},{label: 'Utah', value: 'UT'},{label: 'Vermont', value: 'VT'},{label: 'Virginia', value: 'VA'},{label: 'Washington', value: 'WA'},{label: 'West Virginia', value: 'WV'},{label: 'Wisconsin', value: 'WI'},{label: 'Wyoming', value: 'WY'}];
  },
  getCountriesHelper : function(){
    return ['Afghanistan','Albania','Algeria','Andorra','Angola','Antigua and Barbuda','Argentina','Armenia','Australia','Austria','Azerbaijan','The Bahamas','Bahrain','Bangladesh','Barbados','Belarus','Belgium','Belize','Benin','Bhutan','Bolivia','Bosnia and Herzegovina','Botswana','Brazil','Brunei','Bulgaria','Burkina Faso','Burundi','Cabo Verde','Cambodia','Cameroon','Canada','Central African Republic','Chad','Chile','China','Colombia','Comoros','Democratic Republic of the Congo','Republic of the Congo','Costa Rica','Côte d’Ivoire','Croatia','Cuba','Cyprus','Czech Republic','Denmark','Djibouti','Dominica','Dominican Republic','East Timor (Timor-Leste)','Ecuador','Egypt','El Salvador','Equatorial Guinea','Eritrea','Estonia','Eswatini','Ethiopia','Fiji','Finland','France','Gabon','The Gambia','Georgia','Germany','Ghana','Greece','Grenada','Guatemala','Guinea','Guinea-Bissau','Guyana','Haiti','Honduras','Hungary','Iceland','India','Indonesia','Iran','Iraq','Ireland','Israel','Italy','Jamaica','Japan','Jordan','Kazakhstan','Kenya','Kiribati','North Korea','South Korea','Kosovo','Kuwait','Kyrgyzstan','Laos','Latvia','Lebanon','Lesotho','Liberia','Libya','Liechtenstein','Lithuania','Luxembourg','Madagascar','Malawi','Malaysia','Maldives','Mali','Malta','Marshall Islands','Mauritania','Mauritius','Mexico','Micronesia, Federated States of','Moldova','Monaco','Mongolia','Montenegro','Morocco','Mozambique','Myanmar (Burma)','Namibia','Nauru','Nepal','Netherlands','New Zealand','Nicaragua','Niger','Nigeria','North Macedonia','Norway','Oman','Pakistan','Palau','Panama','Papua New Guinea','Paraguay','Peru','Philippines','Poland','Portugal','Qatar','Romania','Russia','Rwanda','Saint Kitts and Nevis','Saint Lucia','Saint Vincent and the Grenadines','Samoa','San Marino','Sao Tome and Principe','Saudi Arabia','Senegal','Serbia','Seychelles','Sierra Leone','Singapore','Slovakia','Slovenia','Solomon Islands','Somalia','South Africa','Spain','Sri Lanka','Sudan','Sudan, South','Suriname','Sweden','Switzerland','Syria','Taiwan','Tajikistan','Tanzania','Thailand','Togo','Tonga','Trinidad and Tobago','Tunisia','Turkey','Turkmenistan','Tuvalu','Uganda','Ukraine','United Arab Emirates','United Kingdom','United States','Uruguay','Uzbekistan','Vanuatu','Vatican City','Venezuela','Vietnam','Yemen','Zambia','Zimbabwe'];
  }
})