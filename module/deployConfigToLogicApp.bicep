@description('Required. Appsettings Array')
param appSettings array

@description('Required. Name of app')
param appName string

param ipSecurityRestrictions array = []
param scmIpSecurityRestrictions array = []

resource app 'Microsoft.Web/sites@2021-02-01' existing = {
  name: appName
}

resource appsettingsDeploy 'Microsoft.Web/sites/config@2021-03-01' =  {
  name: 'web'
  kind: 'V2'
  parent: app
  properties: {
    appSettings: appSettings
    ipSecurityRestrictions: ipSecurityRestrictions
    scmIpSecurityRestrictions: scmIpSecurityRestrictions
  }  
}
