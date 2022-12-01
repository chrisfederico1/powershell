Function VMReport ($vm)
{


# VLAN
$vlan = get-networkadapter -vm $vm

# Cluster
$cluster = get-cluster -VM $vm

# VM Name
$VMName = $vm.name

# PowerState
$powerstate = $vm.powerstate

# VM Operating System
$vmos = get-vmguest -VM $vm

# Number of CPU
$numcpu = $vm.numcpu

# Memory in GB
$memorygb = $vm.memorygb

# Used Storage
$UsedSpaceGB = $vm.UsedSpaceGB

#Provisioned Space GB
$ProvisionedSpaceGB = $vm.ProvisionedSpaceGB

# IP Address
$IPAddress = get-vmguest -VM $vm

# Location 
$DataCenter = get-datacenter -VM $vm

# VM Host
$VMHost = get-VMHost -VM $vm

# Is MemoryHotAddenabled ? 
$MemHotAddEnabled = ($vm | select-object ExtensionData).ExtensionData.config | select-object -ExpandProperty MemoryHotAddenabled 

# Is CPUHotAddEnabled ?
$CPUHotAddEnabled = ($vm | Select-object ExtensionData).ExtensionData.config | Select-object -ExpandProperty CPUHotAddEnabled

# VM Hardware Version
$Version = $vm.HardwareVersion

# VM Tools Version and VM Tools VersionStatus
New-VIProperty -Name ToolsVersion -ObjectType VirtualMachine -ValueFromExtensionProperty 'Config.tools.ToolsVersion' -Force | Out-Null
    
    
New-VIProperty -Name ToolsVersionStatus -ObjectType VirtualMachine -ValueFromExtensionProperty 'Guest.ToolsVersionStatus' -Force | Out-Null

$ToolsVersion = $vm.ToolsVersion
$ToolsVersionStatus = $vm.ToolsVersionStatus



# Create the object being used for report
$object = new-object psobject -Property @{

    VLAN = $vlan.NetworkName
    CLUSTER  = $cluster
    NAME = $VMName
    POWERSTATE = $powerstate
    OS = $vmos.osfullname
    NUMCPU = $numcpu
    MEMGB = $memorygb
    USEDSPACE = "{0:F2}" -f $UsedSpaceGB
    PROVISIONEDSTORAGEGB = "{0:F2}" -f $ProvisionedSpaceGB
    IPADDRESS = [string]$IPAddress.IPAddress
    DATACENTER = $DataCenter
    VMHOST = $VMHost.Name
    MemHotAddEnabled = $MemHotAddEnabled
    CPUHotAddEnabled = $CPUHotAddEnabled
    VMHardwareVersion = $Version
    ToolsVersion = $ToolsVersion
    ToolsVersionStatus = $ToolsVersionStatus

    
}
write-output $object
}

###########################Entry point for Script########################################

#No Errors shown
#$ErrorActionPreference = "SilentlyContinue"

$vm = get-vm

$vm | ForEach-Object{ VMReport $_ }| Select-object NAME,POWERSTATE,IPADDRESS,VLAN,OS,NUMCPU,MEMGB,MemHotAddEnabled,CPUHotAddEnabled,VMHardwareVersion,ToolsVersion,ToolsVersionStatus,USEDSPACE,PROVISIONEDSTORAGEGB,CLUSTER,DATACENTER,VMHOST | Export-Csv -NoTypeInformation .\vmreport.csv

