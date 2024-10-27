
param cosmosDbDatabaseName string
param cosmosDbContainerName string
param blobContainerName string
param location string = resourceGroup().location
param virtualNetworkAddressPrefix string = '10.100.0.0/16'
param privateEndpointSubnetAddressPrefix string = '10.100.1.0/24'
param functionSubnetAddressPrefix string = '10.100.2.0/24'

var uniqueStringId = uniqueString(resourceGroup().id)
var appServicePlanName = '${uniqueStringId}-asp'
var functionAppName = '${uniqueStringId}-funcapp'
var vnetName = '${uniqueStringId}-vnet'
var functionWebJobsStorageAccountName = toLower('${uniqueStringId}wjsa')
var censusDataStorageAccountName = toLower('${uniqueStringId}pe')
var applicationInsightsName = '${uniqueStringId}-ai'
var functionsSubnetName = '${uniqueStringId}-subnet-functions'
var privateEndpointSubnetName = '${uniqueStringId}-subnet-privateendpoint'
var privateEndpointStorageBlobName = '${uniqueStringId}-blob-private-endpoint'
var privateEndpointCosmosDbName = '${uniqueStringId}-cosmosdb-private-endpoint'
var privateEndpointWebJobsQueueStorageName = '${uniqueStringId}-wjsa-queue-private-endpoint'
var privateEndpointWebJobsTableStorageName = '${uniqueStringId}-wjsa-table-private-endpoint'
var privateEndpointWebJobsBlobStorageName = '${uniqueStringId}-wjsa-blob-private-endpoint'
var privateEndpointWebJobsFileStorageName = '${uniqueStringId}-wjsa-file-private-endpoint'
var privateStorageQueueDnsZoneName = 'privatelink.queue.${environment().suffixes.storage}'
var privateStorageBlobDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var privateStorageTableDnsZoneName = 'privatelink.table.${environment().suffixes.storage}'
var privateStorageFileDnsZoneName = 'privatelink.file.${environment().suffixes.storage}'
var privateCosmosDbDnsZoneName = 'privatelink.documents.azure.com'
var privateCosmosDbAccountName = '${uniqueStringId}-cosmosdb-private'
var appInsightsResourceId = applicationInsights.id
var vmSubscriptionId = 'b16cc792-dc1d-4942-ac9a-0ff659eb9f38'
var vmVnetResourceGroupId = 'sb-dev-vm-rg'
var vmVnetName = 'sb-dev-vm-vnet'

// resource vmVnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing ={
//   name: vmVnetName
//   scope: resourceGroup(vmVnetResourceGroupId)
// }


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




module functionSubnet 'modules/functionsAndTools/functionSubnet.bicep' = {
  name: functionsSubnetName
  params:{
    functionSubnetAddressPrefix: functionSubnetAddressPrefix
    functionSubnetName: functionsSubnetName
    vnetName: vnetName
  }
  dependsOn:[
    vnet
  ]
}

module privateEndpointSubnet 'modules/privateEndpoints/privateEndPointSubnet.bicep' = {
  name: privateEndpointSubnetName
  params:{
    privateEndpointSubnetAddressPrefix: privateEndpointSubnetAddressPrefix
    privateEndpointSubnetName: privateEndpointSubnetName
    vnetName: vnetName
  }
  dependsOn:[
    vnet
    functionSubnet
  ]
}

resource censusDataStorageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  location: location
  name: censusDataStorageAccountName
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
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
  name: '${censusDataStorageAccountName}/default/${blobContainerName}'
  dependsOn: [
    censusDataStorageAccount
  ]
}

resource functionWebJobsStorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  location: location
  name: functionWebJobsStorageAccountName
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
    vnet
  ]
}

resource functionWebJobsStorageAccountName_default_myfunctionfiles 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-06-01' = {
  name: '${functionWebJobsStorageAccountName}/default/myfunctionfiles'
  dependsOn: [
    functionWebJobsStorageAccount
  ]
}


resource privateCosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-01-15' = {
  name: privateCosmosDbAccountName
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
    publicNetworkAccess: 'Disabled'
  }
}

resource privateCosmosDbAccountName_cosmosDbDatabaseName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-01-15' = {
  parent: privateCosmosDbAccount
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

resource applicationInsights 'Microsoft.Insights/components@2015-05-01' = {
  location: location
  name: applicationInsightsName
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource privateStorageQueueDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateStorageQueueDnsZoneName
  location: 'global'
}

resource privateStorageBlobDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateStorageBlobDnsZoneName
  location: 'global'
}

resource privateStorageTableDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateStorageTableDnsZoneName
  location: 'global'
}

resource privateStorageFileDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateStorageFileDnsZoneName
  location: 'global'
}

resource privateCosmosDbDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateCosmosDbDnsZoneName
  location: 'global'
}

resource privateStorageQueueDnsZoneName_privateStorageQueueDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateStorageQueueDnsZone
  name: '${privateStorageQueueDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.outputs.resourceId
    }
  }
  dependsOn: [
    vnet
  ]
}

resource privateStorageTableDnsZoneName_privateStorageTableDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateStorageTableDnsZone
  name: '${privateStorageTableDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.outputs.resourceId
    }
  }
  dependsOn: [
    vnet
  ]
}

resource privateStorageBlobDnsZoneName_privateStorageBlobDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateStorageBlobDnsZone
  name: '${privateStorageBlobDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.outputs.resourceId
    }
  }
  dependsOn: [
    vnet
  ]
}

resource privateStorageBlobDnsZoneName_privateStorageBlobDnsZoneName_vm_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateStorageBlobDnsZone
  name: '${privateStorageBlobDnsZoneName}-vm-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vmSubscriptionId, vmVnetResourceGroupId, 'Microsoft.Network/virtualNetworks', vmVnetName)
    }
  }
  dependsOn: [
    vnet
  ]
}


resource privateStorageFileDnsZoneName_privateStorageFileDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateStorageFileDnsZone
  name: '${privateStorageFileDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.outputs.resourceId
    }
  }
  dependsOn: [
    vnet
  ]
}

resource privateCosmosDbDnsZoneName_privateCosmosDbDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateCosmosDbDnsZone
  name: '${privateCosmosDbDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.outputs.resourceId
    }
  }
  dependsOn: [
    vnet
  ]
}

resource privateCosmosDbDnsZoneName_privateCosmosDbDnsZoneName_vm_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateCosmosDbDnsZone
  name: '${privateCosmosDbDnsZoneName}-vm-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vmSubscriptionId, vmVnetResourceGroupId, 'Microsoft.Network/virtualNetworks', vmVnetName)
    }
  }
  dependsOn: [
    vnet
  ]
}

resource privateEndpointStorageBlob 'Microsoft.Network/privateEndpoints@2019-11-01' = {
  name: privateEndpointStorageBlobName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageBlobPrivateLinkConnection'
        properties: {
          privateLinkServiceId: censusDataStorageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
  dependsOn: [
    vnet
    privateEndpointSubnet
  ]
}

resource privateEndpointStorageBlobName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpointStorageBlob
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageBlobDnsZone.id
        }
      }
    ]
  }
}

resource privateEndpointWebJobsQueueStorage 'Microsoft.Network/privateEndpoints@2019-11-01' = {
  name: privateEndpointWebJobsQueueStorageName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: functionWebJobsStorageAccount.id
          groupIds: [
            'queue'
          ]
        }
      }
    ]
  }
  dependsOn: [
    privateEndpointSubnet
    vnet
  ]
}

resource privateEndpointWebJobsQueueStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpointWebJobsQueueStorage
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageQueueDnsZone.id
        }
      }
    ]
  }
}

resource privateEndpointWebJobsTableStorage 'Microsoft.Network/privateEndpoints@2019-11-01' = {
  name: privateEndpointWebJobsTableStorageName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: functionWebJobsStorageAccount.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
  dependsOn: [
    vnet
    privateEndpointSubnet
  ]
}

resource privateEndpointWebJobsTableStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpointWebJobsTableStorage
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageTableDnsZone.id
        }
      }
    ]
  }
}

resource privateEndpointWebJobsBlobStorage 'Microsoft.Network/privateEndpoints@2019-11-01' = {
  name: privateEndpointWebJobsBlobStorageName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: functionWebJobsStorageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
  dependsOn: [
    privateEndpointSubnet
    vnet
  ]
}

resource privateEndpointWebJobsBlobStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpointWebJobsBlobStorage
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageBlobDnsZone.id
        }
      }
    ]
  }
}

resource privateEndpointWebJobsFileStorage 'Microsoft.Network/privateEndpoints@2019-11-01' = {
  name: privateEndpointWebJobsFileStorageName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: functionWebJobsStorageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
  dependsOn: [
    privateEndpointSubnet
    vnet
  ]
}

resource privateEndpointWebJobsFileStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpointWebJobsFileStorage
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageFileDnsZone.id
        }
      }
    ]
  }
}

resource privateEndpointCosmosDb 'Microsoft.Network/privateEndpoints@2019-11-01' = {
  name: privateEndpointCosmosDbName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyCosmosDbPrivateLinkConnection'
        properties: {
          privateLinkServiceId: privateCosmosDbAccount.id
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
  }
  dependsOn: [
    privateEndpointSubnet
    vnet
  ]
}

resource privateEndpointCosmosDbName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpointCosmosDb
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateCosmosDbDnsZone.id
        }
      }
    ]
  }
}





resource appServicePlan 'Microsoft.Web/serverfarms@2018-02-01' = {
  name: appServicePlanName
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

resource functionApp 'Microsoft.Web/sites@2018-11-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      vnet: 'bead47e1-d65e-4cb4-b907-f74674d32c09_${functionsSubnetName}'
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
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionWebJobsStorageAccountName};AccountKey=${listkeys(functionWebJobsStorageAccount.id, '2018-11-01').keys[0].value};'
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
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionWebJobsStorageAccountName};AccountKey=${listkeys(functionWebJobsStorageAccount.id, '2018-11-01').keys[0].value};'
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
          value: 'DefaultEndpointsProtocol=https;AccountName=${censusDataStorageAccountName};AccountKey=${listkeys(censusDataStorageAccount.id, '2018-11-01').keys[0].value};'
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
          value: listConnectionStrings(privateCosmosDbAccount.id, '2019-12-12').connectionStrings[0].connectionString
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
    vnet
  ]
}

resource functionAppName_virtualNetwork 'Microsoft.Web/sites/networkConfig@2019-08-01' = {
  parent: functionApp
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, functionsSubnetName)
    isSwift: true
  }
  dependsOn: [
    functionSubnet
    vnet
  ]
}


resource Microsoft_Web_sites_config_functionAppName_web 'Microsoft.Web/sites/config@2019-08-01' = {
  parent: functionApp
  name: 'web'
  properties: {
    functionsRuntimeScaleMonitoringEnabled: true
  }
  dependsOn: [
    functionSubnet
    vnet
  ]
}
