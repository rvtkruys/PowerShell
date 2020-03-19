<#
.SYNOPSIS
    Deletes compressed files, older than 6 months

.DESCRIPTION
    This script will delete all files with extension .gz and older than 6 months.
    
    Copy the script in C:\Scripts

.PARAMETER $Archives
    Adjust the UNC path accordingly. This will be the working directory.

.INPUTS
    None

.OUTPUTS
    C:\Scripts\Logs\CleanupLogArchives.log

.NOTES
    Version: 1.0.3
    Author: Roland van 't Kruijs
    Creation Date: 10/16/2019
    Purpose/Change: Added Thread ID and disk space info to the log functionality

.EXAMPLE
    Run this script by either:
    - Using an administrative account on the server
    - Or create an scheduled task (see below), using the Local System account

    $Trigger = New-ScheduledTaskTrigger -Daily -At 8am
    $User = "NT AUTHORITY\SYSTEM"
    $Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExcutionPolicy Bypass C:\Scripts\CleanupLogFiles.ps1'
    Register-ScheduledTask -TaskName 'Cleanup Log Files' -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force
#>

$Archives = "E:\LogArchive"
$Count = Get-ChildItem –Path E:\LogArchive\* -Include *.gz -Recurse | Where-Object {($_.CreationTime -lt (Get-Date).AddMonths(-6))}
$LogFilePath = "C:\Scripts\Logs\CleanupLogArchives.log"
[int]$ItemCount = $Count.count
$PSVer = $PSVersionTable.PSVersion
$build = $PSVersionTable.BuildVersion
$Processes = Get-Process | WHERE {($_.ProcessName -match 'powershell')} | Select -Property ID, Threads
$TID = ($Processes.Threads | Where-Object {$_.ThreadState -eq 'running'}).Id
$FreeSpace = [System.Math]::Round(((Get-PSDrive E).Free) / 1GB)
$TotalSpace = [System.Math]::Round((((Get-PSDrive E).Used) / 1GB) + (((Get-PSDrive E).Free) / 1GB))

function Write-Log {
    param (
        [Parameter(Mandatory=$False, Position=0)]
        [String]$Entry
    )

    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Entry" | Out-File -FilePath $LogFilePath -Append
}

cd $Archives

If ($ItemCount -eq 0){
    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - No files will be deleted, at this moment"
    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Current free space on drive E is: $Freespace GB out of $TotalSpace GB"
}
Else{
    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Current free space on drive E is: $Freespace GB out of $TotalSpace GB"
    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - $ItemCount files has been deleted."
    Get-ChildItem –Path E:\LogArchive\* -Include *.gz -Recurse | Where-Object {($_.CreationTime -lt (Get-Date).AddMonths(-6))} | Remove-Item
    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Available free space on drive E is now: $Freespace GB out of $TotalSpace GB"
}