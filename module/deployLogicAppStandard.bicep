@minLength(3)
@description('Required. The name of the Logic App.')
param logicAppName string

@minLength(3)
@description('Required. Location where this is deployed.')
param deployLocation string

@minLength(3)
@description('Required. The id of Microsoft.Web/serverfarms service plan')
param appServicePlanExtId string

@minLength(3)
@description('Required. Application Insights Instrumentation Key')
param appInsightsInstrKey string

@minLength(3)
@description('Required. Application Insights Connectionstring')
param appInsightsEndpointConnectionString string

@minLength(3)
@description('Required. Storage name')
param storageName string

@description('Optional. Use 32-bit Worker Process')
param use32BitWorkerProcess bool = false

@description('Optional. Userassigned identity Id')
param userAssignedIdentityId string = ''

@description('Optional. Logic app outbount vnet')
param vnetResourceId string = ''

@minLength(3)
@description('Required. Fileshare name')
param fileshareName string

@description('Required. Public access?')
param enablePublicNetworkAccess bool

var logicAppEnabledState = true

resource existingStorage 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageName
}

/* TODO! Must be securely handled, no raw sensitive strings */
var storageAccountConnectionStringRaw = 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${listKeys(resourceId(subscription().subscriptionId, resourceGroup().name, 'Microsoft.Storage/storageAccounts', storageName), existingStorage.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  

var baseAppSettings = [
  {
    name: 'APP_KIND'
    value: 'workflowApp'
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: appInsightsInstrKey
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: appInsightsEndpointConnectionString
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
    value: storageAccountConnectionStringRaw
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
    value: storageAccountConnectionStringRaw
  }
  {
    name: 'WEBSITE_CONTENTSHARE' //Requires an actual fileshare in an actual storageaccount
    value: fileshareName
  }
]

resource logicApp 'Microsoft.Web/sites@2022-09-01' = {
  name: logicAppName
  location: deployLocation
  kind: 'functionapp,workflowapp'
  identity: {
    type: empty(userAssignedIdentityId) ? 'SystemAssigned' : 'UserAssigned'
    userAssignedIdentities: empty(userAssignedIdentityId) ? null : {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    publicNetworkAccess: enablePublicNetworkAccess ? 'Enabled' : 'Disabled'
    enabled: logicAppEnabledState
    hostNameSslStates: [
      {
          name: '${logicAppName}SslState1'
          sslState: 'Disabled'
          hostType: 'Standard'
      }
      {
          name: '${logicAppName}SslState2'
          sslState: 'Disabled'
          hostType: 'Repository'
      }
    ]
    serverFarmId: appServicePlanExtId
    clientAffinityEnabled: true
    siteConfig: {
      alwaysOn: false
      appSettings: baseAppSettings
      cors: {
        allowedOrigins: [
            'https://afd.hosting.portal.azure.net'
            'https://afd.hosting-ms.portal.azure.net'
            'https://hosting.portal.azure.net'
            'https://ms.hosting.portal.azure.net'
            'https://ema-ms.hosting.portal.azure.net'
            'https://ema.hosting.portal.azure.net'
            'https://ema.hosting.portal.azure.net'
            'https://portal.azure.com '
        ]
      }
	   use32BitWorkerProcess: use32BitWorkerProcess
    }

    virtualNetworkSubnetId: empty(vnetResourceId) ? null : vnetResourceId
  }
}

output LogicAppName string = logicApp.name
output LogicAppId string = logicApp.id
output LogicAppIdentity string = logicApp.identity.principalId
output LogicAppBaseAppSettings array = baseAppSettings
