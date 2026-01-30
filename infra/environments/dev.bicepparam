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
