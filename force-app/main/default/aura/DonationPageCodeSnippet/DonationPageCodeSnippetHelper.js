({
    retrieveCampaign : function(component) {
        console.log('retrieveCampaign');
        var action = component.get('c.retrieveCampaignRecordType');
        var dpSettingsId = component.get('v.recordId');
        console.log(dpSettingsId);

        action.setParams({
            settingsId: dpSettingsId
        });

        action.setCallback(this, function(result) {
            if (result.getState() === 'ERROR') {
                console.log('Error retrieving campaign: ', result.getError());
            } else {
                var res = result.getReturnValue();
                if(!res) {
                    console.log('No campaign found with the given id');
                }
                else {
                    component.set('v.campaignFields', res);
                }
            }
        });
        $A.enqueueAction(action);
    }
})