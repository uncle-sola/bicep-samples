#
# Customer specific parameters 
#  Connect-AzAccount -SubscriptionId b16cc792-dc1d-4942-ac9a-0ff659eb9f38
# https://learn.microsoft.com/en-us/azure/virtual-machines/windows-in-place-upgrade#powershell-script
# https://charbelnemnom.com/in-place-upgrade-windows-server-vms-in-azure/


#  Connect-AzAccount -SubscriptionId b16cc792-dc1d-4942-ac9a-0ff659eb9f38

# Resource group of the source VM
$resourceGroup = "sb-dev-vm-rg"

# Location of the source VM
$location = "uksouth"

# vmName 
$vmName = "sb-dev-vm"

# Zone of the source VM, if any
$zone = "" 

# Disk name for the that will be created
$upgradeDiskName = "WindowsServer2022UpgradeDisk"

# Target version for the upgrade - must be either server2022Upgrade or server2019Upgrade
$sku = "server2022Upgrade"


# Common parameters

$publisher = "MicrosoftWindowsServer"
$offer = "WindowsServerUpgrade"
$managedDiskSKU = "Standard_LRS"

#
# Get the latest version of the special (hidden) VM Image from the Azure Marketplace

$versions = Get-AzVMImage -PublisherName $publisher -Location $location -Offer $offer -Skus $sku | sort-object -Descending {[version] $_.Version	}
$latestString = $versions[0].Version


# Get the special (hidden) VM Image from the Azure Marketplace by version - the image is used to create a disk to upgrade to the new version


$image = Get-AzVMImage -Location $location `
                       -PublisherName $publisher `
                       -Offer $offer `
                       -Skus $sku `
                       -Version $latestString

#
# Create Resource Group if it doesn't exist
#

if (-not (Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $resourceGroup -Location $location    
}

#
# Create Managed Disk from LUN 0
#

if ($zone){
    $diskConfig = New-AzDiskConfig -SkuName $managedDiskSKU `
                                   -CreateOption FromImage `
                                   -Zone $zone `
                                   -Location $location
} else {
    $diskConfig = New-AzDiskConfig -SkuName $managedDiskSKU `
                                   -CreateOption FromImage `
                                   -Location $location
} 

Set-AzDiskImageReference -Disk $diskConfig -Id $image.Id -Lun 0

New-AzDisk -ResourceGroupName $resourceGroup `
           -DiskName $upgradeDiskName `
           -Disk $diskConfig


           

           
$upgradeDataDisk = Get-AzDisk -DiskName $upgradeDiskName -ResourceGroupName $resourceGroup
           
$vm = Get-AzVM -Name $vmName -ResourceGroupName $resourceGroup
$vm = Add-AzVMDataDisk -VM $vm -Name $upgradeDiskName -CreateOption Attach -ManagedDiskId $UpgradeDataDisk.Id -Lun 0
           
Update-AzVM -VM $vm -ResourceGroupName $resourceGroup           