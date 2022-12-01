# The following script accepts input of SingleVM or Cluster Name.  
# These settings disable the time sync to the VMhost . https://kb.vmware.com/s/article/1189


function ClusterVMs ($ExtraValues) {

	# Get Cluster Name
	$Cluster = read-host 'Input Cluster Name'
	Write-host "Warning : You are about to add advanced Time Sync Settings to all VMs in the following Cluster: $Cluster" -BackgroundColor Red

	$reply = read-host "Continue?[y/n]"
	if ($reply -match "[nN]")
	{
	exit 
	}

	# Get vms in Cluster
try { 
	$vmlist = get-cluster -Name $Cluster -ErrorAction Stop | get-vm 
	}
	catch {
		# Error Handling
		Write-host "An Error Occured: Cannot find Cluster"
		write-host $_.ScriptStackTrace
		exit
	}

	foreach ($vm in $vmlist)


	{
		$vmview = get-view -ViewType VirtualMachine -Filter @{"Name" = $vm.Name} #| where-object {-not $_.config.template}
		
		$vmConfigSpec = new-object VMware.Vim.VirtualMachineConfigSpec
		
		# Gathering settings and prepare for adding it to virtual machine settings
		
		$ExtraValues | ForEach-Object GetEnumerator | ForEach-Object {
			$extra = New-object VMware.Vim.OptionValue
			$extra.key = $_.key
			$extra.value=$_.value
			$vmConfigSpec.ExtraConfig += $extra
		}
		
		# Performing commit to Virtual Machine.

		write-host "INFO: Reconfiguring " $vm.Name
		$vmview.ReconfigVM($vmConfigSpec)
		
	}
	
}

function SingleVM ($ExtraValues) {

	# Enter Blank line
	""

	# Prompt User for VM Name
	$svm = read-host "Enter VM Name"

	
		$vmview = get-view -ViewType VirtualMachine -ErrorAction Stop -Filter @{"Name" = $svm}
	
	

	$vmConfigSpec = new-object VMware.Vim.VirtualMachineConfigSpec

	$ExtraValues | ForEach-Object GetEnumerator | ForEach-Object {
		$extra = New-object VMware.Vim.OptionValue
		$extra.key = $_.key
		$extra.value=$_.value
		$vmConfigSpec.ExtraConfig += $extra
	}
		# Performing commit to Virtual Machine.
		write-host "INFO: Reconfiguring " $svm
		""
		try {

			$vmview.ReconfigVM($vmConfigSpec)
		}
		catch {

			# Error Handling
			Write-host "An Error Occured: Cannot find VM"
			write-host $_.ScriptStackTrace
			exit

		}
	
}


################ Script starts here ###############

Start-Transcript -path .\disablevmtimesynclog.txt -Force


# Clear Screen
Clear-Host

# Prompt User to select Single VM or Cluster Name
write-host "1   Cluster"
Write-host "2   Single VM"

# 1 Blank line
""

# Creating a hash table with key-values for disable time sync advanced settings
$ExtraValues = @{
	"tools.syncTime"="0";
	"time.synchronize.continue"= "0";
	"time.synchronize.restore"= "0";
	"time.synchronize.resume.disk"= "0";
	"time.synchronize.shrink"= "0";
	"time.synchronize.tools.startup"= "0";
	"time.synchronize.tools.enable"= "0";
    "time.synchronize.resume.host"= "0" 
}

# Capture response from user
$response = read-host "Please enter 1 or 2"

switch ($response)
{
    "1" {ClusterVMs($ExtraValues)}
	"2" {SingleVM($ExtraValues)}
	default {"Invalid Entry";break}
}

# Stop logging
Stop-Transcript