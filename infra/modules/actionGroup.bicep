@description('Name of Action Group.')
param actionGroupName string

@description('Email Address for notification.')
param emailAddresses array

@description('Short name (<= 12 chars recommended).')
@maxLength(12)
param groupShortName string = 'ag-alz'

@description('Tags applayed to the Action Group.')
param tags object

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  tags: tags
  properties: {
    enabled: true
    groupShortName: groupShortName
    emailReceivers: [ for email in emailAddresses: {
      name: 'AlertEmail-${email}'
      emailAddress: email
      useCommonAlertSchema: true
    }]
  }
}

output actionGroupId string = actionGroup.id
