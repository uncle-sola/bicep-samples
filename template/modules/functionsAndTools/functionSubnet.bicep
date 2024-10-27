param vnetName string
param functionSubnetName string
param functionSubnetAddressPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: vnetName
}

resource functionSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  parent: vnet
  name: functionSubnetName
  properties: {
    addressPrefix: functionSubnetAddressPrefix
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    delegations: [
      {
        name: 'webapp'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
          actions: [
            'Microsoft.Network/virtualNetworks/subnets/action'
          ]
        }
      }
    ]
  }
}
