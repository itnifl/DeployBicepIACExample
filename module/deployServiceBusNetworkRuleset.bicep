@description('Required. Name of the parent')
param parentName string

resource parent 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: parentName
}

param publicNetworkAccess string
param ipRules array
param virtualNetworkRules array

resource networkRuleSet 'Microsoft.ServiceBus/namespaces/networkRuleSets@2021-06-01-preview' = {
  parent: parent
  name: 'default'
  properties: {
    publicNetworkAccess: publicNetworkAccess
    defaultAction: 'Deny'
    virtualNetworkRules: virtualNetworkRules
    ipRules: ipRules
  }
}
