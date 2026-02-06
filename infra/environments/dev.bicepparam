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
param amount = 10
param startDate = '2026-01-01T00:00:00Z'
param endDate = '2026-12-31T23:59:59Z'


//=========ActionGroup==========//
param emailAddresses = ['sebqu@outlook.com' ]

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
param policyRequireTagOnResourcesId = '/providers/Microsoft.Authorization/policyDefinitions/d9a3c8d6-0a0c-4a2e-8d5f-3f5f1c9d3c6a'
param policyRequireTagOnRGId = '/providers/Microsoft.Authorization/policyDefinitions/4f9e5b1f-5f3c-4d3b-8a3b-1f3b0b1e1f3a'
