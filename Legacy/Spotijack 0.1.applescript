set delay_time to 0.1

set myspace to " "
set myspace2 to myspace & myspace
set myspace3 to myspace & myspace & myspace

set old_track_id to ""
set old_state to ""

tell application "Audio Hijack Pro"
	set theSession to first session whose name is "Spotify"
	start hijacking theSession relaunch yes
	start recording theSession
end tell

set smallDelay to 0.3
delay smallDelay

tell application "Spotify" to play current track

repeat
	try
		set boolStarted to false
		set boolPaused to false
		
		--main crap
		
		tell application "Spotify" to set track_id to id of current track
		tell application "Spotify" to set theState to player state as string
		
		if ((old_state is "stopped") or (old_state is "paused")) and theState is "playing" then set boolStarted to true
		if (old_state is "playing") and theState is "paused" then set boolPaused to true
		
		set old_state to theState
		
		if (old_track_id is not track_id) then
			tell application "Spotify" to pause current track
			
			tell application "Audio Hijack Pro" to split recording theSession
			--set timeDelay to 1
			--delay delay_time
			tell application "Spotify" to play current track
		end if
		
		set old_track_id to track_id
		
	end try
	delay delay_time
end repeat
