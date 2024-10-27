param location string
param vnetName string
param virtualNetworkAddressPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  location: location
  name: vnetName
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
    enableVmProtection: false
  }
}

output resourceId string = vnet.id
