 
 # This script creates a snapshot report. Uses the Get-VIEvent cmdlet. Creates objects ans then exports the object to a CSV file.
 
 Begin {
     #Create an empty array for report
    $report = @()

 }
 

 Process{
# Create Snaps array 
 foreach ($snap in Get-VM | Get-Snapshot)
 {$snapevent = Get-VIEvent -Entity $snap.VM -Types Info -Finish $snap.Created -MaxSamples 1 | Where-Object {$_.FullFormattedMessage -imatch 'Task: Create virtual machine snapshot'}
 
 if ($null -ne $snapevent){
# Create object for custom reporting
    $myobject = New-Object psobject -Property @{

        VM = $snap.VM
        SNAPSHOT = $snap.Name
        CREATED = $snap.Created.DateTime
        SNAPOWNER = $snapevent.UserName
        SIZEGB = "{0:F2}" -f $snap.SizeGB
    }

$report += $myobject


 }
 
 else {

$myobject = New-Object psobject -Property @{
# Create object for custom reporting
        VM = $snap.VM
        SNAPSHOT = $snap.Name
        CREATED = $snap.Created.DateTime
        SNAPOWNER = "This event is not in vCenter events Database"
        SIZEGB = "{0:F2}" -f $snap.SIZEGB
    }

  $report += $myobject


}


}
 

 }


 End{
# Create Report
$report | sort-object Created | select-object VM,SNAPSHOT,CREATED,SNAPOWNER,SIZEGB | export-csv .\vcsnapreport.csv

 }