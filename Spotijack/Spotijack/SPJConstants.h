//
//  SPJConstants.h
//  Spotijack
//
//  Created by Alex Jackson on 16/05/2015.
//  Copyright (c) 2015 Alex Jackson. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - Bundle Identifiers
extern NSString * const SPJAudioHijackIdentifier;
extern NSString * const SPJSpotifyIdentifier;

#pragma mark - NSUserDefaults Key
extern NSString * const SPJMuteSpotifyForSessionKey;
extern NSString * const SPJNotifyWhenRecordingFinishesKey;

#pragma mark NSNotificationCentre Keys
extern NSString * const SPJTrackDidChangeNotification;
/** Posted when Spotify runs out of songs to play and the AHP recording is
    finished. */
extern NSString * const SPJRecordingSessionFinishedNotificaiton;
/**
 *  Posted when an @p SPJAudioHijackSessionError is succesfully resolved.
 */
extern NSString * const SPJSessionCreatedNotification;

#pragma mark Error codes
extern NSInteger const SPJAudioHijackLaunchError;
extern NSInteger const SPJAudioHijackScriptingError;
extern NSInteger const SPJSpotifyLaunchError;
extern NSInteger const SPJSpotifyScriptingError;
extern NSInteger const SPJAudioHijackSessionError;
extern NSInteger const SPJSpotifyNoSongPlayingError;