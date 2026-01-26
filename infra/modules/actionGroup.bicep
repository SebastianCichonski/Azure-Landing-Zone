@description('Name of Action Group.')
param actionGroupName string

@description('Azure region for the Action Group.')
param location string

@description('Email Address for notification.')
param emailAddress string

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: location
  properties: {
    enabled: true
    groupShortName: 'ag-alz'
    emailReceivers: [{
      name: 'AlertEmialRecivier'
      emailAddress: emailAddress
      useCommonAlertSchema: true
    }]
  }
}

output actionGroupId string = actionGroup.id
