@description('Required. The name of the servicebus that we are adding a topic to')
param serviceBusName string

@description('Required. The name of the topic that we will create')
param topicName string

@description('Required. The name of the subscriber that we will create')
param topicSubscriberName string 

resource sb1ServiceBus1 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: serviceBusName
}

resource sb1ServiceBus1_topic 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = {
  parent: sb1ServiceBus1
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

resource sb1ServiceBus1_subscriber_customertransactionsubs 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  parent: sb1ServiceBus1_topic
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

/*
TODO: Clean this up.

Don't use Bicep outputs for secure data. Outputs are logged to the deployment history, and anyone with access to the deployment can view the values of a deployment's outputs.

Examples:

var serviceBusEndpoint = '${sb1ServiceBus1.id}/AuthorizationRules/RootManageSharedAccessKey'
var serviceBusConnectionString = listKeys(serviceBusEndpoint, sb1ServiceBus1.apiVersion).primaryConnectionString
var serviceBusConnectionPrimaryKey = listKeys(serviceBusEndpoint, sb1ServiceBus1.apiVersion).primaryKey

var serviceBusId string = sb1ServiceBus1.id
var serviceBusPrimaryConnectionString string = serviceBusConnectionString
var serviceBusPrivatePrimaryConnectionString string = 'Endpoint=sb://${serviceBusName}.privatelink.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=${serviceBusConnectionPrimaryKey}'
*/
