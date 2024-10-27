param virtualMachineName_var string
param location string
param virtualMachineAdminUsername string
param virtualMachineAdminPassword string
param vmNicName_var string
param storageUri string

resource virtualMachineName 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: virtualMachineName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: virtualMachineName_var
      adminUsername: virtualMachineAdminUsername
      adminPassword: virtualMachineAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: 'win10-21h2-pro-g2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Nework/networkInterfaces', vmNicName_var)
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageUri
      }
    }
  }
}

output ResourceId string = virtualMachineName.id
