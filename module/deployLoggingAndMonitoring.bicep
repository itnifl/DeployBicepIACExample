@description('Required. The Application Insights name.')
param aiName string

@description('Required. Location of deployment')
param location string

@description('Required. Log Analytics Workspace Name')
param logAnalyticsWorkspaceName string

@description('Optional. Log Analytics Workspace SKU')
@allowed([
  'CapacityReservation'
  'Free'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
 ])
param operationInsightsSku string = 'PerGB2018'
param publicNetworkAccessForQuery bool = true
param publicNetworkAccessForIngestion bool = true

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
 
  properties: {
    retentionInDays: 30
    publicNetworkAccessForQuery: publicNetworkAccessForQuery ? 'Enabled' : 'Disabled'
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion ? 'Enabled' : 'Disabled'
    sku: {
      name: operationInsightsSku
    }
  }
}

resource sb1ApplicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: aiName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    DisableIpMasking: false
    DisableLocalAuth: false
    Flow_Type: 'Bluefield'
    ForceCustomerStorageForProfiler: false
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion ? 'Enabled' : 'Disabled'
    publicNetworkAccessForQuery: publicNetworkAccessForQuery ? 'Enabled' : 'Disabled'
    Request_Source: 'rest'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}


/*  TODO!
 *  ConnectionString and InstrumentationKey is sensitive information. Outputting it from a module will log it and expose it in Azure portal logs. 
 *  These values should be fetched and referenced where needed, and not passed around.
 */ 
output appInsightId string = sb1ApplicationInsights.id
output appInsightName string = sb1ApplicationInsights.name
output appInsightsConnectionString string = sb1ApplicationInsights.properties.ConnectionString 
output appInsightsInstrumentationKey string = reference(resourceId('Microsoft.Insights/components', sb1ApplicationInsights.name), '2014-04-01').InstrumentationKey
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
