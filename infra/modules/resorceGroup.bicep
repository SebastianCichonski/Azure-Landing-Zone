
targetScope = 'subscription'

@description('Name of the Resource Group.')
@minLength(1)
param resourceGroupName string

@description('Azure region for the Resource Group.')
param location string

@description('Tags applayed to the Resource Group')
param tags object


resource rg 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

output rgName string = rg.name
