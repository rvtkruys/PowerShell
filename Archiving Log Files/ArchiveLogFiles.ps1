<#
.SYNOPSIS
    Compress single files in directory, based on age

.DESCRIPTION
    This script will compress every file within the designated directory and subfolders. After compression, the script will 
    remove the uncompressed version of the file only leaving the compressed archive with the same name. Due to security 
    policies, the server environment is not communicating with the Internet. In order for this script to run, certain 
    components must be downloaded and installed. This process will occur only once and with every future update. The proxy 
    will be configured, activated and when the process is finished, proxy settings are removed.
    
    Copy the script in C:\Scripts

.PARAMETER $Archives
    Adjust the UNC path accordingly. This will be the working directory.

.PARAMETER $Files
    -Include - focusses only on the extension you provide. For this process, we are looking for *.txt and *.log extensions
    -Exclude - to prevent duplicate actions, we are excluding already compressed files (*.gz, *.gzip, *.tar and *.zip)

.PARAMETER $Date
    At the moment, the script will compress all files older than 30 days. You can change this to meet the requirements of 
    the production. The value must start a minus sign (-), otherwise the script will look for files that are created in 
    the future.

.INPUTS
    None

.OUTPUTS
    On screen and in C:\Scripts\Logs\ArchiveLogFiles.log

.NOTES
    Version: 1.1.0
    Author: Roland van 't Kruijs
    Creation Date: 10/10/2019
    Purpose/Change: Added functionality to correct the Creation Time after compressing the file

.EXAMPLE
    Run this script by either:
    - Using an administrative account on the server
    - Or create an scheduled task (see below), using the Local System account

    $Trigger = New-ScheduledTaskTrigger -Daily -At 5am
    $User = "NT AUTHORITY\SYSTEM"
    $Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument 'C:\Scripts\ArchiveLogFiles.ps1'
    Register-ScheduledTask -TaskName 'Archive Log Files' -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force
#>

# .: INITIALIZATION :.

Set-ExecutionPolicy -ExecutionPolicy ByPass -Force

# .: ADJUSTABLE VARIABLE :.

$Archives = "E:\LogArchive"
$LogFilePath = "C:\Scripts\Logs\ArchiveLogFiles.log"
$Date = (Get-Date).AddDays(-5)

# .: VARIABLE :.

$ExitCode = 0
$Today = (Get-Date).Date
$DateFormat = "yyyyMMdd"
$FilePath = "C:\Scripts\Logs"
$PSVer = $PSVersionTable.PSVersion
$build = $PSVersionTable.BuildVersion
$Processes = Get-Process | WHERE {($_.ProcessName -match 'powershell')} | Select -Property ID, Threads
$TID = ($Processes.Threads | Where-Object {$_.ThreadState -eq 'running'}).Id
$CheckRepository = Get-PSRepository PSGallery | Select-Object InstallationPolicy
$CheckSource = Get-PackageSource NuGet | Select-Object IsTrusted
$CheckPacProNuGet = (Get-PackageProvider -Name NuGet).version
$modules = Get-Module -ListAvailable
$Count = Get-ChildItem $Archives -Recurse | Where-Object { $_.CreationTime -gt $Date }
$Files = Get-ChildItem $Archives -Include *.txt,*.log -Exclude *.gz,*.gzip,*.tar,*.zip -Recurse -Force | Where-Object {($_.LastWriteTime -lt $Date)}
$FileList = Get-ChildItem -Path $Archives -Filter '*.gz' -Recurse -File
[int]$ItemCount = $Count.count
$g = $modules | Group Name -NoElement | Where Count -gt 1 #group to identify modules with multiple versions installed
$gallery = $modules.where({$_.repositorysourcelocation})
$reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
$DefaultConnectionSettings = [byte[]](70,0,0,0,17,0,0,0,11,0,0,0,28,0,0,0,111,117,116,98,111,117,110,100,112,114,111,120,121,46,97,115,99,105,111,46,108,111,99,58,57,48,48,50,18,0,0,0,60,108,111,99,97,108,62,42,46,97,115,99,105,111,46,108,111,99,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
$IESettingsKey = 'Registry::HKEY_USERS\S-1-5-18\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
$IEConnectionsKey = Join-Path -Path $IESettingsKey -ChildPath 'Connections'

# .: FUNCTION :.

Function Write-Log {
    param (
        [Parameter(Mandatory=$False, Position=0)]
        [String]$Entry
    )

    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Entry" | Out-File -FilePath $LogFilePath -Append
}

Function UpdateInstalledModules {
[cmdletbinding(
    DefaultParameterSetName = 'Site'
)]
param(
    [Parameter(
        Mandatory = $True,
        ParameterSetName = '',
        ValueFromPipeline = $True)]
        [string]$Site,
    [Parameter(
        Mandatory = $True,
        ParameterSetName = '',
        ValueFromPipeline = $False)]
        [Int]$Wait
    )

    Clear-Host

    If (!(Test-Connection -computer $site -count 1 -quiet)) {
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Enabling Proxy settings for installations and/or updates of PowerShell modules"
        #Set-ItemProperty -Path $reg -Name ProxyServer -Value "outboundproxy.ascio.loc:9002"
        #Set-ItemProperty -path $reg -Name ProxyOverride -Value "<local>*.ascio.loc"
        
        If (-not(Test-Path -Path $IEConnectionsKey)) {
            New-Item -Path $IESettingsKey -Name 'Connections'
        }

        Try {
            $Null = Get-ItemPropertyValue -Path $IEConnectionsKey -Name 'DefaultConnectionSettings'
            Set-ItemProperty -Path $IEConnectionsKey -Name 'DefaultConnectionSettings' -Value $DefaultConnectionSettings
        }
        Catch {
            New-ItemProperty -Path $IEConnectionsKey -Name 'DefaultConnectionSettings' -Value $DefaultConnectionSettings -PropertyType Binary
        }
        
        Set-ItemProperty -Path $reg -Name ProxyEnable -Value 1
        New-Item -Path 'C:\Scripts\check.txt' -ItemType File
        $IE = Start-Process -File iexplore -Arg 'http://www.google.com' -PassThru
    }
    Else {
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Internet connection is available"
    }
    
    If ($CheckRepository.InstallationPolicy -match 'Untrusted'){
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Write-Warning "Restart PowerShell console to confirm changes..."
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Restart PowerShell console to confirm changes"
    }
    ElseIf (!(Get-PSRepository PSGallery)) {
        Register-PSRepository -Name "PSGallery" –SourceLocation "https://www.powershellgallery.com/api/v2/" -InstallationPolicy Trusted
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Registered Repository PowerShell Gallery as a trusted source"
    }
    Else {
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Repository PowerShell Gallery is already a trusted source"
    }

    If ($CheckSource.IsTrusted -match 'False'){
        Set-PackageSource -Name NuGet -InstallationPolicy Trusted
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Configuring Package Source NuGet as a trusted source"
    }
    ElseIf (!(Get-PackageSource NuGet)) {
        Register-PackageSource -Name Nuget -Location "http://www.nuget.org/api/v2" –ProviderName Nuget -Trusted
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Installing and configuring Package Source NuGet as a trusted source"
    }
    Else {
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Package Source NuGet is already a trusted source"
    }

    If ((Get-PackageProvider -Name NuGet).version -lt 2.8.5.208) {
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Checking and updating NuGet version"
        Install-PackageProvider -Name NuGet -Force
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Completed NuGet update"
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Closing PowerShell session to finalize update to latest NuGet version"
        [System.Windows.MessageBox]::Show('Restart this script to finalize the installation...','Installing NuGet','OK','Information')
        Exit
    }
    ElseIf (!(Get-PackageProvider -Name NuGet)) {
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Downloading and installing latest NuGet version"
        Install-PackageProvider -Name NuGet -Force
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Completed NuGet installation"
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Closing PowerShell session to finalize update to latest NuGet version"
        [System.Windows.MessageBox]::Show('Restart this script to finalize the installation...','Installing NuGet','OK','Information')
        Exit
    }
    Else {
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Most current version of NuGet is already installed: $CheckPacProNuGet"
    }

    If (!(Get-Module -ListAvailable -Name PowerShellGet)) {
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Module 'PowerShellGet' does not exist"
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Installing module 'PowerShellGet' now"
        Install-Module -Name PowerShellGet -Force
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Module 'PowerShellGet' is now available"
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Closing PowerShell session to finalize update to latest PowerShellGet version"
        [System.Windows.MessageBox]::Show('Restart this script to finalize the installation...','Installing PowerShellGet','OK','Information')
        Exit
    }

    If (!(Get-InstalledModule PS7Zip)) {
        Write-Log -Entry "PID=$PID - Installing the latest PS7Zip version and relevant dependencies"
        Install-Module PS7Zip -Force
        Write-Log -Entry "PID=$PID - PS7Zip Installation finished"
    }
<# Most likely overkill, since this process is repeated differnetly in line 181 to 198
    Else {
        $ErrorActionPreference="SilentlyContinue"
        Stop-Transcript | out-null
        $ErrorActionPreference = "Continue"
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - PS7Zip is already installed"
        Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Checking for updates and, if available, installing the latest version of PS7Zip"
        Start-Transcript -Path $LogFilePath -Append
        Get-InstalledModule PS7Zip | Update-Module -Verbose
        Stop-Transcript
    }
#>

    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Getting currently installed modules"
    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Filter to modules from the PowerShell Gallery"
    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Comparing to online versions"

    ForEach ($module in $gallery) {
        Try {
            $online = Find-Module -Name $module.name -Repository PSGallery -ErrorAction Stop
        }
        Catch {
            Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Module $($module.name) was not found in the PowerShell Gallery"
        }

        If ($online.version -gt $module.version) {
            $UpdateAvailable = $True
            Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Updating module $module to the latest version"
            Update-Module $module
        }
        Else {
            $UpdateAvailable = $False
            Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Module $module is on the latest version"
        }
    }

    If (Test-Path 'C:\Scripts\check.txt') {
        Write-Host "Disabling Proxy Server" -ForegroundColor Yellow
        #Remove-ItemProperty -Path $reg -Name ProxyServer
        #Remove-ItemProperty -Path $reg -Name ProxyOverride
        Set-ItemProperty -Path $reg -Name ProxyEnable -Value 0
        $IE.Kill()
        Remove-Item 'C:\Scripts\check.txt'
    }
}

# .: EXECUTION: CHECK POWERSHELL PLATFORM :.

Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - [START] Starting process"

Clear-Host

If (!(Test-Path $FilePath)) { 
    New-Item -Path $FilePath -ItemType Directory | Out-Null
    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Checking for directory $FilePath"
    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Directory $FilePath does not exist"
    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Created directory: $FilePath"
}
Else {
    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Checking for directory $FilePath"
    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Directory $FilePath exists"
}

Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Changing Execution Policies to ByPass"
Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Found and Initialized the PowerShell Logger"
Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - PowerShell process running on OS version: $build"
Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - PowerShell version: $PSVer"
Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Initialized PowerShell logging at $LogFilePath"

If (!(Test-Path $Archives)) { 
    New-Item -Path $Archives -ItemType Directory | Out-Null
    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Checking for directory $Archives"
    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Directory $FilePath does not exist"
    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Created directory: $Archives"
}
Else {
    Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Directory $Archives already exists"
}

UpdateInstalledModules -Site google.com -Wait 10

Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - PowerShell Platform check completed"

# .: EXECUTION: PROCESS :.

Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Starting file compressing and cleanup"

cd $Archives

$Count

ForEach ($File in $Files) {
    Compress-7Zip -FullName "$File" -ArchiveType GZIP -OutputFile "$File.gz" -Remove
}

Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - $ItemCount files are compressed up until the last modification on: $Date and removed"
Write-Host "$ItemCount files are compressed up until the last modification on:" $Date "and removed. For more details check $LogFilePath" -ForegroundColor Green
Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - $ItemCount uncompressed version of the files are removed, only leaving the compressed archives"
Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Starting with adjusting the Creation Date, Last Write Date and Last Access Date"

ForEach ($FL_Item in $FileList) {
    $Null = $FL_Item.BaseName -match '(?<DateString>\d{4}\d{2}\d{2})'
    $DateString = $Matches.DateString
    $date_from_file = [datetime]::ParseExact($DateString, $DateFormat, $Null)

    $FL_Item.CreationTime = $date_from_file
}

Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - Finished adjusting the Creation Date, Last Write Date and Last Access Date"
Write-Log -Entry "PID=$PID TID=$TID $env:COMPUTERNAME - [END] Process finished"