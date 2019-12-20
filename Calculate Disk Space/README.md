# DiskSpaceHTML

> Adjusted by Roland van 't Kruijs (20/12/2019)

This script will analyze the current disk space on selected servers, mentioned in the SERVER.CSV file and displays the result in the PowerShell command prompt and in a Internet browser.

Save both files in C:\Scripts

1. Open Server.csv and add the servers to the list
   - Leave the first line, as this is used as an header
   - Adjusted the values accordingly, which are read as percentages
2. Run PowerShell ISE as Administrator
3. Open the DiskSpaceHTML script and change the location in line **30**
4. Run the script, by performing **Run Script (F5)**
5. The result will be displayed in the command window and in Internet Explorer
   - The webpage is stored in the designated folder
