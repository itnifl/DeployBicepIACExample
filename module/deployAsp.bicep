@description('Required. Location of deployment')
param deployLocation string

@description('Required. The name.')
param hostingPlanName string

@description('Optional. WorkerSizeId ')
param workerSizeId int = 3
@description('Optional. NumberOfWorkers')
param numberOfWorkers int = 1
@description('Optional. MaximumElasticWorkerCount ')
param maximumElasticWorkerCount int = 20
@description('Optional. SkuTier')
param skuTier string = 'WorkflowStandard'
@description('Optional. SkuName')
param skuName string = 'WS1'

@description('Optional. Kind of server OS.')
@allowed([
  'Windows'
  'Linux'
])
param serverOS string = 'Windows'

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: hostingPlanName
  location: deployLocation
  kind: serverOS == 'Windows' ? '' : 'Linux'
  tags: {}
  properties: {
    targetWorkerSizeId: workerSizeId
    targetWorkerCount: numberOfWorkers
    maximumElasticWorkerCount: maximumElasticWorkerCount
    zoneRedundant: false
  }
  sku: {
    tier: skuTier
    name: skuName
  }
  dependsOn: []
}


output extId string = hostingPlanName_resource.id
