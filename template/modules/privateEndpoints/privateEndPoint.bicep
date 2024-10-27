param privateEndpointName_var string
param location string
param groupIds array
param privateLinkServiceConnectionName_var string
param vnetName_var string
param privateEndpointSubnetName string
param privateLinkServiceId string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2019-11-01' = {
  name: privateEndpointName_var
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: privateLinkServiceConnectionName_var
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
  }
}
