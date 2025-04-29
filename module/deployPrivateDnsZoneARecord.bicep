@description('The dns name of the new A record')
param recordDnsName string
@description('The IP address of the new A record')
param recordIpAddress string
@description('The existing DNS Zone name where the record is to be registered')
param privateDNSZone_name string


resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
    name: privateDNSZone_name
  }


resource newARecord 'Microsoft.Network/privateDnsZones/A@2018-09-01' = if(!empty(recordIpAddress)) {
  name: recordDnsName
  parent: privateDnsZone


  properties: {
      ttl: 3600
      aRecords: [
          {
              ipv4Address: recordIpAddress
          }
      ]
  }
}
