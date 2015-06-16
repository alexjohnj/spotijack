tell application "Audio Hijack Pro"
	set theSession to the first session whose name is "Spotijack"
	set recording format of theSession to {encoding:AAC, bit rate:320, channels:Stereo, style:Normal, quality:10}
end tell
