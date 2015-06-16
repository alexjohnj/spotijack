-- Version 0.2
-- New In 0.2:
-- Spotijack will atempt to fill in song information in Audio Hijack
-- Can fill:
--	Album Name
--	Album Artist Name
--	Track Name
--	Arist Name
--	Track Number
--	Disc Number
-- Spotijack will automatically move the seek to 0:00 in Spotify on the first song

set delay_time to 0.1

set myspace to " "
set myspace2 to myspace & myspace
set myspace3 to myspace & myspace & myspace

set old_track_id to ""
set old_state to ""

display alert "Instructions: Launch Audio Hijack & Hijack Spotify. Then, find a song in Spotify and play then pause it. Then click Ready!" buttons {"Quit", "Ready!"}
set choice to button returned of the result
if choice is "Quit" then
	tell me to quit
end if

tell application "Audio Hijack Pro"
	set theSession to first session whose name is "Spotify"
	start hijacking theSession relaunch yes
	start recording theSession
end tell

set smallDelay to 0.3 -- Needed to let AH start recording? Check this...
delay smallDelay

tell application "Spotify" to set player position to 0
tell application "Spotify" to play current track

repeat
	try
		set boolStarted to false
		set boolPaused to false
		
		--main crap
		
		tell application "Spotify" to set track_id to id of current track
		tell application "Spotify" to set theState to player state as string
		
		if theState is "paused" then tell application "Audio Hijack Pro" to pause recording theSession
		if theState is "playing" then tell application "Audio Hijack Pro" to unpause recording theSession
		
		if theState is "stopped" then tell application "Audio Hijack Pro"
			stop recording theSession
			stop hijacking theSession
			tell me to quit
		end tell
		
		if (old_track_id is not track_id) then
			tell application "Spotify" to pause current track
			
			tell application "Audio Hijack Pro" to stop recording theSession
			tell application "Audio Hijack Pro" to stop hijacking theSession
			
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
				set album tag of theSession to cAlbum
				set album artist tag of theSession to cAlbumArtist
				set artist tag of theSession to cArtist
				set title tag of theSession to cName
				set track number tag of theSession to cTrackNum
				set disc number tag of theSession to cDiscNum
				start hijacking theSession
				start recording theSession
			end tell
			
			--set timeDelay to 1
			--delay delay_time
			tell application "Spotify" to play current track
		end if
		
		set old_track_id to track_id
		tell application "Spotify"
			set trackLength to duration of current track
			set currentTime to player position
			set delay_time to trackLength - currentTime
		end tell
	end try
	delay delay_time
end repeat