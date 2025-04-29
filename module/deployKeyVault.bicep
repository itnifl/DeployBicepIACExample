@minLength(3)
@description('Required. Location of deployment')
param location string

@minLength(3)
@maxLength(34)
@description('Required. Key Vault Name')
param keyVaultName string

@description('Required. Array of principal Ids to have access to the vault')
param principalIds array

@description('Required. Enable Public Network Access?')
param enablePublicNetworkAccess bool

@description('Optional. Virtual Network Rules')
param virtualNetworkRules array = []

@description('Optional. Firewall Rules')
param ipRules array = []

param dnsZoneName string = environment().suffixes.keyvaultDns

@description('Optional. KeyVault SKU')
@allowed([
  'premium'
  'standard'
])
param keyvaultSku string = 'standard'

var accessRights  = [for principalId in principalIds: {    
    objectId: principalId
    permissions: {
      certificates: [
        'all'
      ]
      keys: [
        'all'
      ]
      secrets: [
        'all'
      ]
      storage: [
        'all'
      ]
    }
    tenantId: subscription().tenantId
}]

resource sb1Keyvault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    vaultUri: 'https://${keyVaultName}${dnsZoneName}/'
    publicNetworkAccess: enablePublicNetworkAccess ? 'Enabled' : 'Disabled'
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: false
    accessPolicies: accessRights
    tenantId: subscription().tenantId
    sku: {
      name: keyvaultSku
      family: 'A'
    }

    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: empty(virtualNetworkRules) ? 'Allow' : 'Deny'   
      virtualNetworkRules: virtualNetworkRules 
      ipRules: ipRules 
    }
  }
}


output keyvaulturi string = sb1Keyvault.properties.vaultUri
output keyvaultId string = sb1Keyvault.id
output keyvaultName string = sb1Keyvault.name
