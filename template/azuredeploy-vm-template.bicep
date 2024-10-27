param virtualMachineAdminUsername string

@secure()
param virtualMachineAdminPassword string

param location string = resourceGroup().location
param virtualNetworkAddressPrefix string = '10.100.0.0/16'
param virtualMachineSubnetAddressPrefix string = '10.100.0.0/24'

var uniqueStringId = uniqueString(resourceGroup().id)
var vnetName = '${uniqueStringId}-vnet'
var vmDiagnosticStorageAccountName = '${uniqueStringId}vmdiag'
var virtualMachineName = '${uniqueStringId}vm'
var vmNicName = '${uniqueStringId}-vm-nic'
var vmSubnetName = '${uniqueStringId}-subnet-vm'
var vmNsgName = '${uniqueStringId}-vm-nsg'
var publicIPAddressName = '${uniqueStringId}-public-ip'
var dnsLabelPrefix = 'a${uniqueStringId}-vm'


// vnet creation
module vnet 'modules/vnet/virtualNetwork.bicep' = {
  name: vnetName
  params:{
    location: location
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    vnetName: vnetName
  }
}
// vnet creation


// start of vm and related resoiurces 

module vmNsg 'modules/vmAndNetwork/networkSecurityGroup.bicep' = {
  name: vmNsgName
  params:{
    allowOrDeny: 'Allow'
    location: location
    vmNsgName_var: vmNsgName
  }
}


module vmSubnet 'modules/vmAndNetwork/vmSubnet.bicep' = {
  name: vmSubnetName
  params:{
    vmSubnetAddressPrefix: virtualMachineSubnetAddressPrefix
    vmSubnetName: vmSubnetName
    vnetName: vnetName
    vmNsgNameId: vmNsg.outputs.resourceId
  }
  dependsOn:[
    vnet
    vmNsg
  ]
}

module publicIPAddress 'modules/vmAndNetwork/publicIpAddress.bicep' = {
  name: publicIPAddressName
  params:{
    location: location
    dnsLabelPrefix: dnsLabelPrefix
    publicIPAddressName_var: publicIPAddressName
  }
}


module vmNic 'modules/vmAndNetwork/networkInterface.bicep' = {
  name: vmNicName
  params:{
    location: location
    publicIpAddress: publicIPAddress.outputs.ResourceId
    vmNicName_var: vmNicName
    vmSubnetName: vmSubnetName
    vnetName: vnetName
  }
  dependsOn: [
    vnet
    vmSubnet
  ]
}


module vmDiagnosticStorageAccount 'modules/vmAndNetwork/vmDiagnosticStorageAccount.bicep' = {
  name: vmDiagnosticStorageAccountName
  params:{
    location: location
    vmDiagnosticStorageAccountName_var: vmDiagnosticStorageAccountName
  }
}

module virtualMachine 'modules/vmAndNetwork/virtualMachine.bicep' = {
  name: virtualMachineName

  params:{
    location: location
    storageUri: vmDiagnosticStorageAccount.outputs.proerties.primaryEndpoints.blob
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineAdminUsername: virtualMachineAdminUsername
    virtualMachineName_var: virtualMachineName
    vmNicName_var: vmNicName
  }
  dependsOn: [
    vmNic
  ]
}

module shutdown_computevm_virtualMachineName 'modules/vmAndNetwork/vmShutDown.bicep' = {
  name: 'shutdown-computevm-${virtualMachineName}'

  params:{
    location: location
    targetResourceId: virtualMachine.outputs.ResourceId
    virtualMachineName_var: virtualMachineName
  }
}

// end of VM and vm related resources

