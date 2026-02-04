
targetScope = 'subscription'

@minLength(36)
@maxLength(36)
@description('Object ID of the principal.')
param principalId string

@minLength(36)
@maxLength(36)
@description('Role definition GUID.')
param roleDefinitionGuid string

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

var roleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionGuid)

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, roleDefinitionId)
  scope: subscription()
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    principalType: principalType
  }
}
