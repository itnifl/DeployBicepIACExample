@description('Required. The storage name.')
@maxLength(24)
@minLength(3)
param storageName string

@description('Required. Location of deployment')
param location string

@description('Optional. Userassigned identity Id')
param userAssignedIdentityId string = ''

@description('Optional. Userassigned identity principal Id')
param storageContributorPrincipalId string = ''

@description('Optional. Required. Id of KeyVault to use. Required if userAssignedIdentityId is used')
param keyvaulturi string = ''

@description('Optional. Keyvault Key Name. Required if userAssignedIdentityId is used.')
param keyvaultKeyName string = ''

@description('Optional.')
@allowed([
  'Allow'
  'Deny'
])
param defaultnetworkAclsAction string = 'Deny'

@description('Optional. Storage SKU')
@allowed([
 'Premium_LRS'
 'Premium_ZRS'
 'Standard_GRS'
 'Standard_GZRS'
 'Standard_LRS'
 'Standard_RAGRS'
 'Standard_RAGZRS'
 'Standard_ZRS'
])
param storageSKU string = 'Standard_LRS'

@description('Optional. Storage Kind')
@allowed([
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
  'Storage'
  'StorageV2'
])
param storageKind string = 'StorageV2'

resource azurestorage001 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageName
  location: location

  sku: {
    name: storageSKU
  }
  kind: storageKind

  identity: {
    type: empty(userAssignedIdentityId) ? 'SystemAssigned' : 'UserAssigned'
    userAssignedIdentities: empty(userAssignedIdentityId) ? null : {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    allowCrossTenantReplication: true
    allowSharedKeyAccess: true
    
    defaultToOAuthAuthentication: false
    encryption: {
      identity: empty(userAssignedIdentityId) ? null : {
        userAssignedIdentity: userAssignedIdentityId
      }
      keySource:  empty(userAssignedIdentityId) ? 'Microsoft.Storage' : 'Microsoft.Keyvault'
      keyvaultproperties: empty(userAssignedIdentityId) ? null : {
          keyname: keyvaultKeyName
          keyvaulturi: keyvaulturi
        }
      requireInfrastructureEncryption: false

      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }        
      }    
    }
     
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: defaultnetworkAclsAction     
    }
    publicNetworkAccess: 'Enabled'
    supportsHttpsTrafficOnly: true
  }
}

resource sb1BlobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  name: 'default'
  parent: azurestorage001
  properties: {
    automaticSnapshotPolicyEnabled: true
    changeFeed: {
      enabled: false
    }
    containerDeleteRetentionPolicy: {
      days: 1
      enabled: false
    }
    cors: {
      corsRules: [
        {
          allowedHeaders: [ 
            '*'
          ]
          allowedMethods: [ 
            'DELETE' 
            'GET' 
            'HEAD' 
            'MERGE' 
            'OPTIONS' 
            'POST' 
            'PUT' 
          ]
          allowedOrigins: [ 
            '*' 
          ]
          exposedHeaders: [ 
            '*' 
          ]
          maxAgeInSeconds: 30
        }
      ]
    }
    defaultServiceVersion: '2008-10-27'
    deleteRetentionPolicy: {
      days: 1
      enabled: false
    }
    isVersioningEnabled: false
    lastAccessTimeTrackingPolicy: {
      enable: true
      name: 'AccessTimeTracking'
      trackingGranularityInDays: 3
    }
    restorePolicy: {
      enabled: false
    }
  }
}

var roleAssignments = !empty(storageContributorPrincipalId) ? [
  {
    roleDefinitionIdOrName: 'Contributor'
    principalIds: [
      storageContributorPrincipalId
    ]
  }
] : []

module storageAccount_rbac 'set_storage_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${uniqueString(deployment().name, location)}-Storage-Rbac-${index}'
  params: {
    principalIds: roleAssignment.principalIds
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    resourceId: azurestorage001.id
  }
}]


output storageAccountId string = azurestorage001.id
output storageAccountName string = azurestorage001.name
