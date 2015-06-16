tell application "Spotify"
	set cAlbum to album of current track
	set cArtist to artist of current track
	set cDiscNum to disc number of current track
	set cDuration to duration of current track
	set cTrackNum to track number of current track
	set cName to name of current track
	set cAlbumArtist to album artist of current track
end tell

tell application "Audio Hijack Pro"
	set theSession to the first session whose name is "Spotify"
	set album tag of theSession to cAlbum
	set album artist tag of theSession to cAlbumArtist
	set artist tag of theSession to cArtist
	set title tag of theSession to cName
	set track number tag of theSession to cTrackNum
	set disc number tag of theSession to cDiscNum
end tell
