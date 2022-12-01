function Get-VmwOrphan{
    <#
    .SYNOPSIS
      Find orphaned files on a datastore
    .DESCRIPTION
      This function will scan the complete content of a datastore.
      It will then verify all registered VMs and Templates on that
      datastore, and compare those files with the datastore list.
      Files that are not present in a VM or Template are considered
      orphaned
    .NOTES
      Author:  Chris Federico
    .PARAMETER Datastore
      The datastore that needs to be scanned
    .EXAMPLE
      PS> Get-VmwOrphan -Datastore DS1
    .EXAMPLE
      PS> Get-Datastore -Name DS* | Get-VmwOrphan
    #>
     
      [CmdletBinding()]
      param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [PSObject[]]$Datastore
      )
     
      #Line 30-62: The script constructs the SearchDatastoreSubFolders parameter in the Begin block.
      #This parameter will be the same for all datastores.

      Begin{
        $flags = New-Object VMware.Vim.FileQueryFlags
        $flags.FileOwner = $true
        $flags.FileSize = $true
        $flags.FileType = $true
        $flags.Modification = $true
        
        $qFloppy = New-Object VMware.Vim.FloppyImageFileQuery
        $qFolder = New-Object VMware.Vim.FolderFileQuery
        $qISO = New-Object VMware.Vim.IsoImageFileQuery
        $qConfig = New-Object VMware.Vim.VmConfigFileQuery
        $qConfig.Details = New-Object VMware.Vim.VmConfigFileQueryFlags
        $qConfig.Details.ConfigVersion = $true
        $qTemplate = New-Object VMware.Vim.TemplateConfigFileQuery
        $qTemplate.Details = New-Object VMware.Vim.VmConfigFileQueryFlags
        $qTemplate.Details.ConfigVersion = $true
        $qDisk = New-Object VMware.Vim.VmDiskFileQuery
        $qDisk.Details = New-Object VMware.Vim.VmDiskFileQueryFlags
        $qDisk.Details.CapacityKB = $true
        $qDisk.Details.DiskExtents = $true
        $qDisk.Details.DiskType = $true
        $qDisk.Details.HardwareVersion = $true
        $qDisk.Details.Thin = $true
        $qLog = New-Object VMware.Vim.VmLogFileQuery
        $qRAM = New-Object VMware.Vim.VmNvramFileQuery
        $qSnap = New-Object VMware.Vim.VmSnapshotFileQuery
        
        $searchSpec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
        $searchSpec.details = $flags
        #Line 61: To get maximum detail for the returned files, 
        #the script uses all available FileQuery variation
        $searchSpec.Query = $qFloppy,$qFolder,$qISO,$qConfig,$qTemplate,$qDisk,$qLog,$qRAM,$qSnap
        $searchSpec.sortFoldersFirst = $true
      }

      
     #Line 69-71: Cheap OBN implementation 
      Process{
        foreach($ds in $Datastore){
          if($ds.GetType().Name -eq "String"){
            $ds = Get-Datastore -Name $ds
          }
     
    # Only shared VMFS datastore
    #Line 75: The script only looks at shared VMFS datastores
          if($ds.Type -eq "VMFS" -and $ds.ExtensionData.Summary.MultipleHostAccess -and $ds.State -eq 'Available'){
            Write-Verbose -Message "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tLooking at $($ds.Name)"
      
    
    #Line 84: This hash table will be used to determine which file/folder is orphaned or not.
    # First all the files the method fins are placed in the hash table.
    # Then the files that belong to VMs and Templates are removed.
    # Finally some system files are removed. What is left are orphaned files.
    # Define file DB
            $fileTab = @{}
     
    # Get datastore files
    #Line 92: Get all the files on the datastore with the SearchDatastoreSubFolders method
    #Line 90-103: Enter the files in the hash table

            $dsBrowser = Get-View -Id $ds.ExtensionData.browser
            $rootPath = "[" + $ds.Name + "]"
            $searchResult = $dsBrowser.SearchDatastoreSubFolders($rootPath, $searchSpec) | Sort-Object -Property {$_.FolderPath.Length}
            foreach($folder in $searchResult){
              foreach ($file in $folder.File){
                $key = "$($folder.FolderPath)$(if($folder.FolderPath[-1] -eq ']'){' '})$($file.Path)"
                $fileTab.Add($key,$file)
     
                #Line 100-102: Take care of the folder entries. If a file inside a folder is encountered, 
                #the script also removes the folder itself from the hash table
                $folderKey = "$($folder.FolderPath.TrimEnd('/'))"
                if($fileTab.ContainsKey($folderKey)){
                  $fileTab.Remove($folderKey)
                }
              }
            }
      
    # Get VM inventory
    # Line 110-113: Remove all files that belong to registered VMs from the hash table

            Get-VM -Datastore $ds | %{
              $_.ExtensionData.LayoutEx.File | %{
                if($fileTab.ContainsKey($_.Name)){
                  $fileTab.Remove($_.Name)
                }
              }
            }
      
    # Line 120-123: Remove all files that belong to registered Templates from the hash table
    # Get Template inventory
            Get-Template | where {$_.DatastoreIdList -contains $ds.Id} | %{
              $_.ExtensionData.LayoutEx.File | %{
                if($fileTab.ContainsKey($_.Name)){
                  $fileTab.Remove($_.Name)
                }
              }
            }
     #Line 129-131: Remove system files. For now these all files that are located in folders that start with a dot, or in a folder named vmkdump.
    # Remove system files & folders from list
            $systemFiles = $fileTab.Keys | where{$_ -match "] \.|vmkdump"}
            $systemFiles | %{
              $fileTab.Remove($_)
            }
     #Line 135-159: If there are entries left in the hash table, collect more information and create an ordered object containing that information.
    # Organise remaining files
            if($fileTab.Count){
              $fileTab.GetEnumerator() | %{
                $obj = [ordered]@{
                  Name = $_.Value.Path
                  Folder = $_.Name
                  SizeGB = [math]::round($_.Value.FileSize/1GB,2)
                  #CapacityGB = [math]::round($_.Value.CapacityKb/1MB,2)
                  Modification = $_.Value.Modification
                  Owner = $_.Value.Owner
                  Thin = $_.Value.Thin
                  Extents = $_.Value.DiskExtents -join ','
                  DiskType = $_.Value.DiskType
                  HWVersion = $_.Value.HardwareVersion
                }
                New-Object PSObject -Property $obj
              }
              Write-Verbose -Message "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tFound orphaned files on $($ds.Name)!"
            }
            else{
              Write-Verbose -Message "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tNo orphaned files found on $($ds.Name)."
            }
          }
        }
      }
    }