param vmNsgName_var string
param location string
param allowOrDeny string

resource vmNsgName 'Microsoft.Network/networkSecurityGroups@2019-04-01' = {
  name: vmNsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: '${allowOrDeny}_RDP_Internet'
        properties: {
          description: '${allowOrDeny} RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: allowOrDeny
          priority: 101
          direction: 'Inbound'
        }
      }
    ]
  }
}

output resourceId string = vmNsgName.id
