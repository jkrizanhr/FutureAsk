// Facebook analytics
!function(f,b,e,v,n,t,s)
{if(f.fbq)return;n=f.fbq=function(){n.callMethod?
n.callMethod.apply(n,arguments):n.queue.push(arguments)};
if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
n.queue=[];t=b.createElement(e);t.async=!0;
t.src=v;s=b.getElementsByTagName(e)[0];
s.parentNode.insertBefore(t,s)}(window, document,'script',
'https://connect.facebook.net/en_US/fbevents.js');
fbq('init', '1167480306621215');
fbq('track', 'PageView');

// Google analytics
(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','https://www.google-analytics.com/analytics.js','ga');
ga('create', 'UA-143317823-2', 'auto');
ga('send', 'pageview');

window.addEventListener('message', function(e) {
  if (e.data && e.data.type === 'messageFromForm') {
    console.log('Conversion message received.');
    var conversion = e.data.value;
    fireAnalytics(conversion.donationId, conversion.idOrUtm, conversion.total, conversion.currency);
  } else {
    iframe_resize(e);
  }
});

var iframe_resize = function (event) {
  if (event.origin !== 'https://donor-donate.cs123.force.com') {
    return;
  }
  var donation_iframe = document.getElementById('donationFormIframe');
  if (donation_iframe) {
    donation_iframe.style.height = event.data + 'px';
  }
};

window.onload = function () {
  var iFrameWindow = document.getElementById('donationFormIframe').contentWindow;
  var urlSplit = window.location.search.split('?');
  if(urlSplit && urlSplit[1]){ 
    var urlParams = urlSplit[1].split('&');
    var utmParam = null;
    var utmSource = null;
    var utmMedium = null;
    var contactId = null;
    var accountId = null;
    var donationAmount = null;
    var source = null;
    var finalParameters = [{ value: true, type: 'donationPageParams' }];
    for (let param of urlParams) {
      if (param.includes('utm_campaign')) { 
        utmParam = param.split('=')[1];
        finalParameters.push({ value: utmParam, type: 'utm_campaign' });
      } 
      if (param.includes('utm_source')) { 
        utmSource = param.split('=')[1];
        finalParameters.push({ value: utmSource, type: 'utm_source' });
      } 
      if (param.includes('utm_medium')) { 
        utmMedium = param.split('=')[1];
        finalParameters.push({ value: utmMedium, type: 'utm_medium' });
      } 
      if (param.includes('contact_id')) {
        contactId = param.split('=')[1];
        finalParameters.push({ value: contactId, type: 'contact_id' });
      }
      if (param.includes('account_id')) {
        accountId = param.split('=')[1];
        finalParameters.push({ value: accountId, type: 'account_id' });
      }
      if (param.includes('donation_amount')) {
        donationAmount = param.split('=')[1];
        finalParameters.push({ value: donationAmount, type: 'donation_amount' });
      }
      if (param.includes('source')) {
        source = param.split('=')[1];
        finalParameters.push({ value: source, type: 'source' });
      }
    }
    iFrameWindow.postMessage(finalParameters, window.location.origin); 
  }
}

var fireAnalytics = function(donationId, idOrUtm, total, currency) {
  fbq('track', 'Donate', {
    currency: currency, 
    value: total, 
    content_name: idOrUtm
  });
  ga('send', 'event', 'Donor Conversion', idOrUtm);  // Campaign Name or Code along with conversion type: Name or Donor.
  ga('require', 'ecommerce');
  ga('ecommerce:addTransaction', {
  'id': donationId,                            // DFS ID.
  'revenue': total,                     // Grand Total - without a dollar sign.
  'currency': currency  // Currency Code.
  });
  ga('ecommerce:send');
}
