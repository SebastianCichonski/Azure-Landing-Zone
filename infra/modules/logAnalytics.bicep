targetScope = 'resourceGroup'

@description('Log Analytics Workspace name.')
param workspaceName string

@description('Location for the workspace (should match RG location).')
param location string

@description('Tags applied to the workspace.')
param tags object = {}

@description('Retention in days (30–730).')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Daily ingestion cap in GB. 0 means unlimited.')
@minValue(0)
param dailyQuotaGb int = 1

@description('SKU for Log Analytics.')
@allowed([
  'PerGB2018'
])
param skuName string = 'PerGB2018'

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: skuName
    }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output workspaceId string = law.id       
