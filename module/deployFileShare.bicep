@maxLength(24)
@description('Required. Name of the Storage Account.')
param storageAccountName string

@description('Optional. The name of the file service')
param fileServicesName string = 'default'

@description('Required. The name of the file share to create')
param name string

@description('Optional. Protocol settings for file service')
param protocolSettings object = {}

@description('Optional. The service properties for soft delete.')
param shareDeleteRetentionPolicy object = {
  enabled: true
  days: 7
}

@description('Optional. The maximum size of the share, in gigabytes. Must be greater than 0, and less than or equal to 5TB (5120). For Large File Shares, the maximum size is 102400.')
param sharedQuota int = 5120

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageAccountName
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2021-04-01' = {
  name: fileServicesName
  parent: storageAccount
  properties: {
    protocolSettings: protocolSettings
    shareDeleteRetentionPolicy: shareDeleteRetentionPolicy
  }
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-06-01' = {
  name: name
  parent: fileService
  properties: {
    shareQuota: sharedQuota
  }
}


@description('The name of the deployed file share')
output name string = fileShare.name

@description('The resource ID of the deployed file share')
output resourceId string = fileShare.id

@description('The resource group of the deployed file share')
output resourceGroupName string = resourceGroup().name
