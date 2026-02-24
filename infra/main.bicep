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
param budgetAmount int

@description('Start date of budget.')
param budgetStartDate string

@description('End date of budget.')
param budgetEndDate string = ''

@description('Email Address for notification.')
param alertEmailAddresses array

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
param activityLogCategories ActivityLogCategory[]

type ActivityLogCategory =  'Administrative'
| 'Security'
| 'ServiceHealth'
| 'Alert'
| 'Recommendation'
| 'Policy'
| 'Autoscale'
| 'ResourceHealth'

var rgSuffixes = ['monitor', 'shared', 'workloads']
var tagsName = ['Owner', 'Environment', 'CostCenter']
var monitorRgName = 'rg-${projectName}-${environment}-monitor'

module rgs 'modules/resourceGroup.bicep' = [for suffix in rgSuffixes: {
  name: 'rg-${suffix}'
  params: {
    location: location
    resourceGroupName: 'rg-${projectName}-${environment}-${suffix}'
    tags: commonTags
  }
}]

module actionGroupMonitor 'modules/actionGroup.bicep' = {
  name: 'monitor-actionGroup'
  scope: resourceGroup(monitorRgName)
  dependsOn: [ rgs[0] ]
  params: {
    tags: commonTags
    actionGroupName: 'ag-${projectName}-${environment}'
    emailAddresses: alertEmailAddresses
  }
}

module budgetSubscription 'modules/budget.bicep' = {
  name: 'cost-budget'
  params: {
    budgetName: 'bud-${projectName}-${environment}'
    actionGroupId: actionGroupMonitor.outputs.actionGroupId
    amount: budgetAmount
    startDate: budgetStartDate
    endDate: budgetEndDate
  }
}

module rbacOps 'modules/rbac.bicep' = {
  name: 'iam-rbac-sgOps'
  params: {
    principalId: sgOpsId
    roleDefinitionGuid: rolesOps
  }
}

module rbacAudit 'modules/rbac.bicep' = {
  name: 'iam-rbac-sgAudit'
  params: {
    principalId: sgAuditId
    roleDefinitionGuid: rolesAudit
  }
}

module rbacDev 'modules/rbac.bicep' = {
  name: 'iam-rbac-sgDev'
  params: {
    principalId: sgDevId
    roleDefinitionGuid: rolesDev
  }
}

module policyAllowedLocations 'modules/policyAssignments.bicep' = {
  name: 'governance-pa-allowedLocations'
  params: {
    assignmentName: 'pa-${projectName}-${environment}-allowed-locations'
    displayName: 'Allowed Locations'
    policyDefinitionId: policyAllowedLocationsId
    nonComplianceMessage: 'Deployments are restricted to West Europe.'
    parameters: {
      listOfAllowedLocations: {
        value: [ 'westeurope' ]
      }
    }
  }
}

module policyRequireTagsOnResources 'modules/policyAssignments.bicep' = [for tagName in tagsName: {
  name: 'governance-pa-ReqTag${tagName}Res'
  params: {
    assignmentName: 'pa-${projectName}-${environment}-req-tag-${toLower(tagName)}-res'
    displayName: 'Require tag on resources (${tagName})'
    policyDefinitionId: policyRequireTagOnResourcesId
    nonComplianceMessage: 'Missing required tag: ${tagName}'
    parameters: {
      tag: {
        value: tagName
      }
    }
  }
}]

module policyRequireTagsOnResourceGroups 'modules/policyAssignments.bicep' = [for tagName in tagsName: {
  name: 'governance-pa-ReqTag${tagName}RG'
  params: {
    assignmentName: 'pa-${projectName}-${environment}-req-tag-${toLower(tagName)}-rg'
    displayName: 'Require tag on Resource Group (${tagName})'
    policyDefinitionId: policyRequireTagOnRGId
    nonComplianceMessage: 'Missing required tag: ${tagName}'
    parameters: {
      tag: {
        value: tagName
      }
    }
  }
}]

module logAnalyticsMonitor 'modules/logAnalytics.bicep' = {
  name: 'monitor-logAnalytics'
  scope: resourceGroup(monitorRgName)
  params: {
    workspaceName: 'law-${projectName}-${environment}'
    location: location
    tags: commonTags
  }
}


module diagSubscriptionActivityLogToLaw 'modules/diagnosticSettings.bicep' = {
  name: 'monitor-diag-activityLog'
  params: {
    diagName: 'diag-${projectName}-${environment}-sub-activity'
    workspaceId: logAnalyticsMonitor.outputs.workspaceId
    categories: activityLogCategories
  }
}
