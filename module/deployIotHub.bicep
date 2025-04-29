@minLength(3)
@description('Required. The name of the Iot Hub.')
param name string

@description('Required. The ID of a resource of type Microsoft.OperationalInsights/workspaces')
param operational_insights_workspace_id string

@description('Required. Enable public network access')
param enablePublicNetworkAccess bool


@minLength(3)
@description('Optional. Location where this is deployed.')
param location string = resourceGroup().location

@description('Optional. Sku name.')
param skuName string = 'S1'

@description('Optional. Userassigned identity Id')
param userAssignedIdentityId string = ''

@description('Optional. Service Bus Topic Rputes')
param servicebusTopicRoutes array = [
  
]

@description('Optional. Routes')
param routes array = []

resource iotHub 'Microsoft.Devices/IotHubs@2021-07-02' = {
  name: name
  location: location

  sku: {
    name: skuName
    capacity: 1
  }
  identity: {
    type: empty(userAssignedIdentityId) ? 'SystemAssigned' : 'UserAssigned'
    userAssignedIdentities: empty(userAssignedIdentityId) ? null : {
      '${userAssignedIdentityId}': {}
    }
  }

  properties: {
    publicNetworkAccess: enablePublicNetworkAccess ? 'Enabled' : 'Disabled'
    ipFilterRules: []
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: 4
      }
    }
    routing: {
      endpoints: {
        serviceBusQueues: []
        serviceBusTopics: servicebusTopicRoutes
        eventHubs: []
        storageContainers: []
      }
      routes: routes
      fallbackRoute: {
        name: '$fallback'
        source: 'DeviceMessages'
        condition: 'true'
        endpointNames: [
          'events'
        ]
        isEnabled: true
      }
    }
    storageEndpoints: {

    }
    messagingEndpoints: {
      fileNotifications: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
    enableFileUploadNotifications: false
    cloudToDevice: {
      maxDeliveryCount: 10
      defaultTtlAsIso8601: 'PT1H'
      feedback: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
    features: 'None'
    disableLocalAuth: false
    allowedFqdnList: []
    enableDataResidency: false
  }
}

var logsToEnable = [
  'Connections'
  'DeviceStreams'
  'Configurations'
  'JobsOperations'
  'Routes'
  'TwinQueries'
]

var diagnosticLogsRetentionInDays = 20
var diagnosticLogsname = '${name}Logs'

var diagnosticsLogs = [for log in logsToEnable: {
  category: log
  enabled: true
  retentionPolicy: {
    enabled: false
    days: diagnosticLogsRetentionInDays
  }
}]

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnosticLogsname
  scope: iotHub
  properties: {
    workspaceId: operational_insights_workspace_id
    logs: diagnosticsLogs
  }
}

output iotHubId string = iotHub.id
