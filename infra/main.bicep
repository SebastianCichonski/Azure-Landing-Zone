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

var rgSuffixes = ['monitor', 'shared', 'workloads']

module rgs 'modules/resourceGroup.bicep' = [for suffix in rgSuffixes: {
  name: 'rg-${suffix}'
  params: {
    location: location
    resourceGroupName: 'rg-${projectName}-${environment}-${suffix}'
    tags: commonTags
  }
}]
