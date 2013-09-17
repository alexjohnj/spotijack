--
--  SCAppDelegate.applescript
--  Spotijack
--
--  Created by Alex Jackson on 29/07/2013.
--  Copyright (c) 2013 Alex Jackson. All rights reserved.
--

script SCAppDelegate
	property parent : class "NSObject"
	property songTitleLabel : missing value
    property artistLabel : missing value
	property actionButton : missing value
	property playingMusic : false
	
	on applicationWillFinishLaunching_(aNotification)
		# Get AH & Spotify set up
		try
			tell application "Audio Hijack Pro"
				launch
				set theSession to first session whose name is "Spotify"
				start hijacking theSession relaunch yes
			end tell
		on error errmesg number errn
			display dialog errmesg & return & return & "error number: " & (errn as text)
			songTitleLabel's setStringValue_("Error")
			songTitleLabel's setTextColor_(current application's NSColor's redColor)
		end try
		songTitleLabel's setStringValue_("Ready to Record")
	end applicationWillFinishLaunching_
	
	on applicationShouldTerminate_(sender)
		-- Insert code here to do any housekeeping before your application quits 
		return current application's NSTerminateNow
	end applicationShouldTerminate_
	
	on applicationShouldTerminateAfterLastWindowClosed_(sender)
		return true
	end applicationShouldTerminateAfterLastWindowClosed_
	
	on actionButtonClicked_(sender)
		if my playingMusic as boolean is false then
			actionButton's setTitle_("Recording")
            actionButton's setState_(1) -- 1 == NSOnState
			my setPlayingMusic_(true as boolean)
			performSelectorInBackground_withObject_("recordMusic:", "test")
		else
			actionButton's setTitle_("Record")
            actionButton's setState_(0) -- 0 == NSOffState
			my setPlayingMusic_(false as boolean)
		end if
	end actionButtonClicked_
	
	on nextTrackButtonClicked_(sender)
		tell application "Spotify" to play (next track)
	end nextTrackButtonClicked_
	
	on previousButtonClicked_(sender)
		tell application "Spotify" to play (previous track)
	end previousButtonClicked_
	
	on recordMusic_()
		# Stop all AH sessions and pause Spotify
		resetApps_()
		
		# Determine if Shuffling is enabled and ask user if they want to disable it
		tell application "Spotify" to set shufflingIsEnabled to shuffling
		if shufflingIsEnabled is true then
			set disableShuffling to true
			try
				display dialog "Disable Shuffling?" buttons {"No", "Yes"} default button "Yes" cancel button "No"
			on error number -128
				set disableShuffling to false
			end try
			if disableShuffling is true then
				tell application "Spotify" to set shuffling to false
			end if
		end if
		
		# Determine ID of current track. If there's no song, prompt the user to chose one
		try
			tell application "Spotify" to set current_track_id to id of current track
			tell application "Spotify" to set old_track_id to id of current track
			tell application "Spotify" to set currentTrackTitle to name of current track
			songTitleLabel's setStringValue_(currentTrackTitle)
		on error errmesg number errn
			if errn is -1728 then
				songTitleLabel's setStringValue_("Start a song in Spotify")
			else
				display dialog errmesg & return & return & "error number: " & (errn as text)
			end if
			actionButton's setTitle_("Start")
			my setPlayingMusic_(false as boolean)
			return
		end try
		
		# Set up the AH session and start recording
		updateTrackMetadata_()
		tell application "Audio Hijack Pro" to set theSession to first session whose name is "Spotify"
		tell application "Audio Hijack Pro" to start hijacking theSession
		tell application "Audio Hijack Pro" to start recording theSession
		
		delay 0.1 -- Small delay needed to allow AH to start recording, otherwise the first µs of the song is cut off. Small but noticeable.
		
		# Reset Spotify's play position and start playing a track
		tell application "Spotify" to set player position to 0
		tell application "Spotify" to play current track
		tell application "Spotify" to set currentTrackTitle to name of current track
		tell application "Spotify" to set currentTrackArtist to artist of current track
        
		songTitleLabel's setStringValue_(currentTrackTitle)
        artistLabel's setStringValue_(currentTrackArtist)
		
		repeat
			
			# Check if user has asked to stop recording music.
			if my playingMusic as boolean is false then
				resetApps_()
				songTitleLabel's setStringValue_("Ready to Record")
                artistLabel's setStringValue_("")
				return
			end if
			
			# Get the current track's ID
			try
				tell application "Spotify" to set current_track_id to id of current track
			on error errmesg number errn
				if errn is -1728 then -- Error -1728 indicates there is no track playing so assume we've finished
					songTitleLabel's setStringValue_("Ready to Record")
                    artistLabel's setStringValue_("")
					actionButton's setTitle_("Record")
					my setPlayingMusic_(false as boolean)
					resetApps_()
					return
				end if
			end try
			
			# Check to see if the track ID (& hence the track) has changed. Start a new AH session if it has
			if (current_track_id is not old_track_id) then
				tell application "Spotify" to pause current track
				tell application "Audio Hijack Pro"
					stop recording theSession
					stop hijacking theSession
				end tell
				updateTrackMetadata_()
				tell application "Audio Hijack Pro"
					start hijacking theSession
					start recording theSession
				end tell
				tell application "Spotify" to play current track
				tell application "Spotify" to set currentTrackTitle to name of current track
                tell application "Spotify" to set currentTrackArtist to artist of current track
				set old_track_id to current_track_id
				songTitleLabel's setStringValue_(currentTrackTitle)
                artistLabel's setStringValue_(currentTrackArtist)
			end if
			delay 0.1 -- Polling interval for Spotify
		end repeat
	end recordMusic_
	
	on updateTrackMetadata_()
		# Simple method, just updates AH metadata for the current recording
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
			set theSession to first session whose name is "Spotify"
			set album tag of theSession to cAlbum
			set album artist tag of theSession to cAlbumArtist
			set artist tag of theSession to cArtist
			set title tag of theSession to cName
			set track number tag of theSession to cTrackNum
			set disc number tag of theSession to cDiscNum
		end tell
	end updateTrackMetadata_
	
	on resetApps_()
		# Pauses Spotify and ends the current session in AH
		tell application "Audio Hijack Pro"
			set theSession to first session whose name is "Spotify"
			stop recording theSession
			stop hijacking theSession
		end tell
		tell application "Spotify"
			pause current track
		end tell
	end resetApps_
	
end script