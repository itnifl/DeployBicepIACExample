
@minLength(3)
@description('Required. The name of the Logic App.')
param name string

@minLength(3)
@description('Optional. Location where this is deployed.')
param location string = resourceGroup().location

@minLength(3)
@description('Required. defaultExperience.')
@allowed([
  'Cassandra'
  'Table'
  'Graph'
  'DocumentDB'
  'MongoDB'
])
param defaultExperience string

@description('Required. Public access or not?')
param enablePublicNetworkAccess bool

@description('Optional. Database name.')
param dbName string = ''

@description('Optional. Userassigned identity Id')
param userAssignedIdentityId string = ''

resource cosmosDbAccount 'Microsoft.DocumentDb/databaseAccounts@2023-04-15' = {
  name: name
  location: location

  tags: {
    defaultExperience: defaultExperience
    'hidden-cosmos-mmspecial': ''
  }

  identity: {
    type: empty(userAssignedIdentityId) ? 'SystemAssigned' : 'UserAssigned'
    userAssignedIdentities: empty(userAssignedIdentityId) ? null : {
      '${userAssignedIdentityId}': {}
    }
  }

  properties: {
    publicNetworkAccess: enablePublicNetworkAccess ? 'Enabled' : 'Disabled'

    databaseAccountOfferType: 'Standard'
    locations: [
      {
        failoverPriority: 0
        locationName: location
      }
    ]
    backupPolicy: {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: 1440
        backupRetentionIntervalInHours: 48
        backupStorageRedundancy: 'Local'
      }
    }
    isVirtualNetworkFilterEnabled: false
    virtualNetworkRules: []
    ipRules: []
    minimalTlsVersion: 'Tls12'
    enableMultipleWriteLocations: false
    capabilities: []
    enableFreeTier: true
    capacity: {
      totalThroughputLimit: 1000
    }
  }
}

resource sqlDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = if(!empty(dbName)) {
  name: dbName
  parent: cosmosDbAccount
  
  properties: {
    resource: {
      id: dbName
    }
  }
}

output cosmosDbAccountId string = cosmosDbAccount.id

/*
Don't use Bicep outputs for secure data. Outputs are logged to the deployment history, and anyone with access to the deployment can view the values of a deployment's outputs.
Examples:
resource cosmosDbAccount 'Microsoft.DocumentDb/databaseAccounts@2023-04-15' existing =  {
  name: name  
  scope: resourceGroup(resourceGroupName)
}

var cosmosDbsConnectionPrimaryKey = cosmosDbAccount.listKeys(cosmosDbAccount.apiVersion).primaryMasterKey

var cosmosDbAccountPrimaryCMasterKey string = cosmosDbsConnectionPrimaryKey
var cosmosDbAccountPrimaryConnectionString string = 'AccountEndpoint=sb://${name}.document.azure.com/;AccountKey=${cosmosDbsConnectionPrimaryKey}'
*/
