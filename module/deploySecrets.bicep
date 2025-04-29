param storageConnectionStringName string
param storageAccessKeyStringName string
param storageName string
param keyvaultName string


resource existingStorageDoneDeployed 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageName
}

// Determine our connection string
var storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${listKeys(resourceId(subscription().subscriptionId, resourceGroup().name, 'Microsoft.Storage/storageAccounts', storageName), existingStorageDoneDeployed.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
                                   
module keyvaultSecretDeploy1 'deployKeyVaultSecret.bicep' =  {
  name: '${keyvaultName}-Secret-${storageConnectionStringName}'

  params: {
    name: storageConnectionStringName
    value: storageAccountConnectionString
    keyVaultName: keyvaultName
    resourceExists: false
  }
}

module keyvaultSecretDeploy2 'deployKeyVaultSecret.bicep' =  {
  name: '${keyvaultName}-Secret-${storageAccessKeyStringName}'

  params: {
    name: storageAccessKeyStringName
    value: listKeys(resourceId(subscription().subscriptionId, resourceGroup().name, 'Microsoft.Storage/storageAccounts', storageName), existingStorageDoneDeployed.apiVersion).keys[0].value
    keyVaultName: keyvaultName
    resourceExists: false
  }
}
