//
// SPJSessionController.h
//
// Copyright (c) 2014 Alex Jackson
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

#import "AudioHijack.h"
#import "Spotify.h"
#import "SPJPreferencesWindowController.h"
#import "SPJSessionCreator.h"

@interface SPJSessionController : NSObject

@property (assign) BOOL isRecording;
@property (assign,nonatomic) BOOL isMuted;
@property (strong) NSTimer *spotifyPollingTimer;
@property (strong) NSTimer *audioHijackProMutePollingTimer;

@property (strong) SpotifyApplication *spotifyApp;
@property (strong) AudioHijackApplication *audioHijackApp;
@property (strong) AudioHijackSession *audioHijackSpotifySession;

+ (SPJSessionController *)sharedController;

/**
 *  Launches Spotify and Audio Hijack Pro for scripting and attempts to start 
 *  the hijacking session called "Spotify". This method should be called before 
 *  doing anything. Failure to do so will probably result in crashes.
 *
 *  @param error A pointer to an error object that contains information on any 
 *         errors that may have occurred.
 *
 *  @return @p YES on successful initialisation or @p NO otherwise.
 */
- (BOOL)initializeRecordingSessions:(NSError *__autoreleasing *)error;

/**
 Starts the recording session. Pauses Spotify, sets play position to 0, 
 starts AH Session, creates timer, starts playing Spotify. That's it.
 
 @param error A pointer to an error object that contains information on any 
        errors that may have occurred. May be @p nil.

 @return A bool indicating if the recording session started successfully
 */
- (BOOL)startRecordingSession:(NSError *__autoreleasing *)error;
/** 
 Stops the recording session. Pauses Spotify, ends AH Session, invalidates 
 timer.
 */
- (void)stopRecordingSession;
/**
 *  Mutes or unmutes the current Audio Hijack Pro recording session.
 *
 *  @param isMuted A bool indicating if the session should be muted. @p YES to 
           mute, @p NO to unmute.
 */
- (void)setIsMuted:(BOOL)isMuted;

@end
