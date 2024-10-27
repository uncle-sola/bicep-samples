param routeTables_pe_vm_name string = 'pe-vm'

resource routeTables_pe_vm_name_resource 'Microsoft.Network/routeTables@2020-11-01' = {
  name: routeTables_pe_vm_name
  location: 'eastus'
  tags: {
    Environment: ''
    'Parent Business': ''
    'Service Offering': ''
  }
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'pe-to-vm'
        properties: {
          addressPrefix: '10.10.0.0/24'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.200.1.4'
          hasBgpOverride: false
        }
      }
    ]
  }
}

resource routeTables_pe_vm_name_pe_to_vm 'Microsoft.Network/routeTables/routes@2020-11-01' = {
  parent: routeTables_pe_vm_name_resource
  name: 'pe-to-vm'
  properties: {
    addressPrefix: '10.10.0.0/24'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: '10.200.1.4'
    hasBgpOverride: false
  }
}