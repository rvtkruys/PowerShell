<#
.SYNOPSIS
  Creating Reserved Namespace for NicGatewayV2

.DESCRIPTION
  Namespace reservation assigns the rights for a portion of the HTTP URL namespace to the designated gMSA (group Managed
  Service Account). A reservation gives gMSA the right to create services that listen on that portion of the namespace.

.INPUTS
  None

.OUTPUTS
  Log file stored in C:\Scripts\Logs\Tucows_IT.log>

.NOTES
  Version:        1.1.0
  Author:         Roland van 't Kruijs
  Creation Date:  10/22/2019
  Purpose/Change: Changed endpoints to wildcard purposes
  
.EXAMPLE
  Create an Scheduled Task or incorporate the script as an task in the deployment environment
#>

# .: INITIALIZATION :.

# .: DECLARATION :.

$FilePath = "C:\Scripts\Logs"
$LogFilePath = "C:\Scripts\Logs\Tucows_IT.log"
$user_prod = "ascio\prod-gMSA$"
$user_qa = "ascio\qa-gMSA$"
$user_stg = "ascio\STG-gMSA$"
$srv = $env:computername
$endpoints = @(
"http://+:8088/configurations/",
"http://+:8088/configurations/start/",
"http://+:8088/configurations/stop/",
"http://+:8088/configurations/refresh/",
"http://+:8088/configurations/accept/",
"http://+:8088/certificates/",
"http://+:8088/healthcheck/",
"http://+:8088/scan/",
"http://+:8088/"
)

# .: FUNCTION :.

function Write-Log {
    param (
        [Parameter(Mandatory=$False, Position=0)]
        [String]$Entry
    )

    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Entry" | Out-File -FilePath $LogFilePath -Append
}

# .: EXECUTION :.

<# commands for testing script functionality - manual action
netsh http delete urlacl url=http://nicgatewayv2.ascio.loc:8088/configurations
netsh http delete urlacl url=http://nicgatewayv2.ascio.loc:8088/configurations/start
netsh http delete urlacl url=http://nicgatewayv2.ascio.loc:8088/configurations/stop
netsh http delete urlacl url=http://nicgatewayv2.ascio.loc:8088/configurations/refresh
netsh http delete urlacl url=http://nicgatewayv2.ascio.loc:8088/certificates
netsh http delete urlacl url=http://nicgatewayv2.ascio.loc:8088/healthcheck
netsh http delete urlacl url=http://nicgatewayv2.ascio.loc:8088/scan
netsh http delete urlacl url=http://+:8088/configurations
netsh http delete urlacl url=http://+:8088/configurations/start
netsh http delete urlacl url=http://+:8088/configurations/stop
netsh http delete urlacl url=http://+:8088/configurations/refresh
netsh http delete urlacl url=http://+:8088/certificates
netsh http delete urlacl url=http://+:8088/healthcheck
netsh http delete urlacl url=http://+:8088/scan
#>

Clear-Host

If (!(Test-Path $FilePath)) { 
    New-Item -Path $FilePath -ItemType Directory | Out-Null
}

If ((Test-Path "HKLM:\SYSTEM\ControlSet001\Services\HTTP\Parameters\UrlAclInfo")) {
    Write-Log -Entry "PID=$PID - Registry Key 'UrlAclInfo' exist"
    Write-Log -Entry "PID=$PID - Checking for Reserved Namespaces on the system"
    ForEach($endpoint in $endpoints){
        $key = Get-Item "HKLM:\SYSTEM\ControlSet001\Services\HTTP\Parameters\UrlAclInfo"

        If(!($key.GetValue($endpoint))){
            If($srv -match "^FRA0"){
                netsh http add urlacl url=$endpoint user=$user_prod listen=yes
                Write-Log -Entry "PID=$PID - Added Registry Value: $endpoint"
            }
            ElseIf($srv -match "^FRA2"){
                netsh http add urlacl url=$endpoint user=$user_stg listen=yes
                Write-Log -Entry "PID=$PID - Added Registry Value: $endpoint"
            }
            ElseIf($srv -match "^FRA3"){
                netsh http add urlacl url=$endpoint user=$user_qa listen=yes
                Write-Log -Entry "PID=$PID - Added Registry Value: $endpoint"
            }
            Else{
                Write-Log -Entry "PID=$PID - Reserved Namespaces are not applicable for this system"                
                Write-Log -Entry "PID=$PID - No changes made to this system"
            }
        }
        Else{
            Write-Log -Entry "PID=$PID - Registry Value $endpoint exist already"
        }
    }
}
Else {
    Write-Log -Entry "PID=$PID - Registry Key 'UrlAclInfo' does not exist..."
}