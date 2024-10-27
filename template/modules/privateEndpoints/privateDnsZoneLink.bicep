param parentPrivateDnsZoneName string
param vnetId string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  name: parentPrivateDnsZoneName
}

resource privateDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZone
  name: '${parentPrivateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

