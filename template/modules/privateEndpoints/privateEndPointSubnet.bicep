param vnetName string
param privateEndpointSubnetName string
param privateEndpointSubnetAddressPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: vnetName
}

resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' = {
  parent: vnet
  name: privateEndpointSubnetName
  properties: {
    addressPrefix: privateEndpointSubnetAddressPrefix
    privateLinkServiceNetworkPolicies: 'Enabled'
    privateEndpointNetworkPolicies: 'Disabled'
  }
}
