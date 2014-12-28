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

@interface SPJSessionController : NSObject

@property (assign) BOOL isRecording;
@property (strong) NSTimer *spotifyPollingTimer;

@property (strong) SpotifyApplication *spotifyApp;
@property (strong) AudioHijackApplication *audioHijackApp;
@property (strong) AudioHijackSession *audioHijackSpotifySession;

+ (SPJSessionController *)sharedController;

/**
 Initialises Audio Hijack Pro by hijacking the first session who's name is Spotify. Will restart Spotify if Instant 
 Hijack isn't set up.
 */
- (void)initializeAudioHijackPro;

/**
 Starts the recording session. Pauses Spotify, sets play position to 0, starts AH Session, creates timer, starts playing 
 Spotify. That's it.

 @return A bool indicating if the recording session started successfully
 */
- (BOOL)startRecordingSession;
/** 
 Stops the recording session. Pauses Spotify, ends AH Session, invalidates timer. 
 */
- (void)stopRecordingSession;

extern NSString * const SPJTrackDidChangeNotification;

@end
