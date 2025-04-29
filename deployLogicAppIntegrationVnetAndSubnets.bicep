@description('Location of deployment')
param location string

@description('Prefix for name of resources in deployment')
@allowed([
  'dev'
  'prod'
  'test'
 ])
param resourceNamePrefix string = 'dev'

var subnetNumber = resourceNamePrefix == 'dev' ? 0 : (resourceNamePrefix == 'test' ? 1 : 2)

module azSubnetDefault 'module/deploySubnet.bicep' =  {  
  name: '${resourceNamePrefix}-subnet-az'

  params: {
    subnetName: 'default'
    addressPrefix: '10.${subnetNumber}.0.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    serviceEndpoints: [
      {
          service: 'Microsoft.KeyVault'
          locations: [
              '*'
          ]
      }
      {
        service: 'Microsoft.ServiceBus'
        locations: [
            '*'
        ]
    }
    ]
  }
}

var azSubnetLaSubInbound = '${resourceNamePrefix}-la-sub-inbound'
module azSubnet1 'module/deploySubnet.bicep' =  {  
  name: '${resourceNamePrefix}-subnet1-az'

  params: {
    subnetName: azSubnetLaSubInbound
    addressPrefix: '10.${subnetNumber}.1.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    serviceEndpoints: [
      {
        service: 'Microsoft.AzureCosmosDB'
        locations: [
          '*'
        ]

      }
      {
          service: 'Microsoft.KeyVault'
          locations: [
              '*'
          ]
      }
    ]
  }
}


var azSubnetSbus = '${resourceNamePrefix}-azintegrate-sbus'
module azSubnet2 'module/deploySubnet.bicep' =  {  
  name: '${resourceNamePrefix}-subnet2-az'

  params: {
    subnetName: azSubnetSbus
    addressPrefix: '10.${subnetNumber}.2.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    serviceEndpoints: [
      {
          service: 'Microsoft.ServiceBus'
          locations: [
              '*'
          ]
      }
      {
          service: 'Microsoft.KeyVault'
          locations: [
              '*'
          ]
      }
    ]
  }
}


var azSubnetLaSubOutbound = '${resourceNamePrefix}-la-sub-outbound'
module azSubnet3 'module/deploySubnet.bicep' =  {  
  name: '${resourceNamePrefix}-subnet3-az'

  params: {
    subnetName: azSubnetLaSubOutbound
    addressPrefix: '10.${subnetNumber}.3.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    delegations: [
          {
            name: 'delegation'
            properties: {
              serviceName: 'Microsoft.Web/serverfarms'
            }
          }
        ]
    serviceEndpoints: [
      {
        service: 'Microsoft.AzureCosmosDB'
        locations: [
          '*'
        ]

      }
      {
          service: 'Microsoft.KeyVault'
          locations: [
              '*'
          ]
      }
    ]
  }
}

var azSubnetiothub = '${resourceNamePrefix}-azintegrate-iothub'
module azSubnet4 'module/deploySubnet.bicep' =  {  
  name: '${resourceNamePrefix}-subnet4-az'

  params: {
    subnetName: azSubnetiothub
    addressPrefix: '10.${subnetNumber}.4.0/24'
    privateEndpointNetworkPolicies: 'Disabled'

    serviceEndpoints: [
      {
          service: 'Microsoft.KeyVault'
          locations: [
              '*'
          ]
      }
      {
        service: 'Microsoft.ServiceBus'
        locations: [
          '*'
        ]
      }
    ]
  }
}


var azSubnetKeyvault = '${resourceNamePrefix}-azintegrate-keyvault'
module azSubnet5 'module/deploySubnet.bicep' =  {  
  name: '${resourceNamePrefix}-subnet5-az'

  params: {
    subnetName: azSubnetKeyvault
    addressPrefix: '10.${subnetNumber}.5.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    serviceEndpoints: [
      {
          service: 'Microsoft.KeyVault'
          locations: [
              '*'
          ]
      }
    ]
  }
}

var azSubnetCosmosDb = '${resourceNamePrefix}-azintegrate-cosmosdb'
module azSubnet6 'module/deploySubnet.bicep' =  {  
  name: '${resourceNamePrefix}-subnet6-az'

  params: {
    subnetName: azSubnetCosmosDb
    addressPrefix: '10.${subnetNumber}.6.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    serviceEndpoints: [
      {
        service: 'Microsoft.AzureCosmosDB'
        locations: [
          '*'
        ]

      }
      {
          service: 'Microsoft.KeyVault'
          locations: [
              '*'
          ]
      }
      {
        service: 'Microsoft.AzureCosmosDB'
        locations: [
          '*'
      ]
      }
    ]
  }
}

var azSubnetStorage = '${resourceNamePrefix}-azintegrate-blobstorage'
module azSubnet7 'module/deploySubnet.bicep' =  {  
  name: '${resourceNamePrefix}-subnet7-az'

  params: {
    subnetName: azSubnetStorage
    addressPrefix: '10.${subnetNumber}.7.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    serviceEndpoints: [
      {
          service: 'Microsoft.KeyVault'
          locations: [
              '*'
          ]
      }
      {
        service: 'Microsoft.Storage'
        locations: [
          '*'
      ]
      }
    ]
  }
}


var azVnetName = '${resourceNamePrefix}-vnet-az'
var tagName = 'vnetIsDeployed'

resource vnetIsDeployed 'Microsoft.Resources/tags@2021-04-01' existing = {
  name: 'default'
}

var resourceExists = contains(vnetIsDeployed.properties.tags, tagName) && vnetIsDeployed.properties.tags[tagName] == 'true' 


module azVnet 'module/deployVnet.bicep' =  {
  name: azVnetName
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceExists: resourceExists
    location: location
    vnetName: azVnetName
    subnets: [
        azSubnetDefault.outputs.newSubnet
        azSubnet1.outputs.newSubnet
        azSubnet2.outputs.newSubnet
        azSubnet3.outputs.newSubnet
        azSubnet4.outputs.newSubnet
        azSubnet5.outputs.newSubnet
        azSubnet6.outputs.newSubnet
        azSubnet7.outputs.newSubnet
      ]
  }
  dependsOn: [
    azSubnetDefault
    azSubnet1
    azSubnet2
    azSubnet3
    azSubnet4
    azSubnet5
    azSubnet6
    azSubnet7
  ]
}


module privateDNSZone1 'module/deployPrivateDNSZone.bicep' = {
  name: '${resourceNamePrefix}-privateDNSZoneaz'
  params: {
    vnet_id: azVnet.outputs.newVnetResourceId
    privateDNSZone_name: 'privatelink.azurewebsites.net'
    autoRegistrationEnabled: true
    virtualNetworkLinkName: 'azLink'
  }
}

module privateDNSZone2 'module/deployPrivateDNSZone.bicep' = {
  name: '${resourceNamePrefix}-privateSBDNSZoneaz'
  params: {
    vnet_id: azVnet.outputs.newVnetResourceId
    privateDNSZone_name: 'privatelink.servicebus.windows.net'
    autoRegistrationEnabled: false
    virtualNetworkLinkName: 'servicebus-azLink'
  }
}

module privateDNSZoneBlobStorage 'module/deployPrivateDNSZone.bicep' = {
  name: '${resourceNamePrefix}-privateBlobStorageDNSZoneaz'
  params: {
    vnet_id: azVnet.outputs.newVnetResourceId
    privateDNSZone_name: 'privatelink.blob.${environment().suffixes.storage}'
    autoRegistrationEnabled: false
    virtualNetworkLinkName: 'blobstorage-azLink'
  }
}


module privateKeyVaultDNSZone 'module/deployPrivateDNSZone.bicep' = {
  name: '${resourceNamePrefix}-privateKeyVaultDNSZoneaz'
  params: {
    vnet_id: azVnet.outputs.newVnetResourceId
    privateDNSZone_name: 'privatelink${environment().suffixes.keyvaultDns}'
    autoRegistrationEnabled: false
    virtualNetworkLinkName: 'keyvault-azLink'
  }
}

module privateCosmosDbDNSZone 'module/deployPrivateDNSZone.bicep' = {
  name: '${resourceNamePrefix}-privateCosmosDbDNSZoneaz'
  params: {
    vnet_id: azVnet.outputs.newVnetResourceId
    privateDNSZone_name: 'privatelink.document.azure.com'
    autoRegistrationEnabled: false
    virtualNetworkLinkName: 'document-azLink'
  }
}

module privateIotHubDnsZone 'module/deployPrivateDNSZone.bicep' = {
  name: '${resourceNamePrefix}-privateIotHubDNSZoneaz'
  params: {
    vnet_id: azVnet.outputs.newVnetResourceId
    privateDNSZone_name: 'privatelink.azure-devices.net'
    autoRegistrationEnabled: false
    virtualNetworkLinkName: 'azure-devices.net-azLink'
  }
}
