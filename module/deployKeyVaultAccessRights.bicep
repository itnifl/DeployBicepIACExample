param keyvaultName string
param deployLocation string

@description('Required. Array of principal Ids to have access to the vault')
param variousOtherPrincipalIdsForKeyvault array
param newIdentityPrincipalId string

var dnsZoneName = 'privatelink${environment().suffixes.keyvaultDns}'
var keyvaultSku = 'standard'

var principalIdsForKeyvaultUnion = union(variousOtherPrincipalIdsForKeyvault, [newIdentityPrincipalId])

var accessRights  = [for principalId in principalIdsForKeyvaultUnion: {    
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

resource sb1Keyvault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyvaultName
  location: deployLocation
  properties: {
    vaultUri: 'https://${keyvaultName}.${dnsZoneName}/'
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
      defaultAction: 'Allow'  
      virtualNetworkRules: []
      ipRules: []
    }
  }
}
