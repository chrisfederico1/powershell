#Import powercli
#get-module -name VMware* -ListAvailable | import-module

#get credential 
#$password = get-credential

#Connect to vCenter Server
#Connect-VIServer -server s1-vcenter01 -Credential $password

#Get-Cluster and the Host names in Cluster
#$myvmhosts = get-cluster -Name s1-PreProd01 | get-vmhost | select Name

$myvmhosts = get-vmhost -Name s1a-esxi038.prod.paneravirt.com

foreach ($myvmhost in $myvmhosts)

{
    write-host "Working on .... " ($myvmhost.name)
    $esxcli = Get-EsxCli -VMhost $myvmhost.Name -V2
    
    #$devices = $esxcli.storage.core.device.list.invoke() | select-object device,Vendor,NoofoutstandingIOswithcompetingworlds,DeviceMaxQueueDepth
    #$devices = $esxcli.storage.core.device.list.invoke()
 $pList = $esxcli.system.module.parameters.list.CreateArgs()
 $pList['module'] = 'nfnic'
 $esxcli.system.module.parameters.list.Invoke($pList)
}

    


