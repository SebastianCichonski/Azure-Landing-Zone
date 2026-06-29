using '../main.bicep'

param environment = 'dev'
param location = 'westeurope'
param projectName = 'alz'

param commonTags = {
  Environment: environment
  Owner: 'Sebastian'
  CostCenter: '1001-LAB'
}


//=========Budget=============//
param budgetAmount = 10
param budgetStartDate = '2026-06-01T00:00:00Z'
param budgetEndDate = '2026-12-31T23:59:59Z'


//=========ActionGroup==========//
param alertEmailAddresses = ['sebqu@outlook.com' ]

//======secGroupId=============//
param sgAuditId = 'a5704b10-e51a-4079-91ac-c50bd0f07b30'
param sgOpsId = 'dcf69358-6cc2-449f-9776-4347252a9835'
param sgDevId = '22180260-8d11-4b12-94c3-10908befe8ad'

//=========roleGuid==========//
var roleGuid = {
  contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  monitoringReader: '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
  logAnalyticsReader: '73c42c96-874c-492b-b04d-ab87d138a893'
}

//========roleDefinitionPerGroup====//
param rolesAudit = [
  roleGuid.reader
]

param rolesOps = [
  roleGuid.logAnalyticsReader
  roleGuid.monitoringReader
]

param rolesDev = [
  roleGuid.contributor
]

//============policeId's=========//
param policyAllowedLocationsId = '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'
param policyRequireTagOnResourcesId = '/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99'
param policyRequireTagOnRGId = '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'

//==========diagnosticSettings===//
param activityLogCategories = [
  'Administrative'
  'Security'
  'Alert'
  'Policy'
]
