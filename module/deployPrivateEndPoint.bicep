@description('Required. The Endpoint name.')
param endpointName string

@description('Required. Location of deployment')
param location string

@description('Required. SubnetId for Private Endpoint')
param subnetId string

@description('Required. Service Id to be connected to Private Endpoint')
param attachedAccountId string

@description('Required. Group Ids of privateLinkServiceConnections. Subtype(s) of the connection to be created. The allowed values depend on the type serviceResourceId refers to.')
param groupIds array

@description('Required. Private DNS zone name.')
param privateDnsZoneId string

resource sb1privateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: endpointName
  location: location  

  properties: {  
    privateLinkServiceConnections: [
      {
        id: subnetId
        name: endpointName
        properties: {
          groupIds: groupIds
          privateLinkServiceId: attachedAccountId
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource privateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  parent: sb1privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink.sbm1.com'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

var endpointIpConfigs = sb1privateEndpoint.properties.ipConfigurations

output endpointId string = sb1privateEndpoint.id
output endpointName string = sb1privateEndpoint.name
output endpointPrivateIp string = !empty(endpointIpConfigs) ? endpointIpConfigs[0].properties.privateIPAddress : ''
