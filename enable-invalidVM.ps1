Function enable-invalidVM()
{

<#
	.SYNOPSIS
    Fix invalid VM . This is specific to company.
    
	.DESCRIPTION
    This Function will remove the invalid VM from inventory then register VM based on VMFilePath. Lately it will remove nonlocal disks 
    and start the VM .
	.Example
    fix-invalidVM -Name test
	    
	.Notes
	NAME: enable-invalidVM.ps1
    AUTHOR: Chris Federico  
	LASTEDIT: 02/14/2020
	VERSION: 1.0
	KEYWORDS: VMware, vSphere, ESXi, VM, Invalid

#>

# Parameters
[CmdletBinding()]
param
(
    [Parameter(Mandatory=$true)]
    [string]$VMName
)

Begin{

    # Clear Screen
    Clear-host

    # Add start-transact here for logging
    Start-Transcript -path .\enable-invalid-vmlogging.txt

    # Give the user information on which VM they entered. 
    write-host " INFO: You entered VM:" $VMName -BackgroundColor Red

    # Enter 2 spaces 
    "";""

    # Ask user if they would like to continue
    $reply = Read-host "Would you like to Proceed ?[y/n]"
    if ($reply -match "[nN]")
    {
	    exit 
    }

    

     
}

Process{

    # Present data to the user
    write-host "INFO: Verifying if VM is present and is in an invalid state...." -ForegroundColor Yellow
    
    try{
        # Get view of VM
        $vminfo = get-vm -name $VMName -ErrorAction Stop | get-view | Select-Object Name,@{N='ConnectionState';E={$_.runtime.connectionstate}}
        
        # Let user know VM is present
        write-host "INFO: VM is present verifying connection state...." -ForegroundColor Yellow

        if ($vminfo.ConnectionState -match "invalid")
        {
            write-host "INFO: VM is invalid" -ForegroundColor Yellow
                     

            #****** This section doesn't work . When trying to reload VM a general Error is observed
            #write-host "INFO: Reloading VM...." -ForegroundColor Green
            #$vminfo = get-vm -name $Name | foreach-object {get-view $_.reload()}
            #$Vmview = get-vm -name $VMName | Get-View
            #$Vmview.Reload()


            #***********Get Information about VM so we can remove it from inventory and add it back in************

            # Get VM Path to .vmx file
            write-host "INFO: Getting VMX path...." -ForegroundColor Yellow
            $vmxPath = get-vm -name $VMName | `
            add-member -MemberType ScriptProperty -Name 'VMXPath' -value {$this.extensiondata.config.files.vmpathname} -passthru -force | select-object Name,VMXPath
            write-host "INFO: VMX Path...." $vmxPath.VMXPath -ForegroundColor Yellow
            # Get VMHost the VM is on 
            $VMHost = get-vm -name $VMName | Get-VMHost
            write-host "INFO: $VMName is on Host...." $VMHost.Name -ForegroundColor Yellow
            # Get Folder location ID
            $VMFolderID = get-vm -Name $VMName | Select-Object -ExpandProperty FolderID
            write-host "INFO: $VMName is located in folder...." $VMFolderID -ForegroundColor Yellow
            # Get Resource Pool ID
            $VMResourcePoolID = get-vm -Name $VMName | Select-Object -ExpandProperty ResourcePoolID
            write-host "INFO: $VMName is in Resource Pool...." $VMResourcePoolID -ForegroundColor Yellow

            #******************Remove the VM from inventory*********************

            #******************Add the VM back into inventory*******************



        }
        else{
            write-host "INFO: VM is not invalid. Please run script again with VM that is in invalid state." -ForegroundColor Red
            
        }        
    }
    catch{

        Write-Output "INFO:A Error occured." "" $error[0] ""
    }

    # Enter 2 spaces 
    "";""

}


End{

Stop-Transcript

}


}