//
//  SPJSessionController.h
//  Spotijack
//
//  Created by Alex Jackson on 17/12/2014.
//  Copyright (c) 2014 Alex Jackson. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AudioHijack.h"
#import "Spotify.h"

@interface SPJSessionController : NSObject

@property (assign) BOOL playingMusic;
@property (strong) NSTimer *spotifyPollingTimer;

@property (strong) SpotifyApplication *spotifyApp;
@property (strong) AudioHijackApplication *audioHijackApp;
@property (strong) AudioHijackSession *audioHijackSpotifySession;

+ (SPJSessionController *)sharedController;

/**
 Initialises Audio Hijack Pro by hijacking the first session who's name is Spotify. Will restart Spotify if Instant Hijack isn't set up
 */
- (void)initializeAudioHijackPro;

/**
 Starts the recording session. Pauses Spotify, sets play position to 0, starts AH Session, creates timer, starts playing Spotify. That's it.
 */
- (void)startRecordingSession;
/** 
 Stops the recording session. Pauses Spotify, ends AH Session, invalidates timer. 
 */
- (void)stopRecordingSession;

@end
