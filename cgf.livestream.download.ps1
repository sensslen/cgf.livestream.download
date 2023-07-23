param(
    [parameter(mandatory = $true)]
    [string] $account_id,
    [parameter(mandatory = $true)]
    [string] $event_id,
    [parameter(mandatory = $true)]
    [string] $output_folder,
    [parameter(mandatory = $true)]
    [string] $ffmpeg_location
)

$output_folder_full = [IO.Path]::GetFullPath($output_folder)
if (!(Test-Path -Path $output_folder_full -PathType Container)) {
    Write-Error "Could not find output folder $output_folder_full"
    exit
}

$ffmpeg_location_full = [IO.Path]::GetFullPath($ffmpeg_location)
if (!(Test-Path -Path $ffmpeg_location_full  -PathType Leaf)) {
    Write-Error "Could not find ffmpeg at $ffmpeg_location_full"
    exit
}

$eventInfoUrl = "https://api.new.livestream.com/accounts/$account_id/events/$event_id/"
Write-Output "Downloading Event Information using url:$eventInfoUrl"

$eventInfoResponse = Invoke-WebRequest $eventInfoUrl

if ($eventInfoResponse.StatusCode -ne [system.net.httpstatuscode]::ok) {
    Write-Error "Failed to gather event information"
    Write-Error $eventInfoResponse
    exit
}

$eventInfo = $eventInfoResponse.Content | ConvertFrom-Json

$numberOfFilesInFeed = $eventInfo.feed.total

$completeFeedUrl = "https://api.new.livestream.com/accounts/$account_id/events/$event_id/feed/?maxItems=$numberOfFilesInFeed"
Write-Output "Downloading Event feed using url:$completeFeedUrl"

$completeFeedResponse = Invoke-WebRequest $completeFeedUrl

if ($completeFeedResponse.StatusCode -ne [system.net.httpstatuscode]::ok) {
    Write-Error "Failed to download feed information"
    Write-Error $completeFeedResponse
    exit
}

$completeFeed = $completeFeedResponse.Content | ConvertFrom-Json

$videos = $completeFeed.data

Write-Host "Downloading all $numberOfFilesInFeed videos from event with id:$event_id"

foreach ($video in $videos) {
    $videoName = $video.data.caption
    $videoCreationDate = [Datetime]::Parse($video.data.created_at)
    $videoUploadDate = [Datetime]::Parse($video.data.streamed_at)
    $datePrefix = $videoUploadDate.ToString("yyyy-MM-dd-")
    $videoNameWithoutInvalidCharacters = $videoName.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
    $fileName = "$datePrefix$videoNameWithoutInvalidCharacters.m4v"
    $filePath = [IO.Path]::Combine($output_folder_full, $fileName)

    Write-Host "Downloading video to $filePath"

    if (Test-Path -Path $filePath -PathType Any) {
        Write-Output "Skipping the download of $filePath, as the file already exists"
    }
    else {
        $video_id = $video.data.id
        $videoInfoUrl = "https://api.new.livestream.com/accounts/$account_id/events/$event_id/videos/$video_id"
        Write-Output "Downloading Video information using:$videoInfoUrl"

        $videoInfoResponse = Invoke-WebRequest $videoInfoUrl

        if ($videoInfoResponse.StatusCode -ne [system.net.httpstatuscode]::ok) {
            Write-Error "Failed to get video information via: $videoInfoUrl"
            Write-Error $videoInfoResponse
            exit
        }

        $videoInfo = $videoInfoResponse.Content | ConvertFrom-Json

        $maximumVideoBitrate = ($videoInfo.asset.qualities | ForEach-Object { $_.bitrate } | Measure-Object -Maximum).Maximum

        $downloadUrl = $videoInfo.m3u8_url
        $ffmpegCommand = """$ffmpeg_location_full"" -i ""$downloadUrl"" -metadata title=""$videoName"" -map m:variant_bitrate:$maximumVideoBitrate -c copy ""$filePath"""
        Write-Output "Executing $ffmpegCommand"

        & $ffmpeg_location_full -i """$downloadUrl""" -metadata "title=""$videoName""" -map "m:variant_bitrate:$maximumVideoBitrate" -bsf:a "aac_adtstoasc" -c "copy" """$filePath"""

        Write-Output "Setting creation time of file:$filePath to:$videoCreationDate"
        $(Get-Item $filePath).CreationTime = $videoCreationDate
        $(Get-Item $filePath).LastWriteTime = $videoUploadDate
    }
}
