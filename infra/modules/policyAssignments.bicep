targetScope = 'subscription'

param assignmentName string
param displayName string
param policyDefinitionId string
param scope object = subscription()
param parameters object = {}
param userAssignedIdentities object = {}
param identityType string = 'None' 
param nonComplianceMessage string = ''
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
