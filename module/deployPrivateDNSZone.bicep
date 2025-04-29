param privateDNSZone_name string
param vnet_id string
param autoRegistrationEnabled bool
param virtualNetworkLinkName string

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDNSZone_name
  location: 'global'
  
  properties: {
    maxNumberOfRecordSets: 25000
    maxNumberOfVirtualNetworkLinks: 1000
    maxNumberOfVirtualNetworkLinksWithRegistration: 100
    numberOfRecordSets: 2
    numberOfVirtualNetworkLinks: 1
    numberOfVirtualNetworkLinksWithRegistration: 0
    provisioningState: 'Succeeded'
  }
}

resource Microsoft_Network_privateDnsZones_SOA_privateDnsZones_privatelink_servicebus_windows_net_name 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
  parent: privateDNSZone
  name: '@'
  properties: {
    ttl: 3600
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
  }
}

resource privateDnsZones_privatelink_servicebus_windows_net_name_qgzdwvfx2mc4c 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDNSZone
  name: virtualNetworkLinkName
  location: 'global'
  properties: {
    registrationEnabled: autoRegistrationEnabled
    virtualNetwork: {
      id: vnet_id
    }
  }
}

output privateDNSZoneId string = privateDNSZone.id
