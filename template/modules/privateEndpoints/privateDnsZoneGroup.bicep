param privateEndpointName_var string
param privateDnsZoneName_var string
param location string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2019-11-01' existing = {
  name: privateEndpointName_var
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  name: privateDnsZoneName_var
}

resource privateEndpointWebJobsQueueStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpoint
  location: location
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

