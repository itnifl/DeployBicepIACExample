@description('Required. Subnet name')
param subnetName string

@description('Required. Address prefix of subnet')
param addressPrefix string

@description('Required. Private endpoint network policies')
@allowed([
  'Enabled'
  'Disabled'
])
param privateEndpointNetworkPolicies string

@description('Optional. Resource Id of NSG for the subnet')
param nsgId string = ''

@description('Optional. Array of delegations for the subnet')
param delegations array = []

param serviceEndpoints array = []


var sub =  {
  name: subnetName
  properties: {
    addressPrefix: addressPrefix
    privateEndpointNetworkPolicies: privateEndpointNetworkPolicies
    networkSecurityGroup: nsgId != '' ? {
      id: nsgId
    } : null
    delegations: !empty(delegations) ? delegations : null
    serviceEndpoints: !empty(serviceEndpoints) ? serviceEndpoints : null
  }
} 

output newSubnet object = sub
