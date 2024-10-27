param virtualMachineAdminUsername string

@secure()
param virtualMachineAdminPassword string

param cosmosDbDatabaseName string
param cosmosDbContainerName string
param blobContainerName string
param deploySourceCode bool = false
param location string = resourceGroup().location
param function_repo_url string
param virtualNetworkAddressPrefix string = '10.100.0.0/16'
param virtualMachineSubnetAddressPrefix string = '10.100.0.0/24'
param privateEndpointSubnetAddressPrefix string = '10.100.1.0/24'
param functionSubnetAddressPrefix string = '10.100.2.0/24'

var uniqueStringId = uniqueString(resourceGroup().id)
var appServicePlanName_var = '${uniqueStringId}-asp'
var functionAppName_var = '${uniqueStringId}-funcapp'
var vnetName_var = '${uniqueStringId}-vnet'
var functionWebJobsStorageAccountName_var = toLower('${uniqueStringId}wjsa')
var censusDataStorageAccountName_var = toLower('${uniqueStringId}pe')
var applicationInsightsName_var = '${uniqueStringId}-ai'
var functionsSubnetName = '${uniqueStringId}-subnet-functions'
var privateEndpointSubnetName = '${uniqueStringId}-subnet-privateendpoint'
var privateEndpointStorageBlobName_var = '${uniqueStringId}-blob-private-endpoint'
var privateEndpointCosmosDbName_var = '${uniqueStringId}-cosmosdb-private-endpoint'
var privateEndpointWebJobsQueueStorageName_var = '${uniqueStringId}-wjsa-queue-private-endpoint'
var privateEndpointWebJobsTableStorageName_var = '${uniqueStringId}-wjsa-table-private-endpoint'
var privateEndpointWebJobsBlobStorageName_var = '${uniqueStringId}-wjsa-blob-private-endpoint'
var privateEndpointWebJobsFileStorageName_var = '${uniqueStringId}-wjsa-file-private-endpoint'
var privateStorageQueueDnsZoneName_var = 'privatelink.queue.${environment().suffixes.storage}'
var privateStorageBlobDnsZoneName_var = 'privatelink.blob.${environment().suffixes.storage}'
var privateStorageTableDnsZoneName_var = 'privatelink.table.${environment().suffixes.storage}'
var privateStorageFileDnsZoneName_var = 'privatelink.file.${environment().suffixes.storage}'
var privateCosmosDbDnsZoneName_var = 'privatelink.documents.azure.com'
var vmDiagnosticStorageAccountName_var = '${uniqueStringId}vmdiag'
var virtualMachineName_var = '${uniqueStringId}vm'
var vmNicName_var = '${uniqueStringId}-vm-nic'
var vmSubnetName = '${uniqueStringId}-subnet-vm'
var vmNsgName_var = '${uniqueStringId}-vm-nsg'
var privateCosmosDbAccountName_var = '${uniqueStringId}-cosmosdb-private'
var publicIPAddressName_var = '${uniqueStringId}-public-ip'
var dnsLabelPrefix = 'a${uniqueStringId}-vm'
var appInsightsResourceId = applicationInsightsName.id


// vnet creation
module vnetName 'modules/vnet/virtualNetwork.bicep' = {
  name: vnetName_var
  params:{
   location: location
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    vnetName: vnetName_var
  }
}
// vnet creation


// start of vm and related resoiurces 

module vmNsgName 'modules/vmAndNetwork/networkSecurityGroup.bicep' = {
  name: vmNsgName_var
  params:{
    allowOrDeny: 'Allow'
    location: location
    vmNsgName_var: vmNsgName_var
  }
}


module vmSubnet 'modules/vmAndNetwork/vmSubnet.bicep' = {
  name: vmSubnetName
  params:{
    vmSubnetAddressPrefix: virtualMachineSubnetAddressPrefix
    vmSubnetName: vmSubnetName
    vnetName: vnetName_var
    vmNsgNameId: vmNsgName.outputs.resourceId
  }
  dependsOn:[
    vnetName
    vmNsgName
  ]
}

module publicIPAddressName 'modules/vmAndNetwork/publicIpAddress.bicep' = {
  name: publicIPAddressName_var
  params:{
    location: location
    dnsLabelPrefix: dnsLabelPrefix
    publicIPAddressName_var: publicIPAddressName_var
  }
}


module vmNicName 'modules/vmAndNetwork/networkInterface.bicep' = {
  name: vmNicName_var
  params:{
    location: location
    publicIpAddress: publicIPAddressName.outputs.ResourceId
    vmNicName_var: vmNicName_var
    vmSubnetName: vmSubnetName
    vnetName: vnetName_var
  }
  dependsOn: [
    vnetName
    vmSubnet
  ]
}


module vmDiagnosticStorageAccountName 'modules/vmAndNetwork/vmDiagnosticStorageAccount.bicep' = {
  name: vmDiagnosticStorageAccountName_var
  params:{
    location: location
    vmDiagnosticStorageAccountName_var: vmDiagnosticStorageAccountName_var
  }
}

module virtualMachineName 'modules/vmAndNetwork/virtualMachine.bicep' = {
  name: virtualMachineName_var

  params:{
    location: location
    storageUri: vmDiagnosticStorageAccountName.outputs.proerties.primaryEndpoints.blob
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineAdminUsername: virtualMachineAdminUsername
    virtualMachineName_var: virtualMachineName_var
    vmNicName_var: vmNicName_var
  }
  dependsOn: [
    vmNicName
  ]
}

module shutdown_computevm_virtualMachineName 'modules/vmAndNetwork/vmShutDown.bicep' = {
  name: 'shutdown-computevm-${virtualMachineName_var}'

  params:{
    location: location
    targetResourceId: virtualMachineName.outputs.ResourceId
    virtualMachineName_var: virtualMachineName_var
  }
}

// end of VM and vm related resources


module functionSubnet 'modules/functionsAndTools/functionSubnet.bicep' = {
  name: functionsSubnetName
  params:{
    functionSubnetAddressPrefix: functionSubnetAddressPrefix
    functionSubnetName: functionsSubnetName
    vnetName: vnetName_var
  }
  dependsOn:[
    vnetName
    vmSubnet
  ]
}

module privateEndpointSubnet 'modules/privateEndpoints/privateEndPointSubnet.bicep' = {
  name: privateEndpointSubnetName
  params:{
    privateEndpointSubnetAddressPrefix: privateEndpointSubnetAddressPrefix
    privateEndpointSubnetName: privateEndpointSubnetName
    vnetName: vnetName_var
  }
  dependsOn:[
    vnetName
    vmSubnet
    functionSubnet
  ]
}

resource censusDataStorageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  location: location
  name: censusDataStorageAccountName_var
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

resource censusDataStorageAccountName_default_blobContainerName 'Microsoft.Storage/storageAccounts/blobServices/containers@2018-07-01' = {
  name: '${censusDataStorageAccountName_var}/default/${blobContainerName}'
  dependsOn: [
    censusDataStorageAccountName
  ]
}

resource functionWebJobsStorageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  location: location
  name: functionWebJobsStorageAccountName_var
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
  dependsOn: [
    vnetName
  ]
}

resource functionWebJobsStorageAccountName_default_myfunctionfiles 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-06-01' = {
  name: '${functionWebJobsStorageAccountName_var}/default/myfunctionfiles'
  dependsOn: [
    functionWebJobsStorageAccountName
  ]
}


resource privateCosmosDbAccountName 'Microsoft.DocumentDB/databaseAccounts@2021-01-15' = {
  name: privateCosmosDbAccountName_var
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    publicNetworkAccess: 'Enabled'
  }
}

resource privateCosmosDbAccountName_cosmosDbDatabaseName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-01-15' = {
  parent: privateCosmosDbAccountName
  name: cosmosDbDatabaseName
  properties: {
    resource: {
      id: cosmosDbDatabaseName
    }
    options: {
    }
  }
}

resource privateCosmosDbAccountName_cosmosDbDatabaseName_cosmosDbContainerName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-01-15' = {
  parent: privateCosmosDbAccountName_cosmosDbDatabaseName
  name: cosmosDbContainerName
  properties: {
    resource: {
      id: cosmosDbContainerName
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
    }
    options: {
      throughput: 400
    }
  }
}

resource applicationInsightsName 'Microsoft.Insights/components@2015-05-01' = {
  location: location
  name: applicationInsightsName_var
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource privateStorageQueueDnsZoneName 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateStorageQueueDnsZoneName_var
  location: 'global'
}

resource privateStorageBlobDnsZoneName 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateStorageBlobDnsZoneName_var
  location: 'global'
}

resource privateStorageTableDnsZoneName 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateStorageTableDnsZoneName_var
  location: 'global'
}

resource privateStorageFileDnsZoneName 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateStorageFileDnsZoneName_var
  location: 'global'
}

resource privateCosmosDbDnsZoneName 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateCosmosDbDnsZoneName_var
  location: 'global'
}

resource privateStorageQueueDnsZoneName_privateStorageQueueDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateStorageQueueDnsZoneName
  name: '${privateStorageQueueDnsZoneName_var}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetName.outputs.resourceId
    }
  }
  dependsOn: [
    vnetName
  ]
}

resource privateStorageTableDnsZoneName_privateStorageTableDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateStorageTableDnsZoneName
  name: '${privateStorageTableDnsZoneName_var}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetName.outputs.resourceId
    }
  }
  dependsOn: [
    vnetName
  ]
}

resource privateStorageBlobDnsZoneName_privateStorageBlobDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateStorageBlobDnsZoneName
  name: '${privateStorageBlobDnsZoneName_var}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetName.outputs.resourceId
    }
  }
  dependsOn: [
    vnetName
  ]
}

resource privateStorageFileDnsZoneName_privateStorageFileDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateStorageFileDnsZoneName
  name: '${privateStorageFileDnsZoneName_var}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetName.outputs.resourceId
    }
  }
  dependsOn: [
    vnetName
  ]
}

resource privateCosmosDbDnsZoneName_privateCosmosDbDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateCosmosDbDnsZoneName
  name: '${privateCosmosDbDnsZoneName_var}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetName.outputs.resourceId
    }
  }
  dependsOn: [
    vnetName
  ]
}

resource privateEndpointStorageBlobName 'Microsoft.Network/privateEndpoints@2019-11-01' = {
  name: privateEndpointStorageBlobName_var
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageBlobPrivateLinkConnection'
        properties: {
          privateLinkServiceId: censusDataStorageAccountName.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
  dependsOn: [
    vnetName
    privateEndpointSubnet
  ]
}

resource privateEndpointStorageBlobName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpointStorageBlobName
  location: location
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageBlobDnsZoneName.id
        }
      }
    ]
  }
}

resource privateEndpointWebJobsQueueStorageName 'Microsoft.Network/privateEndpoints@2019-11-01' = {
  name: privateEndpointWebJobsQueueStorageName_var
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: functionWebJobsStorageAccountName.id
          groupIds: [
            'queue'
          ]
        }
      }
    ]
  }
  dependsOn: [
    privateEndpointSubnet
    vnetName
  ]
}

resource privateEndpointWebJobsQueueStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpointWebJobsQueueStorageName
  location: location
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageQueueDnsZoneName.id
        }
      }
    ]
  }
}

resource privateEndpointWebJobsTableStorageName 'Microsoft.Network/privateEndpoints@2019-11-01' = {
  name: privateEndpointWebJobsTableStorageName_var
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: functionWebJobsStorageAccountName.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
  dependsOn: [
    vnetName
    privateEndpointSubnet
  ]
}

resource privateEndpointWebJobsTableStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpointWebJobsTableStorageName
  location: location
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageTableDnsZoneName.id
        }
      }
    ]
  }
}

resource privateEndpointWebJobsBlobStorageName 'Microsoft.Network/privateEndpoints@2019-11-01' = {
  name: privateEndpointWebJobsBlobStorageName_var
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: functionWebJobsStorageAccountName.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
  dependsOn: [
    privateEndpointSubnet
    vnetName
  ]
}

resource privateEndpointWebJobsBlobStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpointWebJobsBlobStorageName
  location: location
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageBlobDnsZoneName.id
        }
      }
    ]
  }
}

resource privateEndpointWebJobsFileStorageName 'Microsoft.Network/privateEndpoints@2019-11-01' = {
  name: privateEndpointWebJobsFileStorageName_var
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: functionWebJobsStorageAccountName.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
  dependsOn: [
    privateEndpointSubnet
    vnetName
  ]
}

resource privateEndpointWebJobsFileStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpointWebJobsFileStorageName
  location: location
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageFileDnsZoneName.id
        }
      }
    ]
  }
}

resource privateEndpointCosmosDbName 'Microsoft.Network/privateEndpoints@2019-11-01' = {
  name: privateEndpointCosmosDbName_var
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyCosmosDbPrivateLinkConnection'
        properties: {
          privateLinkServiceId: privateCosmosDbAccountName.id
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
  }
  dependsOn: [
    privateEndpointSubnet
    vnetName
  ]
}

resource privateEndpointCosmosDbName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpointCosmosDbName
  location: location
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateCosmosDbDnsZoneName.id
        }
      }
    ]
  }
}





resource appServicePlanName 'Microsoft.Web/serverfarms@2018-02-01' = {
  name: appServicePlanName_var
  location: location
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
    size: 'EP1'
    family: 'EP'
    capacity: 1
  }
  kind: 'elastic'
  properties: {
    maximumElasticWorkerCount: 20
  }
}

resource functionAppName 'Microsoft.Web/sites@2018-11-01' = {
  name: functionAppName_var
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: appServicePlanName.id
    siteConfig: {
      vnetName: 'bead47e1-d65e-4cb4-b907-f74674d32c09_${functionsSubnetName}'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(appInsightsResourceId, '2018-05-01-preview').instrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${reference(appInsightsResourceId, '2018-05-01-preview').instrumentationKey}'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionWebJobsStorageAccountName_var};AccountKey=${listkeys(functionWebJobsStorageAccountName.id, '2018-11-01').keys[0].value};'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionWebJobsStorageAccountName_var};AccountKey=${listkeys(functionWebJobsStorageAccountName.id, '2018-11-01').keys[0].value};'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: 'myfunctionfiles'
        }
        {
          name: 'WEBSITE_DNS_SERVER'
          value: '168.63.129.16'
        }
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
        {
          name: 'CensusResultsAzureStorageConnection'
          value: 'DefaultEndpointsProtocol=https;AccountName=${censusDataStorageAccountName_var};AccountKey=${listkeys(censusDataStorageAccountName.id, '2018-11-01').keys[0].value};'
        }
        {
          name: 'ContainerName'
          value: blobContainerName
        }
        {
          name: 'CosmosDbName'
          value: cosmosDbDatabaseName
        }
        {
          name: 'CosmosDbCollectionName'
          value: cosmosDbContainerName
        }
        {
          name: 'CosmosDBConnection'
          value: listConnectionStrings(privateCosmosDbAccountName.id, '2019-12-12').connectionStrings[0].connectionString
        }
        {
          name: 'Project'
          value: 'src'
        }
      ]
    }
  }
  dependsOn:[
    functionSubnet
    vnetName
  ]
}

resource functionAppName_virtualNetwork 'Microsoft.Web/sites/networkConfig@2019-08-01' = {
  parent: functionAppName
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, functionsSubnetName)
    isSwift: true
  }
  dependsOn: [
    functionSubnet
    vnetName
  ]
}

resource functionAppName_web 'Microsoft.Web/sites/sourcecontrols@2019-08-01' = if (deploySourceCode) {
  parent: functionAppName
  name: 'web'
  properties: {
    repoUrl: function_repo_url
    branch: 'master'
    isManualIntegration: true
  }
}

resource Microsoft_Web_sites_config_functionAppName_web 'Microsoft.Web/sites/config@2019-08-01' = {
  parent: functionAppName
  name: 'web'
  properties: {
    functionsRuntimeScaleMonitoringEnabled: true
  }
  dependsOn: [
    functionSubnet
    vnetName
  ]
}
