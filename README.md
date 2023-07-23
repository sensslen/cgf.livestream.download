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
   ![Extract Account and Event ID's](/assets/extractAccountAndEventId_.png)
