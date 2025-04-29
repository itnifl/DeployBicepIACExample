@description('Required. Location of deployment')
param location string

@description('Required. Name of the new VNET')
param vnetName string

@description('Required. Subnets to deploy with the VNET')
param subnets array

param resourceExists bool = false

@description('Required. Prefix for name of resources in deployment')
@allowed([
  'dev'
  'prod'
  'test'
 ])
param resourceNamePrefix string

var subnetNumber = resourceNamePrefix == 'dev' ? 0 : (resourceNamePrefix == 'test' ? 1 : 2)

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-11-01' = if(resourceExists == false) {
  name: vnetName
  location: location

  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.${subnetNumber}.0.0/16'
      ]
    }
    virtualNetworkPeerings: []
    enableDdosProtection: false
	  subnets: subnets
  }
}

output newVnetName string = virtualNetwork.name
output newVnetResourceId string = virtualNetwork.id
