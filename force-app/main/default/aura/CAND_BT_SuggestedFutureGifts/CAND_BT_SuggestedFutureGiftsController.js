({
  handlePopulateFutureGifts: function (component, event) {
    // given an account
    // retrieve all future gifts where stage = committment confirmed
    // and record type is major gift
    let accountId = component.get('v.accountId');
    if (accountId)  {
      component.set('v.loading', true);
      let _getFutureGifts = component.get('c.getFutureGifts');
      _getFutureGifts.setParams({
        accountId: accountId
      });
      _getFutureGifts.setCallback(this, res => {
        if (res.getState() === 'SUCCESS') {
          let fgs = res.getReturnValue();          
          component.set('v.futureGifts', fgs);
          component.set('v.loading', false);
        } else {
          component.set('v.loading', false);
          console.error('ERROR:', res.getErrors()[0].message);
          component.find('notifications').showNotice({
            header: 'Error!',
            variant: 'error',
            message: res.getErrors()[0].message
          });
        }
      });
      $A.enqueueAction(_getFutureGifts);
    }
  },

  handleCopyFutureGift: function (component, event) {
    let selectFutureGiftEvent = component.getEvent('CAND_BT_SelectThisFutureGift');
    selectFutureGiftEvent.setParams({
      futureGift: event.getSource().get('v.value')
    });
    selectFutureGiftEvent.fire();
  }
})