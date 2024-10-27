param vnetName string
param vmSubnetName string
param vmNsgNameId string
param vmSubnetAddressPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: vnetName
}

resource vmSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  parent: vnet
  name: vmSubnetName
  properties: {
    addressPrefix: vmSubnetAddressPrefix
    networkSecurityGroup: {
      id: vmNsgNameId
    }
    delegations: []
    serviceEndpoints: []
    privateLinkServiceNetworkPolicies: 'Enabled'
    privateEndpointNetworkPolicies: 'Disabled'
  }
}
