
targetScope = 'subscription'

@minLength(36)
@maxLength(36)
@description('Object ID of the principal.')
param principalId string

@minLength(1)
@description('Role definition GUID.')
param roleDefinitionGuid array

@description('Type of principal for the role assignment.')
@allowed([
  'Group'
  'User'
  'ServicePrincipal'
  'ForeignGroup'
  'Device'
  'MSI'
])
param principalType string = 'Group'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for roleGuid in roleDefinitionGuid: {
    name: guid(subscription().id, principalId, subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleGuid))
    scope: subscription()
    properties: {
      principalId: principalId
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleGuid)
      principalType: principalType
    }
  }
]
