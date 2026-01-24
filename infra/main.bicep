
param location string = 'westeurope'
param projectName string = 'alz'
param environment string = 'dev'

param commonTags object = {
  Environment: environment
  Owner: 'Sebastian'
  CostCenter: '1001-LAB'
  
}

var rgMonitorName = 'rg-${projectName}-${environment}-monitor'
var rgSharedName = 'rg-${projectName}-${environment}-shared'
var rgWorkloadsName = 'rg-${projectName}-${environment}-workloads'

