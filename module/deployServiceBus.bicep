@description('Required. The Service Bus name.')
param serviceBusName string

@description('Required. Location of deployment')
param location string

@description('Required. Subnet to listen to')
param subnetsToListenTo array

@description('Optional. Enable Public Network Access')
param enablePublicNetworkAccess bool

param topicName string = 'customertransactions'
param topicSubscriberName string = 'customertransactionsubs'

@description('Required. The ID of a resource of type Microsoft.OperationalInsights/workspaces')
param operational_insights_workspace_id string


resource azureServiceBus1 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: serviceBusName
  location: location
  sku: {
    capacity: 1
    name: 'Premium'
    tier: 'Premium'
  }

  identity: {
    type: 'SystemAssigned'
  }
}

resource azureServiceBus1_RootManageSharedAccessKey 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-11-01' = {
  parent: azureServiceBus1
  name: 'RootManageSharedAccessKey'

  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

resource azureServiceBus1_networkRules 'Microsoft.ServiceBus/namespaces/networkRuleSets@2021-11-01' = {
  parent: azureServiceBus1
  name: 'default'

  properties: {
    publicNetworkAccess: enablePublicNetworkAccess ? 'Enabled' : 'Disabled'
    defaultAction: enablePublicNetworkAccess ? 'Allow' : 'Deny'
    virtualNetworkRules: [for subNetId in subnetsToListenTo: {
        subnet: {
          id: subNetId
        }
        ignoreMissingVnetServiceEndpoint: false
      
      }
    ]
    ipRules: []
    trustedServiceAccessEnabled: true
  }
}


resource azureServiceBus1_topic_customertransactions 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = {
  parent: azureServiceBus1
  name: topicName
  
  properties: {
    maxMessageSizeInKilobytes: 2096
    defaultMessageTimeToLive: 'P14D'
    maxSizeInMegabytes: 2048
    requiresDuplicateDetection: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    enableBatchedOperations: true
    status: 'Active'
    supportOrdering: true
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource azureServiceBus1_subscriber_customertransactionsubs 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  parent: azureServiceBus1_topic_customertransactions
  name: topicSubscriberName
  
  properties: {
    isClientAffine: false
    lockDuration: 'PT30S'
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: false
    deadLetteringOnFilterEvaluationExceptions: true
    maxDeliveryCount: 1024
    status: 'Active'
    enableBatchedOperations: true
    autoDeleteOnIdle: 'P14D'
  }  
}

var logsToEnable = [
  'VNetAndIPFilteringLogs'
  'RuntimeAuditLogs'
  'OperationalLogs'
]

var diagnosticLogsRetentionInDays = 20
var diagnosticLogsname = '${serviceBusName}Logs'

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
  scope: azureServiceBus1
  properties: {
    workspaceId: operational_insights_workspace_id
    logs: diagnosticsLogs
  }
}

output serviceBusId string = azureServiceBus1.id

/*
TODO: Clean this up.

Don't use Bicep outputs for secure data. Outputs are logged to the deployment history, and anyone with access to the deployment can view the values of a deployment's outputs.


var serviceBusEndpoint = '${azureServiceBus1.id}/AuthorizationRules/RootManageSharedAccessKey'
var serviceBusConnectionString = listKeys(serviceBusEndpoint, azureServiceBus1.apiVersion).primaryConnectionString
var serviceBusConnectionPrimaryKey = listKeys(serviceBusEndpoint, azureServiceBus1.apiVersion).primaryKey

var serviceBusPrimaryConnectionString string = serviceBusConnectionString
var serviceBusPrivatePrimaryConnectionString string = 'Endpoint=sb://${serviceBusName}.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=${serviceBusConnectionPrimaryKey}'
*/
