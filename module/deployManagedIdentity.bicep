param location string
param name string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  location: location
  name: name
  tags: json('{}')
}


output managedIdentityId string = managedIdentity.properties.principalId
output managedIdentityName string = name
