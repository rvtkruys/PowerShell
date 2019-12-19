# Get-RemoteRdpSession

> Adjusted by Roland van 't Kruijs (19/12/2019)

Adjust the filter, to include multiple servers, but include at all times the *VW* to focus on virtual machines. Perform the following steps to logoff all the disconnected sessions:

1. Run PowerShell ISE as Administrator
2. Open the Get-RemoteRdpSession script and perform **Run Script (F5)**
   - This action will prepare the environment for more detailed processing of disconnected sessions
3. Select line 19 and perform **Run Selection (F8)**
   - This will display all sessions related to the selection
	```
	Get-RemoteRdpSession  -ComputerName $(Get-AdComputer -filter {name -like "*VWWEB*"} | select-object -exp name)
	```
4. Adjust the filter value (line **28**), if needed, to include one or more servers
5. Select lines **28** to **35** and press **F8** to run the selection
	```
	$computerlist = Get-AdComputer -filter {name -like "*VWWEB*"} | select-object -exp name
	#Get a list of all RDP disconnected session 
	$RDPDiscSessions = Get-RemoteRdpSession  -ComputerName $computerlist -State Disc 
	#and then disconnect each of them one by one             
	foreach ($row in $RDPDiscSessions){
	Write-Progress -Activity "Logging Off all RDP Disc Sessions" -Status "Logging OFF $($row.Item("USERNAME")) from $($row.Item("COMPUTERNAME"))" 
	logoff $($row.Item("ID")) /server:$( $row.Item("COMPUTERNAME"))
	}
	```
6. Repeat the step **3** for the other servers, by adjusting the filter value
7. Repeat steps **4** and **5** to logoff sessions on other servers
