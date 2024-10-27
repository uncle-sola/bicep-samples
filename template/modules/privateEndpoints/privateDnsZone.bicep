param privateDnsZoneName string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZoneName
  location: 'global'
}

output resourceId string = privateDnsZone.id
