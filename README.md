# Cgf.Livestream.Download

This is a powershell script that allows to archive all videos in an event published through livestream.com.

You have to provide it with the account and event ID and also the location where to find the ffmpeg executable (https://www.ffmpeg.org/).

It than crawls the event and downloads each video in it's highest quality. It uses the description as filename.