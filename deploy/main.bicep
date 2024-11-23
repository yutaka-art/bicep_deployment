@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The type of environment. This must be nonprod or prod.')
@allowed([
  'nonprod'
  'prod'
])
param environmentType string

@description('Indicates whether to deploy the storage account for ameretat.')
param deployAmeretatManualsStorageAccount bool

@description('A unique suffix to add to resource names that need to be globally unique.')
@maxLength(13)
param resourceNameSuffix string = uniqueString(resourceGroup().id)

var appServiceAppName = 'ameretat-${resourceNameSuffix}'
var appServicePlanName = 'ameretat-plan'
var ameretatManualsStorageAccountName = 'ameretatweb${resourceNameSuffix}'

// Define the SKUs for each component based on the environment type.
var environmentConfigurationMap = {
  nonprod: {
    appServicePlan: {
      sku: {
        name: 'F1'
        capacity: 1
      }
    }
    ameretatManualsStorageAccount: {
      sku: {
        name: 'Standard_LRS'
      }
    }
  }
  prod: {
    appServicePlan: {
      sku: {
        name: 'S1'
        capacity: 2
      }
    }
    ameretatManualsStorageAccount: {
      sku: {
        name: 'Standard_ZRS'
      }
    }
  }
}

var ameretatManualsStorageAccountConnectionString = deployAmeretatManualsStorageAccount ? 'DefaultEndpointsProtocol=https;AccountName=${ameretatManualsStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${ameretatManualsStorageAccount.listKeys().keys[0].value}' : ''

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: environmentConfigurationMap[environmentType].appServicePlan.sku
}

resource appServiceApp 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'AmeretatManualsStorageAccountConnectionString'
          value: ameretatManualsStorageAccountConnectionString
        }
      ]
    }
  }
}

resource ameretatManualsStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = if (deployAmeretatManualsStorageAccount) {
  name: ameretatManualsStorageAccountName
  location: location
  kind: 'StorageV2'
  sku: environmentConfigurationMap[environmentType].ameretatManualsStorageAccount.sku
}