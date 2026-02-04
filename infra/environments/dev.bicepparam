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
param agDevId = '22180260-8d11-4b12-94c3-10908befe8ad'

//=========roleGuid==========//
param roleOwnerGuid = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
param roleReaderGuid = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
param roleMonitoringReaderGuid = '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
param roleLogAnalyticsReaderGuid = '73c42c96-874c-492b-b04d-ab87d138a893'
