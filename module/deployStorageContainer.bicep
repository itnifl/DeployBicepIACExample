
@maxLength(24)
@description('Required. Name of the Storage Account.')
param storageAccountName string

@maxLength(24)
@description('Required. Name of the Storage Account.')
param blobName string

@maxLength(24)
@description('Required. Name of the Storage Account.')
param containerName string



resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageAccountName
}


resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' existing = {
  name: ''
}


resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: '${storageAccountName}/default/${containerName}'

  properties: {
    immutableStorageWithVersioning: {
        enabled: false
    }
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
}

  dependsOn: [
    storageAccount
    blobService
  ]
}

