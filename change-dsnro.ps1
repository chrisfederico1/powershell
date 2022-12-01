Function change-dsnro()

{

<#
	.SYNOPSIS
    This script changes the DSNRO setting 
    
	.DESCRIPTION
    This script changes the MaxDepthQueue and DSNRO settings which is set on a LUN level (as of vSphere 6.5). It also creates a log file with before values and after values 
	.Example
    change-dsnro -ClusterName ClusterName -MAXQDepth 256 -DSNROval 64  
    change-dsnro -VMHost VMHostName -MAXQDepth 256 -DSNROval 64

	    
	.Notes
	NAME: change-dsnro.ps1
    AUTHOR: Chris Federico  
	LASTEDIT: 07/29/2022
	VERSION: 1.0
	KEYWORDS: VMware, vSphere, ESXi, VM, DSNRO

#>

# Parameters
[CmdletBinding()]
param
(
    [Parameter(Mandatory=$false)]
    [string]$ClusterName,

    [Parameter(Mandatory=$false)]
    [string]$VMHost,

    [Parameter(Mandatory=$true)]
    [INT]$DSNROval,

    [Parameter(Mandatory=$true)]
    [INT]$MAXQDepth
    
)

    Begin

    {

        # Clear Screen
        Clear-Host

        # Start the logger
        $filename = "dsnro-log_" + (get-date -Format "MM-dd-yyyy_hh-mm-ss") + ".txt"
        Start-Transcript -path .\$filename -Force
    }

    Process

   {

    if ($ClusterName)
    {
        # Show current values of DSNRO for each Lun 
        write-host "INFO: Showing all DSNRO values before change for Cluster $ClusterName"
        write-host ""
        #Get VMHosts in an array
        $cluster = get-cluster -Name $ClusterName  | Get-VMHost
        start-sleep 1
        

        #Cycle thru Cluster of VMhosts
        foreach ($esxi in $cluster)
        
        {
            $esxcli = get-esxcli -VMHost $esxi -V2
            write-host ""
            write-host "INFO: Working on $esxi "
            write-host ""
            start-sleep 1
            #list each Lun and DSNRO value . The displayname is the NAA. #
            $esxcli.storage.core.device.list.invoke() | select-object DisplayName, DeviceMaxQueueDepth, NoofoutstandingIOswithcompetingworlds
            start-sleep 1
        }

        # Ask user if they would like to continue
        write-host ""
        $reply = Read-host "Would you like to proceed in changing these values to $DSNROval" 
            if ($reply -match "[nN]")
                {
    	            exit 
                }
    
        # Change the value of DSNRO to the specified value 
        foreach ($esxi in $cluster) 
        
            {
            $esxcli = get-esxcli -VMHost $esxi -V2
            $esxcli.storage.vmfs.extent.list.Invoke() | foreach-object { $esxcli.storage.core.device.set.Invoke(@{device = $_.DeviceName; maxqueuedepth = $MAXQDepth }) }
            $esxcli.storage.vmfs.extent.list.Invoke() | foreach-object { $esxcli.storage.core.device.set.Invoke(@{device = $_.DeviceName; schednumreqoutstanding  = $DSNROval }) } 
        
            write-host ""
            write-host "Showing results after the change for $esxi"
            write-host ""
        $esxcli.storage.core.device.list.invoke() | select-object DisplayName, DeviceMaxQueueDepth, NoofoutstandingIOswithcompetingworlds
            }
    }
   

    

    if ($VMHost)
    {
        # Show current values of DSNRO for each Lun 
        write-host "INFO: Showing all DSNRO values before change for VMHost $VMHost"
        write-host ""
        
            $esxcli = get-esxcli -VMHost $VMHost -V2
            write-host ""
            write-host "INFO: Working on $VMHost "
            write-host ""
            $esxcli.storage.core.device.list.invoke() | select-object DisplayName, DeviceMaxQueueDepth, NoofoutstandingIOswithcompetingworlds

            # Ask user if they would like to continue
            write-host ""
            $reply = Read-host "Would you like to proceed in changing these values to $DSNROval" 
            if ($reply -match "[nN]")
                {
    	            exit 
                }

        $esxcli = get-esxcli -VMHost $VMHost -V2

        $esxcli.storage.vmfs.extent.list.Invoke() | foreach-object { $esxcli.storage.core.device.set.Invoke(@{device = $_.DeviceName; maxqueuedepth = $MAXQDepth }) }
        $esxcli.storage.vmfs.extent.list.Invoke() | foreach-object { $esxcli.storage.core.device.set.Invoke(@{device = $_.DeviceName; schednumreqoutstanding  = $DSNROval }) } 
        
        write-host ""
        write-host "Showing results after the change for $VMHost"
        write-host ""
        $esxcli.storage.core.device.list.invoke() | select-object DisplayName, DeviceMaxQueueDepth, NoofoutstandingIOswithcompetingworlds

          
    }

}
    

       

    End
        {
            # Stop Logging
            write-host ""
            Stop-Transcript

        }

}






