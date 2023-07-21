1. Get Account and event id's


2. Get general info:
https://api.new.livestream.com/accounts/8742906/events/3094105/

Extract feed count via {root.feed.total}

3. Get all feed info:
https://api.new.livestream.com/accounts/8742906/events/3094105/feed/?maxItems=459

Extract id feeds using {data[0].data.id}

4. Get single feed info:
https://api.new.livestream.com/accounts/8742906/events/3094105/videos/236887141

Convert using ffmpeg:
ffmpeg -i {root.m3u8_url} -map m:variant_bitrate:{root.asset.qualities[index with highest bitrate].bitrate} -c copy output.ts
