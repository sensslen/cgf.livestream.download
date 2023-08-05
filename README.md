# Cgf.Livestream.Download

This is a powershell script that allows to archive all videos in an event published through livestream.com.

You have to provide it with the account and event ID and also the location where to find the ffmpeg executable (https://www.ffmpeg.org/).

It then crawls the event and downloads each video in it's highest quality. It uses the description as filename.

## Get Account and event ID
1. Locate the event you want to download on the livestream website <br>
   ![Locate Event](/assets/locateEvent.png)
2. Open the event and select share <br>
   ![Open Event](/assets/selectEvent.png)
3. Get the embed link for the event <br>
   ![Get Embed Link](/assets/getEmbedLink.png)
4. Extract account and event ID's from the url <br>
   ![Extract Account and Event ID's](/assets/extractIds.png)

## Start Cgf.Livestream.Download
1. Download the Powershell Script and store it in a local folder.
2. Download and store the ffmpeg.exe file in the same folder.
3. Ensure you have set in PowerShell your Executionpolicy to "unrestricted" or "Remote Signed" (Use PowerShell Command "set-executionpolicy -RemoteSign")
   More information about the execution policy can be found here: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-5.1
4. Ensure you use PowerShell version 5.1 as this tool is not tested on other PowerShell versions.
5. start a powershell console and change the path to your local folder where you have stored the script (use the command "cd" followed by the path, for example: "cd C:\mypath")
6. Run the command to start the tool: .\scriptname.ps1 -account_id 1234567 -event_id 987654 -ffmpeg_location C:\yourlocation\ffmpeg.exe -output_folder D:\youroutputfolder
7. the parameter "account_id" and "event_id" are mandatory. Rest of the parameter are optional but recommended. 
