
function upgrade-esxi67U3to70U3 () 
{

    <#
	.SYNOPSIS
    Upgrades Host from 6.7U3 to 7.0U3
    
    
	.DESCRIPTION
    This advanced function will update the host to 7.03U by aplying 7.0U3 iso
    in life cycle manager. Reboots then changes the scratch location back to 
    local storage.It then reboots and switched the UCS profile to the new ESXi
    7 template.
    
	.Example
    . .\upgrade-esxi67U3to70U3
    upgrade-esxi67U3to70U3 -vmhost s1c-esxi172.prod.paneravirt.com
    "hosta" | upgrade-esxi67U3to70U3
	.Notes
	NAME: upgrade-esxi67U3to70U3.ps1
    AUTHOR: Chris Federico
	LASTEDIT: 03/01/2023
	VERSION: 1.0
	KEYWORDS: VMware, vSphere, ESXi, Upgrade

#>


    [CmdletBinding()]
    param
    (
    [Parameter(Mandatory=$true,ValueFromPipeline)]
    [string]$vmhostesxi
    )



    Begin {
        # Clear Screen
        Clear-Host

        # Start the logger 
        $filename = "upgrade-esxiLog_" + (get-date -format "MM-dd-yyyy_hh-mm-ss") + ".txt"
        start-transcript -path .\$filename -force
        
    }

    Process{

        # Get name of service profile 
        $serviceProfile = $vmhostesxi.split('.')
        $serviceProfile = $serviceProfile[0].ToUpper()
	    $srcTemplName = "PaneraVirtProd7"

        #######################################
        # Task 1 put host in Maintenance Mode#
        #######################################
        write-host ""
        write-host "##########################################"
        read-host "Working on $vmhostesxi....."
        read-host "Service Profile Name is $serviceProfile"

        write-host "Task 1 INFO: Place $vmhostesxi in maintenance mode"
        set-vmhost -vmhost $vmhostesxi -state "Maintenance" | out-null

        #############################################################################
        # Task 2 attach baseline UCS 4.2.1 with vSphere 7.0U3 to Host and remediate#
        #############################################################################
        write-host "Task 2 INFO: Next attach baseline."
        $baseline = Get-Baseline -TargetType host -BaselineType Upgrade -Name "UCS 4.2.1 with vSphere 7.0U3"
        attach-baseline -entity $vmhostesxi -baseline $baseline
        write-host "Task 2 INFO: Next remediate"
        # Remediate baseline for $vmhostesxi
        Remediate-Inventory -Entity $vmhostesxi -Baseline $baseline -Confirm:$false -ErrorAction SilentlyContinue

        #######################################
        # Task 3 Change local scratch location#
        #######################################
        write-host "Task 3 INFO: Change scratch location"

        # create VMHost object
        $vmhost = get-vmhost $vmhostesxi
        # Create esxcli object
        $esxcli = get-esxcli -V2 -vmHost $vmhost
        # Capture UUID so we can set it later
        $scratchUuid = $esxcli.storage.vmfs.extent.list.Invoke() | Where-Object {$_.VolumeName -like "OSDATA*"} | select -ExpandProperty VMFSUUID
        # Set the New Scratch location
        $vmhost | Get-AdvancedSetting -Name ScratchConfig.ConfiguredScratchLocation | set-advancedsetting -Value "/vmfs/volumes/$($scratchUuid)" -Confirm:$false | out-null
        # Shutdown host
        stop-vmhost $vmhost -RunAsync -Confirm:$false | out-null

        #################################################################
        # Task 4 Get status of blade in UCS to make use its powered off #
        # Change template and restart pending service profile           #
        #################################################################
        write-host "Task 4 INFO: Gettings status of $serviceProfile in UCS to make sure its powered off"
        # Sleep a bit 
        start-sleep 7

        write-host "Task 4 INFO: Waiting for UCS $serviceProfile to power off in UCS"

        do {
            $server = get-UCSServiceProfile -Name $serviceProfile
            $state = $server.OperState
            write-host -ForegroundColor Yellow -NoNewline "."
        }while ($state -ne "power-off")
        write-host -ForegroundColor Yellow -NoNewline "(Blade is powered off)"


        write-host ""
        write-host "Taks 4 INFO: Change source template"
        $server | set-UCSServiceProfile -SrcTemplName $SrcTemplName -Force | out-null
        write-host "Acknowledge pending reboot of $serviceProfile "
        get-UCSLsmaintack -ServiceProfile $serviceProfile | set-UcsLsmaintAck -AdminState "trigger-immediate" -Force | out-null

        write-host ""

        write-host "Task 5 INFO: Waiting for $vmhostesxi to be powered down (according to vCenter)"

        
	    ## Wait for host to show disconnected in vCenter 
        
	    do {
		start-sleep 2
		$ServerState = (Get-VMHost $vmhostesxi).ConnectionState
		Write-Host -ForegroundColor Yellow -NoNewline "."
	       } while ($ServerState -ne "NotResponding")
	    Write-Host -ForegroundColor Yellow -NoNewline "(Server is powered down)"

        write-host ""
        Write-host "Task 6 INFO: Waiting for $vmhostesxi to come back online (according to vCenter)"

	    ## Waiting for the host to come back online 
	    do {
		    start-sleep 2
		    $ServerState = (Get-VMHost $vmhostesxi).ConnectionState
		    Write-Host -ForegroundColor Yellow -NoNewline "`."
	       } while ($ServerState -ne "Maintenance")
		Write-Host -ForegroundColor Yellow "(Server is Powered Up)"


        ## Get out of Maintenance Mode
    
        Write-Host -ForegroundColor Yellow "Task 7: $vmhostesxi Exiting Maintenance Mode"
        Set-VMHost $vmhostesxi -State Connected  | Out-Null
        Write-Host -ForegroundColor Yellow "$vmhostesxi Reboot Cycle Done!"
        Write-Host ""



    }

    End {
        # Stop Logging
        stop-transcript
    }
}
