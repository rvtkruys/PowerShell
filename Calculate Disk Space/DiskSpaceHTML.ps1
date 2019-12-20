<#
.SYNOPSIS
    Generates HTMl Disk Space Report

.DESCRIPTION
    This script will analyze the current disk space on all servers, mentioned in the SERVER.CSV file and displays the result
	in the PowerShell command prompt and in a Internet browser.
    
    Copy the script in C:\Scripts

.INPUTS
    C:\Scripts\Servers.csv

.OUTPUTS
    On screens and E:\LogArchive\FreeSpace-<Current Date>.htm

.NOTES
    Version: 1.0.2
    Author: Roland van 't Kruijs
    Creation Date: 10/18/2019
    Purpose/Change: Initial development

.EXAMPLE
    Run this script by either:
    - Using an administrative account on the server
#>

Clear-Host
 
$freeSpaceFileName = "E:\LogArchive\FreeSpace-$(get-date -f yyyyMMdd).htm" 
 
New-Item -ItemType file $freeSpaceFileName -Force 
# Getting the freespace info using WMI 
#Get-WmiObject win32_logicaldisk  | Where-Object {$_.drivetype -eq 3 -OR $_.drivetype -eq 2 } | format-table DeviceID, VolumeName,status,Size,FreeSpace | Out-File FreeSpace.txt 
# Function to write the HTML Header to the file 
Function writeHtmlHeader 
{ 
param($fileName) 
$date = ( get-date ).ToString('MM/dd/yyyy') 
Add-Content $fileName "<html>" 
Add-Content $fileName "<head>" 
Add-Content $fileName "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>" 
Add-Content $fileName '<title>DiskSpace Report</title>' 
add-content $fileName '<STYLE TYPE="text/css">' 
add-content $fileName  "<!--" 
add-content $fileName  "td {" 
add-content $fileName  "font-family: Verdana;" 
add-content $fileName  "font-size: 11px;" 
add-content $fileName  "border-top: 1px solid #999999;" 
add-content $fileName  "border-right: 1px solid #999999;" 
add-content $fileName  "border-bottom: 1px solid #999999;" 
add-content $fileName  "border-left: 1px solid #999999;" 
add-content $fileName  "padding-top: 0px;" 
add-content $fileName  "padding-right: 0px;" 
add-content $fileName  "padding-bottom: 0px;" 
add-content $fileName  "padding-left: 0px;" 
add-content $fileName  "}" 
add-content $fileName  "body {" 
add-content $fileName  "margin-left: 5px;" 
add-content $fileName  "margin-top: 5px;" 
add-content $fileName  "margin-right: 0px;" 
add-content $fileName  "margin-bottom: 10px;" 
add-content $fileName  "" 
add-content $fileName  "-->" 
add-content $fileName  "</style>" 
Add-Content $fileName "</head>" 
Add-Content $fileName "<body>" 
add-content $fileName  "<table width='100%'>" 
add-content $fileName  "<tr bgcolor='#0066ff'>" 
add-content $fileName  "<td colspan='9' height='25'  width=5% align='left'>" 
add-content $fileName  "<font face='Verdana' color='#ffffff' size='5'><center><strong>DiskSpace Report - $date</strong></center></font>" 
add-content $fileName  "</td>" 
add-content $fileName  "</tr>" 
 
} 
 
# Function to write the HTML Header to the file 
Function writeTableHeader 
{ 
param($fileName) 
Add-Content $fileName "<tr bgcolor=#0066ff>" 
Add-Content $fileName "<td><b><font face='Verdana' color='#ffffff'>Server</font></b></td>" 
Add-Content $fileName "<td><b><font face='Verdana' color='#ffffff'>Drive</font></b></td>" 
Add-Content $fileName "<td><b><font face='Verdana' color='#ffffff'>Drive Label</font></b></td>" 
Add-Content $fileName "<td><b><font face='Verdana' color='#ffffff'>Total Capacity(GB)</font></b></td>" 
Add-Content $fileName "<td><b><font face='Verdana' color='#ffffff'>Used Capacity(GB)</font></b></td>" 
Add-Content $fileName "<td><b><font face='Verdana' color='#ffffff'>Free Space(GB)</font></b></td>" 
Add-Content $fileName "<td><b><font face='Verdana' color='#ffffff'>FreeSpace % </font></b></td>" 
Add-Content $fileName "<td><b><font face='Verdana' color='#ffffff'>Status </font></b></td>" 
Add-Content $fileName "</tr>" 
} 
 
Function writeHtmlFooter 
{ 
param($fileName) 
 
Add-Content $fileName "</body>" 
Add-Content $fileName "</html>" 
} 
 
Function writeDiskInfo 
{ 
param($fileName,$server,$DeviceID,$VolumeName,$TotalSizeGB,$UsedSpaceGB,$FreeSpaceGB,$FreePer,$status) 
if ($status -eq 'warning') 
{ 
Add-Content $fileName "<tr>" 
Add-Content $fileName "<td >$server</td>" 
Add-Content $fileName "<td >$DeviceID</td>" 
Add-Content $fileName "<td >$VolumeName</td>" 
Add-Content $fileName "<td >$TotalSizeGB</td>" 
Add-Content $fileName "<td >$UsedSpaceGB</td>" 
Add-Content $fileName "<td >$FreeSpaceGB</td>" 
Add-Content $fileName "<td  bgcolor='#ffcc00' >$FreePer</td>" 
Add-Content $fileName "<td >$status</td>" 
Add-Content $fileName "</tr>" 
} 
elseif ($status -eq 'critical') 
{ 
Add-Content $fileName "<tr>" 
Add-Content $fileName "<td >$server</td>" 
Add-Content $fileName "<td >$DeviceID</td>" 
Add-Content $fileName "<td >$VolumeName</td>" 
Add-Content $fileName "<td >$TotalSizeGB</td>" 
Add-Content $fileName "<td >$UsedSpaceGB</td>" 
Add-Content $fileName "<td >$FreeSpaceGB</td>" 
Add-Content $fileName "<td bgcolor='#FF0000' >$FreePer</td>" 
Add-Content $fileName "<td >$status</td>" 
Add-Content $fileName "</tr>" 
 
} 
elseif ($status -eq 'low') 
{ 
Add-Content $fileName "<tr>" 
Add-Content $fileName "<td >$server</td>" 
Add-Content $fileName "<td >$DeviceID</td>" 
Add-Content $fileName "<td >$VolumeName</td>" 
Add-Content $fileName "<td >$TotalSizeGB</td>" 
Add-Content $fileName "<td >$UsedSpaceGB</td>" 
Add-Content $fileName "<td >$FreeSpaceGB</td>" 
Add-Content $fileName "<td bgcolor='#ffff00' >$FreePer</td>" 
Add-Content $fileName "<td >$status</td>" 
Add-Content $fileName "</tr>" 
} 
elseif ($status -eq 'good') 
{ 
Add-Content $fileName "<tr>" 
Add-Content $fileName "<td >$server</td>" 
Add-Content $fileName "<td >$DeviceID</td>" 
Add-Content $fileName "<td >$VolumeName</td>" 
Add-Content $fileName "<td >$TotalSizeGB</td>" 
Add-Content $fileName "<td >$UsedSpaceGB</td>" 
Add-Content $fileName "<td >$FreeSpaceGB</td>" 
Add-Content $fileName "<td bgcolor='#33cc33' >$FreePer</td>" 
Add-Content $fileName "<td >$status</td>" 
Add-Content $fileName "</tr>" 
} 
} 
 
writeHtmlHeader $freeSpaceFileName 
 
writeTableHeader $freeSpaceFileName 
Import-Csv C:\Scripts\Servers.csv|%{  
$cserver = $_.Server  
$cdrivelt = $_.Drive  
$clowth = $_.LowTh  
$cwarnth = $_.WarnTh  
$ccritth = $_.CritTh  
$status='' 
if(Test-Connection -ComputerName $cserver -Count 1 -ea 0) { 
$diskinfo= Get-WmiObject -Class Win32_LogicalDisk -ComputerName $cserver  -Filter "DeviceID='$cdrivelt'"  
ForEach ($disk in $diskinfo)  
{  
If ($diskinfo.Size -gt 0) {$percentFree = [Math]::round((($diskinfo.freespace/$diskinfo.size) * 100))}  
Else {$percentFree = 0}  
#Process each disk in the collection and write to spreadsheet  
    $server=$disk.__Server 
     $deviceID=$disk.DeviceID  
     $Volume=$disk.VolumeName  
     $TotalSizeGB=[math]::Round(($disk.Size /1GB),2)  
     $UsedSpaceGB=[math]::Round((($disk.Size - $disk.FreeSpace)/1GB),2)  
     $FreeSpaceGB=[math]::Round(($disk.FreeSpace / 1GB),2)  
     $FreePer=("{0:P}" -f ($disk.FreeSpace / $disk.Size))  
        
    #Determine if disk needs to be flagged for warning or critical alert  
    If ($percentFree -le  $ccritth) {  
        $status = "Critical"  
             } ElseIf ($percentFree -gt $ccritth -AND $percentFree -le $cwarnth) {  
        $status = "Warning"  
              }  
     ElseIf ($percentFree -ge $cwarnth -AND $percentFree -lt $clowth) {  
        $status = "Low"  
                       
    } Else {  
        $status = "Good"  
           }  
  } 
write-host  $server $DeviceID  $Volume $TotalSizeGB  $UsedSpaceGB $FreeSpaceGB $FreePer $status 
writeDiskInfo $freeSpaceFileName $server $DeviceID  $Volume $TotalSizeGB  $UsedSpaceGB $FreeSpaceGB $FreePer $status 
} 
} 
Add-Content $freeSpaceFileName "</table>"  
writeHtmlFooter $freeSpaceFileName 

Invoke-Expression $freeSpaceFileName