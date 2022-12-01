function Start-UNMAP{

<#
	.SYNOPSIS
    Process SCSI UNMAP on VMware Datastore
    
	.DESCRIPTION
    This Function will process SCSI UNMAP on VMware Datastore via ESXCLI -V2. Remember to dot source. Note USE host that has access
    Datastore.
	.Example
    Start-UNMAP -VMHost MyHost -DataStore myDataStore 
	.Example
    Start-UNMAP -VMHost MyHost -Datastore myDatastore -Verbose -WhatIf
	.Notes
	NAME: Start-UNMAP.ps1
    AUTHOR: Chris Federico  
	LASTEDIT: 01/07/2020
	VERSION: 1.0
	KEYWORDS: VMware, vSphere, ESXi, SCSI, VAAI, UNMAP
   
 #>


 
 
    
# Parameters
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$VMHost,

        [Parameter(Mandatory=$true)]
        [string]$Datastore
       
    )

BEGIN{
    # Clear Screen
    Clear-host

    # Add start-transact here
    Start-Transcript -path .\vmfsunmaplogging.txt -Append

    # Give user information about which server and datastore they choose
    write-host "You selected host " $VMHost " with datastore " $Datastore -BackgroundColor Red

    # Ask user if they would like to continue
    $reply = Read-host "Would you like to Proceed ?[y/n]"
    if ($reply -match "[nN]")
    {
	exit 
    }


    # Add spaces
    "";""

# Verification of Host and Datastore
write-host "INFO: Verifying Host"

try {

    $EsxiHost = get-vmhost $VMHost
}

catch{

    Write-Output "An Error Occured: " "" $error[0] ""
}

write-host "INFO: Verifiying Datastore"


try {

    $DataStoreName = get-datastore $Datastore
}

catch{

    Write-Output "An Error Occured: " "" $error[0] ""
}

}
PROCESS {

    # Connect to Host
    write-host "INFO: Connecting to ESXi Host: $VMHost" -ForegroundColor Green
    $esxcli = Get-EsxCli -VMHost $EsxiHost -V2

    # Create Args
    $arguments = $esxcli.storage.vmfs.unmap.CreateArgs()
    $arguments.volumelabel = $DataStoreName
    $arguments.reclaimunit = "256"


    # Start unmapping.
    write-host "INFO: Unmapping $Datastore on $VMHost. This may take awhile depending on size of datastore." -ForegroundColor Green
    
    # Stopwatch code
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $esxcli.storage.vmfs.unmap.Invoke($arguments) 
    }
    catch{
        Write-Output "A Error occured: " "" $error[0] ""
    }

    $stopwatch.Stop()
    write-output "INFO: UNMAP duration: $($stopwatch.Elapsed.Minutes)"

}

END {

    # Stop Logging
    Stop-Transcript

}

}
