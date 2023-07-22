param(
    [parameter(mandatory = $true)]
    [string] $account_id,
    [parameter(mandatory = $true)]
    [string] $event_id,
    [parameter(mandatory = $false)]
    [string] $output_folder = '.',
    [parameter(mandatory = $false)]
    [string] $ffmpeg_location = './ffmpeg.exe'
)

$output_folder_full = [IO.Path]::GetFullPath($output_folder)
if (!(Test-Path -Path $output_folder_full -PathType Container)) {
    throw "Coult not find folder $output_folder_full"
}

$ffmpeg_location_full = [IO.Path]::GetFullPath($ffmpeg_location)
if (!(Test-Path -Path $ffmpeg_location_full  -PathType Leaf)) {
    throw "Coult not find ffmpeg at $ffmpeg_location_full"
}

$eventInfoUrl = "https://api.new.livestream.com/accounts/$account_id/events/$event_id/"
Write-Output "Downloading Event Information using url:$eventInfoUrl"

$eventInfoResponse = Invoke-WebRequest $eventInfoUrl

if ($eventInfoResponse.StatusCode -ne [system.net.httpstatuscode]::ok) {
    Write-Output "Failed to gather event information"
    throw $eventInfoResponse
}

$eventInfo = $eventInfoResponse.Content | ConvertFrom-Json

$numberOfFilesInFeed = $eventInfo.feed.total

$completeFeedUrl = "https://api.new.livestream.com/accounts/$account_id/events/$event_id/feed/?maxItems=$numberOfFilesInFeed"
Write-Output "Downloading Event feed using url:$completeFeedUrl"

$completeFeedResponse = Invoke-WebRequest $completeFeedUrl

if ($completeFeedResponse.StatusCode -ne [system.net.httpstatuscode]::ok) {
    Write-Output "Failed to download feed information"
    throw $completeFeedResponse
}

$completeFeed = $completeFeedResponse.Content | ConvertFrom-Json

$videos = $completeFeed.data

foreach ($video in $videos) {
    $videoName = $video.data.caption
    $fileName = "$videoName.ts"
    $filePath = [IO.Path]::Combine($output_folder_full, $fileName)

    Write-Host "Downloading video to $filePath"

    if (Test-Path -Path $filePath -PathType Any) {
        Write-Output "Skipping the donload of $filePath, as the file already exists"
    }
    else {
        $videoCreationDate = $video.data.created_at
        $videoUploadDate = $video.data.streamed_at

        $video_id = $video.data.id
        $videoInfoUrl = "https://api.new.livestream.com/accounts/$account_id/events/$event_id/videos/$video_id"
        Write-Output "Downloading Video information using:$videoInfoUrl"

        $videoInfoResponse = Invoke-WebRequest $videoInfoUrl

        if ($videoInfoResponse.StatusCode -ne [system.net.httpstatuscode]::ok) {
            Write-Output "Failed to get video information via: $videoInfoUrl"
            throw $videoInfoResponse
        }

        $videoInfo = $videoInfoResponse.Content | ConvertFrom-Json

        $maximumVideoBitrate = ($videoInfo.asset.qualities | ForEach-Object { $_.bitrate } | Measure-Object -Maximum).Maximum

        $downloadUrl = $videoInfo.m3u8_url
        $ffmpegCommand = """$ffmpeg_location_full"" -i ""$downloadUrl"" -map m:variant_bitrate:$maximumVideoBitrate -c copy ""$filePath"""
        Write-Output "Executing $ffmpegCommand"

        & $ffmpeg_location_full -i """$downloadUrl""" -map "m:variant_bitrate:$maximumVideoBitrate" -c "copy" """$filePath"""

        Write-Output "Setting creation time of file:$filePath to:$videoCreationDate"
        $(Get-Item $filePath).CreationTime = [Datetime]::Parse($videoCreationDate)
        $(Get-Item $filePath).ModifiedAt = [Datetime]::Parse($videoUploadDate)
    }
}