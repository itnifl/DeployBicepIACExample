@description('Required. Virtual network for DNS register')
param virtualNetwork_sb1vnetId string

@description('Required. Location of deployment')
param location string

@description('Required. Resource name prefix when creating resources')
param resourceNamePrefix string

@description('Required. Existing Private DNS zone name.')
param existingDnsZoneName string


resource privateDnsZone'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  name: existingDnsZoneName
}

resource privatelink_vaultcore_azure_net_subscriptions_Microsoft_Network_virtualNetworks_sb1vnet1 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${resourceNamePrefix}${uniqueString(deployment().name, location)}-PrivateDnsZone-VirtualNetworkLink'
  location: 'global'
  parent: privateDnsZone
  properties: {
    virtualNetwork: {
      id: virtualNetwork_sb1vnetId
    }
    registrationEnabled: false
  }
}
