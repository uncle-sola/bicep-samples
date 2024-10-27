param publicIPAddressName_var string
param location string
param dnsLabelPrefix string

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2018-11-01' = {
  name: publicIPAddressName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

output ResourceId string = publicIPAddressName.id
