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


var rgSuffixes = ['monitor', 'shared', 'workloads']

module rgs 'modules/resourceGroup.bicep' = [for suffix in rgSuffixes: {
  name: 'rg-${suffix}'
  params: {
    location: location
    resourceGroupName: 'rg-${projectName}-${environment}-${suffix}'
    tags: commonTags
  }
}]

module bg 'modules/budget.bicep' = {
  name: 'budget'
  params: {
    budgetName: 'bud-${projectName}-${environment}'
    actionGroupId: actionGroupID
    amount: amount
    startDate: startDate
    endDate: endDate
  }
}
