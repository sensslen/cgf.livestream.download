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
    Write-Error "Could not find output folder ${output_folder_full}"
    exit
}

$ffmpeg_location_full = [IO.Path]::GetFullPath($ffmpeg_location)
if (!(Test-Path -Path $ffmpeg_location_full  -PathType Leaf)) {
    Write-Error "Could not find ffmpeg at ${ffmpeg_location_full}"
    exit
}

function Get-ChunkVideoInfo {
    param(
        [string]$chunkUrl
    )

    Write-Host "Downloading Event feed chunk using url:$feedChunkUrl"
    $feedChunkResponse = Invoke-WebRequest $feedChunkUrl
    if ($feedChunkResponse.StatusCode -ne [system.net.httpstatuscode]::ok) {
        Write-Error "Failed to download feed information"
        Write-Error $feedChunkResponse
        exit
    }    
    $feedChunk = $feedChunkResponse.Content | ConvertFrom-Json

    return $feedChunk.data
}

$chunkSize = 10
$feedChunkUrl = "https://api.new.livestream.com/accounts/${account_id}/events/${event_id}/feed/?maxItems=${chunkSize}"

$videos = Get-ChunkVideoInfo($feedChunkUrl)

while ($videos.Count -gt 0) {
    foreach ($video in $videos) {
        $video_id = $video.data.id
        $videoInfoUrl = "https://api.new.livestream.com/accounts/${account_id}/events/${event_id}/videos/${video_id}"

        Write-Host ""
        Write-Host ""
        Write-Host "Starting download of Video using:$videoInfoUrl"

        $videoName = $video.data.caption
        $videoCreationDate = [DateTime]::Parse($video.data.created_at)
        $videoPulishDate = [DateTime]::Parse($video.data.publish_at)
        $datePrefix = $videoPulishDate.ToString("yyyy-MM-dd-")
        $videoNameWithoutInvalidCharacters = $videoName.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $fileName = "${datePrefix}${videoNameWithoutInvalidCharacters}.m4v"
        $filePath = [IO.Path]::Combine($output_folder_full, $fileName)

        Write-Host "Downloading video to ""${filePath}"""

        if (Test-Path -Path $filePath -PathType Any) {
            Write-Host "Skipping the download. The File ""${filePath}"" already exists"
        }
        else {
            $videoInfoResponse = Invoke-WebRequest $videoInfoUrl

            if ($videoInfoResponse.StatusCode -ne [system.net.httpstatuscode]::ok) {
                Write-Error "Failed to get video information via: ${videoInfoUrl}"
                Write-Error $videoInfoResponse
                exit
            }

            $videoInfo = $videoInfoResponse.Content | ConvertFrom-Json

            $maximumVideoBitrate = ($videoInfo.asset.qualities | ForEach-Object { $_.bitrate } | Measure-Object -Maximum).Maximum

            $downloadUrl = $videoInfo.m3u8_url
            $ffmpegCommand = """${ffmpeg_location_full}"" -i ""${downloadUrl}"" -metadata title=""${videoName}"" -map m:variant_bitrate:${maximumVideoBitrate} -c copy ""${filePath}"""
            Write-Host "Executing $ffmpegCommand"

            & $ffmpeg_location_full -i """${downloadUrl}""" -metadata "title=""${videoName}""" -map "m:variant_bitrate:${maximumVideoBitrate}" -bsf:a "aac_adtstoasc" -c "copy" """${filePath}"""

            Write-Host "Setting creation time of file:${filePath} to:${videoCreationDate}"
            $(Get-Item $filePath).CreationTime = $videoCreationDate
            Write-Host "Setting las write time of file:${filePath} to:${videoPulishDate}"
            $(Get-Item $filePath).LastWriteTime = $videoPulishDate
        }
    }

    $lastVideoId = $videos[-1].data.id
    $feedChunkUrl = "https://api.new.livestream.com/accounts/${account_id}/events/${event_id}/feed/?id=${lastVideoId}&type=video&newer=-1&older=${chunkSize}"
    $videos = Get-ChunkVideoInfo($feedChunkUrl)
}
