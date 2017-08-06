tell application "Audio Hijack Pro"
    try
        set theSession to the first session whose name is "Spotijack"
    on error
        set theSession to (make new application session at end of sessions)
        set name of theSession to "Spotijack"
        set targeted application of theSession to "/Applications/Spotify.app"
    end try

	set recording format of theSession to {encoding:AAC, bit rate:320, channels:Stereo, style:Normal, quality:10}
    set output name format of theSession to "%tag_track %tag_title"
end tell
