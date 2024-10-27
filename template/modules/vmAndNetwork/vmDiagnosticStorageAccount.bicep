param vmDiagnosticStorageAccountName_var string
param location string

resource vmDiagnosticStorageAccountName 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: vmDiagnosticStorageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {
  }
}

output proerties object = vmDiagnosticStorageAccountName.properties
