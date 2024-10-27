param vmNicName_var string
param location string
param vnetName string
param vmSubnetName string
param publicIpAddress string

resource vmNicName 'Microsoft.Network/networkInterfaces@2018-11-01' = {
  name: vmNicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddress
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, vmSubnetName)
          }
        }
      }
    ]
  }
}
