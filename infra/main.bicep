targetScope = 'subscription'

@description('Azure region for the Resource Group.')
@allowed(['westeurope'])
param location string 

@description('The name of the project.')
@minLength(2)
@maxLength(12)
param projectName string

@description('Deployment evironment.')
@allowed(['prod', 'dev'])
param environment string

@description('Common tags applaied to all resource.')
param commonTags object 

@description('Amount of budget.')
param amount int

@description('Start date of budget.')
param startDate string

@description('End date of budget.')
param endDate string = ''

@description('Email Address for notification.')
param emailAddresses array

@description('Principal ID.')
param sgAuditId string

@description('Principal ID.')
param sgOpsId string

@description('Principal ID.')
param sgDevId string

@description('Role GUID.')
param rolesAudit array

@description('Role GUID.')
param rolesOps array

@description('Role GUID.')
param rolesDev array

@description('')
param policyAllowedLocationsId string

@description('')
param policyRequireTagOnResourcesId string

@description('')
param policyRequireTagOnRGId string

@description('Carogories of Activity Log')
param categories string[]

var rgSuffixes = ['monitor', 'shared', 'workloads']
var monitorRgName = 'rg-${projectName}-${environment}-monitor'

module rgs 'modules/resourceGroup.bicep' = [for suffix in rgSuffixes: {
  name: 'rg-${suffix}'
  params: {
    location: location
    resourceGroupName: 'rg-${projectName}-${environment}-${suffix}'
    tags: commonTags
  }
}]

module ag 'modules/actionGroup.bicep' = {
  name: 'actionGroup'
  scope: resourceGroup(monitorRgName)
  dependsOn: [ rgs[0] ]
  params: {
    tags: commonTags
    actionGroupName: 'ag-${projectName}-${environment}'
    emailAddresses: emailAddresses
  }
}

module bg 'modules/budget.bicep' = {
  name: 'budget'
  params: {
    budgetName: 'bud-${projectName}-${environment}'
    actionGroupId: ag.outputs.actionGroupId
    amount: amount
    startDate: startDate
    endDate: endDate
  }
}

module rbacOps 'modules/rbac.bicep' = {
  name: 'rbac-sgOps'
  params: {
    principalId: sgOpsId
    roleDefinitionGuid: rolesOps
  }
}

module rbacAudit'modules/rbac.bicep' = {
  name: 'rbac-sgAudit'
  params: {
    principalId: sgAuditId
    roleDefinitionGuid: rolesAudit
  }
}


module rbacDev 'modules/rbac.bicep' = {
  name: 'rbac-sgDev'
  params: {
    principalId: sgDevId
    roleDefinitionGuid: rolesDev
  }
}

module paAllowLoc 'modules/policyAssignments.bicep' = {
  name: 'paAllowedLocations'
  params: {
    assignmentName: 'pa-${projectName}-${environment}-allowed-locations'
    displayName: 'Allowed Locations'
    policyDefinitionId: policyAllowedLocationsId
    nonComplianceMessage: 'Resources must be deployed only in approved regions.'
    parameters: {
      listOfAllowedLocations: {
        value: [ 'westeurope' ]
      }
    }
  }
}

var tagsName = ['Owner', 'Environment', 'CostCenter']

module paReqTagOnRes 'modules/policyAssignments.bicep' = [for tagName in tagsName: {
  name: 'paReqTag${tagName}Res'
  params: {
    assignmentName: 'pa-${projectName}-${environment}-req-tag-${toLower(tagName)}-res'
    displayName: 'Require tag on resources (${tagName})'
    policyDefinitionId: policyRequireTagOnResourcesId
    nonComplianceMessage: 'Resources must have a tag: ${tagName}'
    parameters: {
      tag: {
        value: tagName
      }
    }
  }
}]

module paReqTagOnRG 'modules/policyAssignments.bicep' = [for tagName in tagsName: {
  name: 'paReqTag${tagName}RG'
  params: {
    assignmentName: 'pa-${projectName}-${environment}-req-tag-${toLower(tagName)}-rg'
    displayName: 'Require tag on Resource Group (${tagName})'
    policyDefinitionId: policyRequireTagOnResourcesId
    nonComplianceMessage: 'Resource Group must have a tag: ${tagName}'
    parameters: {
      tag: {
        value: tagName
      }
    }
  }
}]

module diagSettingsAL 'modules/diagnosticSettings.bicep' = {
  name: 'diagnosticSettingsAL'
  params: {
    diagName: 'dsLA-${projectName}-${environment}'
    workspaceId: alWorkspaceID
    categories: categories
  }
}
