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

$vm = Get-AzVM `
    -ResourceGroupName $resourceGroup `
    -Name $vmName

$osSnapshot = New-AzSnapshotConfig `
    -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id `
    -Location $location `
    -CreateOption copy

$snapshotOsName = "$($vm.StorageProfile.OsDisk.Name)_Snapshot_$(Get-Date -Format dd_MM_yyyy)"

New-AzSnapshot `
    -Snapshot $osSnapshot `
    -SnapshotName $snapshotOsName `
    -ResourceGroupName $resourceGroup

Get-AzSnapshot `
    -ResourceGroupName $resourceGroup


