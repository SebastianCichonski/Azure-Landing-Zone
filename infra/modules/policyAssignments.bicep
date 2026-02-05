targetScope = 'subscription'

@description('Name of policy assignment.')
param assignmentName string

@description('Display name shown in Azure.')
param displayName string

@description('ID of policy definition.')
param policyDefinitionId string

@description('Scope object.')
param scope object = subscription()

@description('Policy parameter. Format: { paramName: { value: ... } }.')
param parameters object = {}

@description('User-assigned identity.')
param userAssignedIdentities object = {}

@description('Manage identity type for the assigment.')
param identityType string = 'None' 

@description('Non-compliance message shown in Azure.')
param nonComplianceMessage string = ''

@description('Location for the policy assignment.')
param location string = deployment().location

var identityBlock = identityType == 'UserAssigned'
  ? {
    type: identityType
    userAssignedIdentities: userAssignedIdentities
  }
  : {
    type: identityType
  }

resource assignment 'Microsoft.Authorization/policyAssignments@2025-03-01' = {
  name: assignmentName
  scope: scope
  location: location
  identity: identityBlock
  properties: {
    displayName: displayName
    policyDefinitionId: policyDefinitionId
    parameters: parameters
    nonComplianceMessages: empty(nonComplianceMessage) ? [] : [
      {
        message: nonComplianceMessage
      }
    ] 
  }
}
