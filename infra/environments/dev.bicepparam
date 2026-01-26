using '../main.bicep'

param environment = 'dev'
param location = 'westeurope'
param projectName = 'alz'

param commonTags = {
  Environment: environment
  Owner: 'Sebastian'
  CostCenter: '1001-LAB'
}

param amount = 10
param startDate = '2026-01-01T00:00:00Z'
param endDate = '2026-12-31T23:59:59Z'

param emailAddresses = ['sebqu@outlook.com' ]
