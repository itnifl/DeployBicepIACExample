@minLength(3)
param resourceNamePrefix string

@minLength(3)
param location string

var logicAppName ='${resourceNamePrefix}-azIntegration-la' 
var iotHubName ='${resourceNamePrefix}-iotHub-az'
var cosmosDbName ='${resourceNamePrefix}-cosmosdb-az'
var azVnetName = '${resourceNamePrefix}-vnet-az'

resource azVnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: azVnetName
}

var azSubnetSbus = '${resourceNamePrefix}-azintegrate-sbus'
var azSubnetSubOutbound = '${resourceNamePrefix}-la-sub-outbound'
var vnetSubLaOutboundResourceId = '${azVnet.id}/subnets/${azSubnetSubOutbound}'

var azSubnetSubInbound  = '${resourceNamePrefix}-la-sub-inbound'

var azSubnetDefault = 'default'
var azSubnetiotHub = '${resourceNamePrefix}-azintegrate-iothub'
var azSubnetKeyvault = '${resourceNamePrefix}-azintegrate-keyvault'
var azSubnetCosmosDb = '${resourceNamePrefix}-azintegrate-cosmosdb'
var azSubnetBlobStorage = '${resourceNamePrefix}-azintegrate-blobstorage'


var existingPrivateDNSZone_name = 'privatelink.azurewebsites.net'
var existingPrivateServiceBusDNSZone_name = 'privatelink.servicebus.windows.net'
var existingKeyVaultDNSZone_name =  'privatelink${environment().suffixes.keyvaultDns}'
var existingPrivateCosmosDbDNSZone_name = 'privatelink.document.azure.com'
var existingIotHubPrivateDNSZone_name = 'privatelink.azure-devices.net'
var existingBlobstorageDnsZone_name = 'privatelink.blob.${environment().suffixes.storage}'

var azSubnetIotHubId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', azVnetName, azSubnetiotHub)
var azSubnetSbusId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', azVnetName, azSubnetSbus)
var azSubnetSubInboundId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', azVnetName, azSubnetSubInbound)
var azSubnetSubOutboundId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', azVnetName, azSubnetSubOutbound)
var azSubnetDefaultId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', azVnetName, azSubnetDefault)
var azSubnetKeyvaultId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', azVnet.name, azSubnetKeyvault)
var azSubnetCosmosDbId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', azVnet.name, azSubnetCosmosDb)
var azSubnetBlobStorageId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', azVnet.name, azSubnetBlobStorage)

param keyVaultManagedAccessIdentity string = '${resourceNamePrefix}-az-secrets-accessidentity'
module kvAccessIdentity 'module/deployManagedIdentity.bicep' = {
  name: keyVaultManagedAccessIdentity

  params: {
    location: location
    name: keyVaultManagedAccessIdentity
  }
}

param sbManagedAccessIdentity string = '${resourceNamePrefix}-az-servicebus-accessidentity'
module sbAccessIdentity 'module/deployManagedIdentity.bicep' = {
  name: sbManagedAccessIdentity

  params: {
    location: location
    name: sbManagedAccessIdentity
  }
}

var theHostingPlanName = '${resourceNamePrefix}-logicapp-asp'
module logicappAspDeploy 'module/deployAsp.bicep' =  { 
  name: 'deploy-${theHostingPlanName}'
 
  params: {    
    deployLocation: location
    skuTier: 'WorkflowStandard'
    skuName: 'WS1'
    hostingPlanName: theHostingPlanName
  }
}

var storageName = toLower(length(logicAppName) > 15 ? replace('${substring(logicAppName, 0, 15)}1storage', '-', '') :  replace('${logicAppName}0storage', '-', ''))

module storageDeploymentLogicApp 'module/deployStorage.bicep' =  { 
  name: '${logicAppName}-storage'
  params: {    
    location: location
    storageName: storageName
    defaultnetworkAclsAction: 'Allow'
    storageSKU: 'Standard_LRS'
  }
}

var fileshareName1 = toLower('${logicAppName}share')
module fileshareDeployment1 'module/deployFileShare.bicep' =  { 
  name: '${fileshareName1}-deployment'
  params: {    
    storageAccountName: storageName
    name: fileshareName1
  }
  dependsOn: [
    storageDeploymentLogicApp
  ]
}

module applicationsInsightDeploy 'module/deployLoggingAndMonitoring.bicep' =  { 
  name: 'deploy-${resourceNamePrefix}-azintegrat-appInsights'
  params: {
    location: location
    logAnalyticsWorkspaceName:  '${resourceNamePrefix}-azintegrate-appInsights-ws'
    aiName: '${resourceNamePrefix}-azintegrate-appInsights'
  }
}

module logicappDeploy 'module/deployLogicAppStandard.bicep' = {
  name: 'deploy-${logicAppName}'
  params: {
    logicAppName: logicAppName
    deployLocation: location
    appServicePlanExtId: logicappAspDeploy.outputs.extId
    appInsightsEndpointConnectionString: applicationsInsightDeploy.outputs.appInsightsConnectionString
    appInsightsInstrKey: applicationsInsightDeploy.outputs.appInsightsInstrumentationKey
    storageName: storageName
    vnetResourceId: vnetSubLaOutboundResourceId
    fileshareName: fileshareName1
    enablePublicNetworkAccess: true
  }
  dependsOn: [
    storageDeploymentLogicApp
    fileshareDeployment1
    applicationsInsightDeploy
    logicappAspDeploy
  ]
}

var keyvaultName = '${resourceNamePrefix}-kv-4azIntegration'
module keyvaultDeploy 'module/deployKeyVault.bicep' =  { 
  name: 'deploy-${keyvaultName}'

  params: {
    location: location
    keyVaultName: keyvaultName
    dnsZoneName: environment().suffixes.keyvaultDns
    enablePublicNetworkAccess: true

    virtualNetworkRules: [
      {
        id: azSubnetIotHubId
        ignoreMissingVnetServiceEndpoint: false
      }
      {
        id: azSubnetSbusId
        ignoreMissingVnetServiceEndpoint: false
      }              
      {
        id: azSubnetSubOutboundId
        ignoreMissingVnetServiceEndpoint: false
      }         
      {
        id: azSubnetKeyvaultId
        ignoreMissingVnetServiceEndpoint: false
      }
      {
        id: azSubnetDefaultId
        ignoreMissingVnetServiceEndpoint: false
      }
      {
        id: azSubnetCosmosDbId
        ignoreMissingVnetServiceEndpoint: false
      }
      {
        id: azSubnetBlobStorageId
        ignoreMissingVnetServiceEndpoint: false
      }
    ]

    principalIds: [
      logicappDeploy.outputs.LogicAppIdentity
      kvAccessIdentity.outputs.managedIdentityId
    ]
  }
}

module secretsDeploy 'module/deploySecrets.bicep' = {
  name: 'deploySecrets-${logicAppName}'
  params: {
    keyvaultName: keyvaultDeploy.outputs.keyvaultName
    storageAccessKeyStringName: secretStorageAccessKeyStringName
    storageConnectionStringName: secretStorageConnectionStringName
    storageName: storageName
  }
  dependsOn: [    
    keyvaultDeploy
    storageDeploymentLogicApp    
    fileshareDeployment1
  ]
}


var baseAppSettings = [
  {
    name: 'APP_KIND'
    value: 'workflowApp'
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: applicationsInsightDeploy.outputs.appInsightsInstrumentationKey
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: applicationsInsightDeploy.outputs.appInsightsConnectionString
  }
  {
    name: 'AzureFunctionsJobHost__extensionBundle__id'
    value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
  }
  {
    name: 'AzureFunctionsJobHost__extensionBundle__version'
    value: '[1.*, 2.0.0)'
  }
  {
    name: 'AzureWebJobsStorage'
    value: secretStorageConnectionStringValue
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'node'
  }
  {
    name: 'WEBSITE_NODE_DEFAULT_VERSION'
    value: '~12'
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: secretStorageConnectionStringValue
  }
  {
    name: 'WEBSITE_CONTENTSHARE' //Requires an actual fileshare in an actual storageaccount
    value: fileshareName1
  }
]

var serviceBusName = '${resourceNamePrefix}-sbus-ns-az'
var sbTopicName = 'customertransactions'
var sbTopicSubscriberName = 'customertransactionsubs'

module serviceBusDeploy 'module/deployServiceBus.bicep' =  { 
  name: '${resourceNamePrefix}-sbus-azPOC'
  params: {
    location: location
    serviceBusName: serviceBusName
    subnetsToListenTo: [
      '${azVnet.id}/subnets/${azSubnetSbus}'
      '${azVnet.id}/subnets/${azSubnetiotHub}'
      '${azVnet.id}/subnets/default'
    ]
    topicName: sbTopicName
    topicSubscriberName: sbTopicSubscriberName
    enablePublicNetworkAccess: true
    operational_insights_workspace_id: applicationsInsightDeploy.outputs.logAnalyticsWorkspaceId
  }
  dependsOn: [
    applicationsInsightDeploy
    azVnet
  ]
}

module setSbTopicRbac 'module/set_topic_rbac.bicep' = {
  name: '${resourceNamePrefix}-topic-rbac'
  params: {
    principalIds: [ sbAccessIdentity.outputs.managedIdentityId ]
    roleDefinitionIdOrName: 'Azure Service Bus Data Owner'
    resourceId: '${subscriptionResourceId('Microsoft.Resources/resourceGroups', resourceGroup().name)}/providers/Microsoft.ServiceBus/namespaces/${serviceBusName}/topics/${sbTopicName}'
  }
  dependsOn: [
    serviceBusDeploy
  ]
}

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  name: existingPrivateDNSZone_name
}

resource privateServiceBusDNSZone 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  name: existingPrivateServiceBusDNSZone_name
}

resource privateKeyVaultDNSZone 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  name: existingKeyVaultDNSZone_name
}

resource privateCosmosDbDNSZone 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  name: existingPrivateCosmosDbDNSZone_name
}

resource privateIotHubPrivateDNSZone 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  name: existingIotHubPrivateDNSZone_name
}

resource existingBlobstorageDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  name: existingBlobstorageDnsZone_name
}

module cosmosDbDeploy 'module/deployCosmosDb.bicep' = {
  name: cosmosDbName
  params: {
    name: cosmosDbName
    location: location
    defaultExperience: 'DocumentDB'
    dbName: 'monitor'
    enablePublicNetworkAccess: true
  }
}

var sbAccessIdentityString = '${subscriptionResourceId('Microsoft.Resources/resourceGroups', resourceGroup().name)}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${sbAccessIdentity.outputs.managedIdentityName}'

var iotCustomeEnpointName = '${resourceNamePrefix}-iotep-servicebus'
var iotRouteName = 'iot2servicebus'

module firstIotHubDeploy 'module/deployIotHub.bicep' = {
  name: '${iotHubName}-initialDeploy'
  params: {
    name: iotHubName
    location: location
    userAssignedIdentityId: sbAccessIdentityString  
    operational_insights_workspace_id: applicationsInsightDeploy.outputs.logAnalyticsWorkspaceId
    enablePublicNetworkAccess: true
  }

  dependsOn: [
    sbAccessIdentity
    serviceBusDeploy
    applicationsInsightDeploy
  ]
}

module privateEndpointForKeyvault 'module/deployPrivateEndPoint.bicep' =  { 
  name: '${resourceNamePrefix}-pe-keyvault-az'
  dependsOn: [
    azVnet
	  privateKeyVaultDNSZone
    keyvaultDeploy
  ]
  params: {
    location: location
    subnetId: azSubnetKeyvaultId
    attachedAccountId: keyvaultDeploy.outputs.keyvaultId
    endpointName: '${resourceNamePrefix}-pe-keyvault-az'
    groupIds: array('vault')
    privateDnsZoneId: privateDNSZone.id
  }
}

module privateEndpointForSbus 'module/deployPrivateEndPoint.bicep' =  { 
  name: '${resourceNamePrefix}-pe-sbus-az'
  dependsOn: [
    azVnet
    serviceBusDeploy
	  privateServiceBusDNSZone
    firstIotHubDeploy
  ]
  params: {
    location: location
    subnetId: azSubnetSbusId
    attachedAccountId: serviceBusDeploy.outputs.serviceBusId
    endpointName: '${resourceNamePrefix}-pe-sbus-az'
    groupIds: array('namespace')
    privateDnsZoneId: privateServiceBusDNSZone.id
  }
}

module privateEndpointForCosmosDb 'module/deployPrivateEndPoint.bicep' =  { 
  name: '${resourceNamePrefix}-pe-cosmosdb-az'
  dependsOn: [
    azVnet
	  privateCosmosDbDNSZone
    cosmosDbDeploy
  ]
  params: {
    location: location
    subnetId: azSubnetCosmosDbId
    attachedAccountId: cosmosDbDeploy.outputs.cosmosDbAccountId
    endpointName: '${resourceNamePrefix}-pe-cosmosdb-az'
    groupIds: array('sql')
    privateDnsZoneId: privateCosmosDbDNSZone.id
  }
}

module privateEndpointForIotHub 'module/deployPrivateEndPoint.bicep' =  { 
  name: '${resourceNamePrefix}-pe-iothub-az'
  dependsOn: [
    azVnet
	  privateServiceBusDNSZone
    firstIotHubDeploy
    serviceBusDeploy
  ]
  params: {
    location: location
    subnetId: azSubnetIotHubId
    attachedAccountId: firstIotHubDeploy.outputs.iotHubId
    endpointName: '${resourceNamePrefix}-pe-iothub-az'
    groupIds: array('iotHub')
    privateDnsZoneId: privateIotHubPrivateDNSZone.id
  }
}

module privateEndpointForLaSubscriber 'module/deployPrivateEndPoint.bicep' =  { 
  name: '${resourceNamePrefix}-pe-la-inbound'
  dependsOn: [
	  privateDNSZone
    logicappDeploy
  ]
  params: {
    location: location
    subnetId: azSubnetSubInboundId
    attachedAccountId: logicappDeploy.outputs.LogicAppId
    endpointName: '${resourceNamePrefix}-pe-la-inbound'
    groupIds: array('sites')
    privateDnsZoneId: privateDNSZone.id
  }
}

module privateEndpointForStorageBlob 'module/deployPrivateEndPoint.bicep' =  { 
  name: '${resourceNamePrefix}-pe-storage-blob-az'
  dependsOn: [
    storageDeploymentLogicApp
    existingBlobstorageDnsZone
  ]

  params: {
    location: location
    subnetId: azSubnetBlobStorageId
    attachedAccountId: storageDeploymentLogicApp.outputs.storageAccountId
    endpointName: '${resourceNamePrefix}-pe-storage-blob-az'
    groupIds: array('blob')
    privateDnsZoneId: existingBlobstorageDnsZone.id
  }
}


module newARecordKeyVault 'module/deployPrivateDnsZoneARecord.bicep' = {
  name: '${resourceNamePrefix}-dns-a-record-keyvault'
  dependsOn: [
    privateDNSZone
    privateEndpointForKeyvault
  ] 
  params: {
    recordDnsName: keyvaultName
    recordIpAddress: privateEndpointForKeyvault.outputs.endpointPrivateIp
    privateDNSZone_name: privateDNSZone.name
  }
}

module newARecordServiceBusInWebsitesZone 'module/deployPrivateDnsZoneARecord.bicep' = {
  name: '${resourceNamePrefix}-dns-a-record-servicebus-website'
  dependsOn: [
    privateDNSZone
    privateEndpointForSbus
  ] 
  params: {
    recordDnsName: serviceBusName
    recordIpAddress: privateEndpointForSbus.outputs.endpointPrivateIp
    privateDNSZone_name: privateDNSZone.name
  }
}

module newARecordServiceBusInPrivateZone 'module/deployPrivateDnsZoneARecord.bicep' = {
  name: '${resourceNamePrefix}-dns-a-record-servicebus-private'
  dependsOn: [
    privateServiceBusDNSZone
    privateEndpointForSbus
  ] 
  params: {
    recordDnsName: serviceBusName
    recordIpAddress: privateEndpointForSbus.outputs.endpointPrivateIp
    privateDNSZone_name: privateServiceBusDNSZone.name
  }
}

module newARecordKeyVaultInPrivateZone 'module/deployPrivateDnsZoneARecord.bicep' = {
  name: '${resourceNamePrefix}-dns-a-record-keyvault-private'
  dependsOn: [
    privateServiceBusDNSZone
    privateEndpointForKeyvault
  ] 
  params: {
    recordDnsName: keyvaultName
    recordIpAddress: privateEndpointForKeyvault.outputs.endpointPrivateIp
    privateDNSZone_name: privateKeyVaultDNSZone.name
  }
}

module newARecordCosmosDbInPrivateZone 'module/deployPrivateDnsZoneARecord.bicep' = {
  name: '${resourceNamePrefix}-dns-a-record-cosmosdb-private'
  dependsOn: [
    privateCosmosDbDNSZone
    privateEndpointForKeyvault
  ] 
  params: {
    recordDnsName: cosmosDbName
    recordIpAddress: privateEndpointForCosmosDb.outputs.endpointPrivateIp
    privateDNSZone_name: privateCosmosDbDNSZone.name
  }
}

module newARecordIotHubInPrivateZone 'module/deployPrivateDnsZoneARecord.bicep' = {
  name: '${resourceNamePrefix}-dns-a-record-iothub-private'
  dependsOn: [
    privateEndpointForKeyvault
    privateEndpointForIotHub
  ] 
  params: {
    recordDnsName: iotHubName
    recordIpAddress: privateEndpointForIotHub.outputs.endpointPrivateIp
    privateDNSZone_name: privateEndpointForIotHub.name
  }
}

module routeIotHubDeploy 'module/deployIotHub.bicep' = {
  name: '${iotHubName}-routeDeploy'
  params: {
    name: iotHubName
    location: location
    operational_insights_workspace_id: applicationsInsightDeploy.outputs.logAnalyticsWorkspaceId
    enablePublicNetworkAccess: true
    userAssignedIdentityId: sbAccessIdentityString    
    servicebusTopicRoutes: [
      {
        endpointUri: 'sb://${serviceBusName}.servicebus.windows.net'
        entityPath: sbTopicName
        authenticationType: 'identityBased'
        identity: {
          userAssignedIdentity: sbAccessIdentityString
        }
        name: iotCustomeEnpointName
        subscriptionId: subscription().subscriptionId
        resourceGroup: resourceGroup().name        
      }

    ]
    routes: [
      {
        name: iotRouteName
        source: 'DeviceMessages'
        condition: 'true'
        endpointNames: [
          iotCustomeEnpointName
        ]
        isEnabled: true
      }
    ]
  }

  dependsOn: [
    sbAccessIdentity
    serviceBusDeploy
    firstIotHubDeploy
    privateEndpointForIotHub
    privateEndpointForSbus
    newARecordIotHubInPrivateZone
    newARecordServiceBusInPrivateZone
    applicationsInsightDeploy
  ]
}

resource azServiceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: serviceBusName
}

var secretServiceBusConnectionStringName = 'secretServiceBusConnectionString'
var serviceBusEndpoint = '${azServiceBus.id}/AuthorizationRules/RootManageSharedAccessKey'
var serviceBusConnectionString = listKeys(serviceBusEndpoint, azServiceBus.apiVersion).primaryConnectionString

module azKeyvaultSecretDeploy1 'module/deployKeyVaultSecret.bicep' =  {
  name: substring('${keyvaultName}-Secret-${secretServiceBusConnectionStringName}', 0, 64)

  params: {
    name: secretServiceBusConnectionStringName
    value: serviceBusConnectionString
    keyVaultName: keyvaultName
    resourceExists: false
  }

  dependsOn: [
    keyvaultDeploy
    serviceBusDeploy
  ]
}

resource cosmosDbAccount 'Microsoft.DocumentDb/databaseAccounts@2023-04-15' existing =  {
  name: cosmosDbName  
  scope: resourceGroup(resourceGroup().name)
}

var secretCosmosDbConnectionStringName = 'secretCosmosDbConnectionString'
var cosmosDbsConnectionPrimaryKey = cosmosDbAccount.listKeys(cosmosDbAccount.apiVersion).primaryMasterKey
var cosmosDbAccountPrimaryConnectionString = 'AccountEndpoint=sb://${cosmosDbName}.document.azure.com/;AccountKey=${cosmosDbsConnectionPrimaryKey}'

module azKeyvaultSecretDeploy2 'module/deployKeyVaultSecret.bicep' =  {
  name: '${keyvaultName}-Secret-${secretCosmosDbConnectionStringName}'

  params: {
    name: secretCosmosDbConnectionStringName
    value: cosmosDbAccountPrimaryConnectionString
    keyVaultName: keyvaultName
    resourceExists: false
  }

  dependsOn: [
    keyvaultDeploy
    cosmosDbDeploy
  ]
}

var secretStorageConnectionStringName = 'StorageConnectionString'
var secretStorageConnectionStringValue = '@Microsoft.KeyVault(SecretUri=https://${keyvaultName}${environment().suffixes.keyvaultDns}/secrets/${secretStorageConnectionStringName})'
var secretStorageAccessKeyStringName = 'StorageAccountKey'

var appConfigValues = [
  {
    name: secretStorageConnectionStringName
    value: secretStorageConnectionStringValue
  }
  {
    name: secretStorageAccessKeyStringName
    value: '@Microsoft.KeyVault(SecretUri=https://${keyvaultName}${environment().suffixes.keyvaultDns}/secrets/${secretStorageAccessKeyStringName})'
  }
  {
    name: 'StorageAccountName'
    value: storageName
  }
  {
    name: secretCosmosDbConnectionStringName
    value: '@Microsoft.KeyVault(SecretUri=https://${keyvaultName}${environment().suffixes.keyvaultDns}/secrets/${secretCosmosDbConnectionStringName})'
  }
  {
    name: secretServiceBusConnectionStringName
    value: '@Microsoft.KeyVault(SecretUri=https://${keyvaultName}${environment().suffixes.keyvaultDns}/secrets/${secretServiceBusConnectionStringName})'
  }
]


var fullAppSetting1 = union(baseAppSettings, appConfigValues)

module finalAppSettingsForApp1 'module/deployConfigToLogicApp.bicep'  = {
  name: '${resourceNamePrefix}FinalAppSettingsForApp'

  params: {
    appSettings: fullAppSetting1
    appName: logicappDeploy.outputs.LogicAppName
    ipSecurityRestrictions: []
    scmIpSecurityRestrictions: []
  }

  dependsOn: [
    logicappDeploy
    keyvaultDeploy
    storageDeploymentLogicApp
    fileshareDeployment1
    secretsDeploy
    azKeyvaultSecretDeploy2
    azKeyvaultSecretDeploy1
  ]
}
