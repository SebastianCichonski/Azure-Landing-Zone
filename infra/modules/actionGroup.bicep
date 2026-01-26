
param actionGroupName string
param location string
param emailaddress string

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: location
  properties: {
    enabled: true
    groupShortName: 'ag-alz'
    emailReceivers: {
      name: 'AlertEmialRecivier'
      emailAddress: emailAddress
      useCommonAlertShema: true
    }
  }

}
