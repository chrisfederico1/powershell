# The folowing script will apply backup tags to VM's based on what folders they are in vCenter 
# for example all VM's in Avamar Backup 0200 folder will receive the 0200 tag. EVEN if there are multiple folders with the same name.
# Note only connect to one vCenter at a time !!

# Start Logging
Start-Transcript -path .\applyvmtagslog.txt -Force

# clear Screen
Clear-Host

# Show information to user and ask to continue
write-host "Note: the following script applies tags to VM's . Only connect to ONE vCenter at a time." -BackgroundColor Red


# Ask user if they would like to continue
$reply = Read-host "Would you like to Proceed ?[y/n]"
if ($reply -match "[nN]")
{
	exit 
}

# insert 2 blank lines
"";""

# Define Tags
write-host "Info: Gathering Tag inforamtion"
$0200 = get-tag 0200
$1700 = get-tag 1700
$2200 = get-tag 2200

# insert 2 blank lines
"";""

# Define vm arrays for Backup Folders 

# All Avamar VM's in the 0200 folder
write-host "INFO: Gathereing all VMs in Avamar Backup 0200...."
$AVBKUP0200VM = Get-Folder -Name  'Avamar Backup 0200' | Get-VM
write-host "INFO: Number of VM's in Avamar Backup 0200 "$AVBKUP0200VM.Count

# insert 2 blank lines
"";""

# All Avamar VM's in the 1700 folder
write-host "INFO: Gathereing all VMs in Avamar Backup 1700...."
$AVBKUP1700VM = Get-Folder -Name 'Avamar Backup 1700' | Get-VM
write-host "INFO: Number of VM's in Avamar Backup 1700 "$AVBKUP1700VM.count

# insert 2 blank lines
"";""


# All Avamar VM's in the 2200 folder
write-host "INFO: Gathereing all VMs in Avamar Backup 2200...."
$AVBKUP2200VM = Get-Folder -Name 'Avamar Backup 2200' | Get-VM
write-host "INFO: Number of VM's in Avamar Backup 2200 "$AVBKUP2200VM.count

# insert 2 blank lines
"";""


# Ask user if they would like to continue
$reply = Read-host "Updating VM's with tags ...Would you like to Proceed ?[y/n]" 
if ($reply -match "[nN]")
{
	exit 
}

# Assing tags to VMs

# For 0200 tag
foreach ($vm in $AVBKUP0200VM)
{
    New-TagAssignment -tag $0200 -Entity $vm
}

# insert 2 blank lines
"";""


# For 1700 tag 
foreach ($vm in $AVBKUP1700VM)
{
   New-TagAssignment -tag $1700 -Entity $vm
}


# insert 2 blank lines
"";""


# For 2200 tag 
foreach ($vm in $AVBKUP2200VM)
{
   New-TagAssignment -tag $2200 -Entity $vm
}

# Stop logging
Stop-Transcript