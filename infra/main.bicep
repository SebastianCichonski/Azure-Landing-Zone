targetScope = 'subscription'

param location string 
param projectName string
param environment string

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
