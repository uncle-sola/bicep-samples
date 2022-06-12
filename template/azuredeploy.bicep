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
param bastionSubnetAddressPrefix string = '10.100.3.0/27'
param virtualMachineSubnetAddressPrefix string = '10.100.2.0/24'
param functionSubnetAddressPrefix string = '10.100.0.0/24'
param privateEndpointSubnetAddressPrefix string = '10.100.1.0/24'

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
var bastionPublicIPAddressName_var = '${uniqueStringId}-bastion-pip'
var dnsLabelPrefix = 'a${uniqueStringId}-vm'
var bastionHostName_var = '${uniqueStringId}-bastion-host'
var bastionSubnetName = 'AzureBastionSubnet'
var appInsightsResourceId = applicationInsightsName.id

resource vnetName 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  location: location
  name: vnetName_var
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: functionsSubnetName
        properties: {
          addressPrefix: functionSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: 'webapp'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
                actions: [
                  'Microsoft.Network/virtualNetworks/subnets/action'
                ]
              }
            }
          ]
        }
      }
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: privateEndpointSubnetAddressPrefix
          privateLinkServiceNetworkPolicies: 'Enabled'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: vmSubnetName
        properties: {
          addressPrefix: virtualMachineSubnetAddressPrefix
          networkSecurityGroup: {
            id: vmNsgName.id
          }
          delegations: []
          serviceEndpoints: []
          privateLinkServiceNetworkPolicies: 'Enabled'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetAddressPrefix
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource censusDataStorageAccountName 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  location: location
  name: censusDataStorageAccountName_var
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
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

resource censusDataStorageAccountName_default_blobContainerName 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: '${censusDataStorageAccountName_var}/default/${blobContainerName}'
  dependsOn: [
    censusDataStorageAccountName
  ]
}

resource functionWebJobsStorageAccountName 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  location: location
  name: functionWebJobsStorageAccountName_var
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
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

resource functionWebJobsStorageAccountName_default_myfunctionfiles 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-09-01' = {
  name: '${functionWebJobsStorageAccountName_var}/default/myfunctionfiles'
  dependsOn: [
    functionWebJobsStorageAccountName
  ]
}

resource vmDiagnosticStorageAccountName 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: vmDiagnosticStorageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
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
    publicNetworkAccess: 'Disabled'
  }
}

resource privateCosmosDbAccountName_cosmosDbDatabaseName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-01-15' = {
  parent: privateCosmosDbAccountName
  name: cosmosDbDatabaseName
  properties: {
    resource: {
      id: cosmosDbDatabaseName
    }
    options: {}
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
        storageUri: vmDiagnosticStorageAccountName.properties.primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    vmNicName
  ]
}

resource shutdown_computevm_virtualMachineName 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${virtualMachineName_var}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '1900'
    }
    timeZoneId: 'UTC'
    notificationSettings: {
      status: 'Disabled'
    }
    targetResourceId: virtualMachineName.id
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
  properties: ''
}

resource privateStorageBlobDnsZoneName 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateStorageBlobDnsZoneName_var
  location: 'global'
  properties: ''
}

resource privateStorageTableDnsZoneName 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateStorageTableDnsZoneName_var
  location: 'global'
  properties: ''
}

resource privateStorageFileDnsZoneName 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateStorageFileDnsZoneName_var
  location: 'global'
  properties: ''
}

resource privateCosmosDbDnsZoneName 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateCosmosDbDnsZoneName_var
  location: 'global'
  properties: ''
}

resource privateStorageQueueDnsZoneName_privateStorageQueueDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateStorageQueueDnsZoneName
  name: '${privateStorageQueueDnsZoneName_var}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetName.id
    }
  }
}

resource privateStorageTableDnsZoneName_privateStorageTableDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateStorageTableDnsZoneName
  name: '${privateStorageTableDnsZoneName_var}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetName.id
    }
  }
}

resource privateStorageBlobDnsZoneName_privateStorageBlobDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateStorageBlobDnsZoneName
  name: '${privateStorageBlobDnsZoneName_var}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetName.id
    }
  }
}

resource privateStorageFileDnsZoneName_privateStorageFileDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateStorageFileDnsZoneName
  name: '${privateStorageFileDnsZoneName_var}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetName.id
    }
  }
}

resource privateCosmosDbDnsZoneName_privateCosmosDbDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateCosmosDbDnsZoneName
  name: '${privateCosmosDbDnsZoneName_var}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetName.id
    }
  }
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

resource bastionHostName 'Microsoft.Network/bastionHosts@2019-11-01' = {
  name: bastionHostName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, bastionSubnetName)
          }
          publicIPAddress: {
            id: bastionPublicIPAddressName.id
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName
  ]
}

resource vmNicName 'Microsoft.Network/networkInterfaces@2018-11-01' = {
  name: vmNicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, vmSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName
  ]
}

resource bastionPublicIPAddressName 'Microsoft.Network/publicIPAddresses@2018-11-01' = {
  name: bastionPublicIPAddressName_var
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

resource vmNsgName 'Microsoft.Network/networkSecurityGroups@2019-04-01' = {
  name: vmNsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'Block_RDP_Internet'
        properties: {
          description: 'Block RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 101
          direction: 'Inbound'
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
}

resource functionAppName_virtualNetwork 'Microsoft.Web/sites/networkConfig@2019-08-01' = {
  parent: functionAppName
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, functionsSubnetName)
    isSwift: true
  }
  dependsOn: [
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
    vnetName
  ]
}
