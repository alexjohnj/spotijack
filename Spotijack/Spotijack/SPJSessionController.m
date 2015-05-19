//
// SPJSessionController.m
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

#import "SPJSessionController.h"

@interface SPJSessionController ()
@property (copy) NSString *currentTrackID;
@property (strong) id recordingActivityToken;
@end

@implementation SPJSessionController

#pragma mark - Object Lifecycle
+ (SPJSessionController *)sharedController {
  static dispatch_once_t onceToken;
  __strong static SPJSessionController *sharedController;
  dispatch_once(&onceToken, ^{
    sharedController = [[self alloc] init];
    sharedController.isRecording = NO;
  });
  return sharedController;
}

#pragma mark - Session Recording
- (BOOL)initializeRecordingSessions:(NSError *__autoreleasing *)error {
  // Try and start Audio Hijack Pro and Spotijack for scripting
  self.audioHijackApp = [SBApplication
                         applicationWithBundleIdentifier:SPJAudioHijackIdentifier];
  if (!self.audioHijackApp) {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: NSLocalizedString(@"AHP_OPEN_ERROR", nil),
                               NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"AHP_OPEN_ERROR_REASON", nil),
                               NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"AHP_OPEN_ERROR_SUGGESTION", nil)
                               };
    *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                 code:SPJAudioHijackScriptingError
                             userInfo:userInfo];
    return NO;
  }
  self.spotifyApp = [SBApplication applicationWithBundleIdentifier:SPJSpotifyIdentifier];
  if (!self.spotifyApp) {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: NSLocalizedString(@"SPOT_OPEN_ERROR", nil),
                               NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"SPOT_OPEN_ERROR_REASON", nil),
                               NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"SPOT_OPEN_ERROR_SUGGESTION", nil)
                               };
    *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                 code:SPJSpotifyScriptingError
                             userInfo:userInfo];
    return NO;
  }
  
  // Try and find a recording session for Spotify and make it active
  for (AudioHijackSession *session in self.audioHijackApp.sessions) {
    if ([session.name isEqualToString:@"Spotijack"]) {
      self.audioHijackSpotifySession = session;
      break;
    }
  }
  if (!self.audioHijackSpotifySession) {
    SPJSessionCreator *recoveryAttempter = [[SPJSessionCreator alloc] init];
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: NSLocalizedString(@"AHP_NO_SESS_ERROR", nil),
                               NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"AHP_NO_SESS_ERROR_REASON", nil),
                               NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"AHP_NO_SESS_ERROR_SUGGESTION", nil),
                               NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"AHP_NO_SESS_ERROR_FIX_CREATE", nil), NSLocalizedString(@"No", nil)],
                               NSRecoveryAttempterErrorKey: recoveryAttempter
                               };
    *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                 code:SPJAudioHijackSessionError
                             userInfo:userInfo];
    return NO;
  }
  
  [self.audioHijackSpotifySession startHijackingRelaunch:AudioHijackRelaunchOptionsYes];
  
  return YES;
}
- (BOOL)startRecordingSession {
  if (self.isRecording) {
    DDLogWarn(@"Attempted to start new recording session while previous session was active. Aborting.");
    return NO;
  }
  
  if (!self.spotifyApp.currentTrack.id) { // Have to check against ID as currentTrack will never be nil
    NSAlert *noTrackAlert = [[NSAlert alloc] init];
    noTrackAlert.messageText = NSLocalizedString(@"No Track Playing", nil);
    noTrackAlert.informativeText = NSLocalizedString(@"Please start a track in Spotify", nil);
    [noTrackAlert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:NULL];
    return NO;
  }
  
  // See if we need to/should disable shuffling
  if (self.spotifyApp.shuffling) {
    NSAlert *shufflingAlert = [[NSAlert alloc] init];
    shufflingAlert.messageText = NSLocalizedString(@"Disable Shuffling?", nil);
    [shufflingAlert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
    [shufflingAlert addButtonWithTitle:NSLocalizedString(@"No", nil)];
    
    [shufflingAlert beginSheetModalForWindow:[NSApp mainWindow]
                           completionHandler:^(NSModalResponse returnCode) {
                             if (returnCode == NSAlertFirstButtonReturn) {
                               self.spotifyApp.shuffling = false;
                             }
                           }];
  }
  
  
  self.recordingActivityToken = [[NSProcessInfo processInfo]
                                 beginActivityWithOptions:(NSActivityUserInitiated|NSActivityIdleSystemSleepDisabled)
                                 reason:@"Recording session in progress"];
  self.spotifyPollingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                              target:self
                                                            selector:@selector(pollSpotify)
                                                            userInfo:nil
                                                             repeats:TRUE];
  
  [self.audioHijackSpotifySession startHijackingRelaunch:AudioHijackRelaunchOptionsYes];
  [self.audioHijackSpotifySession startRecording];
  self.audioHijackSpotifySession.speakerMuted = [[NSUserDefaults standardUserDefaults]
                                                 boolForKey:SPJMuteSpotifyForSessionKey];
  [self.spotifyApp setPlayerPosition:0.0];
  [self.spotifyApp play];
  self.isRecording = YES;
  return YES;
}

- (void)stopRecordingSession {
  [self.spotifyApp pause];
  [self.audioHijackSpotifySession stopRecording];
  self.isRecording = NO;
  
  if ([[NSUserDefaults standardUserDefaults]
       boolForKey:SPJMuteSpotifyForSessionKey]) {
    self.audioHijackSpotifySession.speakerMuted = NO;
  }
  
  [self.spotifyPollingTimer invalidate];
  [[NSProcessInfo processInfo] endActivity:self.recordingActivityToken];
}

#pragma mark Private Methods

/**
 Polls Spotify, comparing the stored track ID with the current track's ID.
 Posts a track change notification if the IDs are different and sets up the
 next recording session for AH.
 */
- (void)pollSpotify {
  SpotifyTrack *suspectTrack = self.spotifyApp.currentTrack;
  if (!suspectTrack) {
    [self stopRecordingSession];
  }
  
  if (![self.currentTrackID isEqualToString:suspectTrack.id]) {
    // Check if Spotify has reached the end of a playlist
    if ([self.spotifyApp playerState] == SpotifyEPlSPaused) {
      [self stopRecordingSession];
      return;
    }
    
    [self.spotifyApp pause];
    [self.audioHijackSpotifySession stopRecording];
    [self updateMetadata];
    
    [self.audioHijackSpotifySession startRecording];
    [self.spotifyApp play];
    self.currentTrackID = suspectTrack.id;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SPJTrackDidChangeNotification
                                                        object:self
                                                      userInfo:@{
                                                                 @"TrackTitle": self.spotifyApp.currentTrack.name,
                                                                 @"TrackArtist": self.spotifyApp.currentTrack.artist,
                                                                 }];
  }
}

/**
 Updates as much metadata as possible for the current AH recording session using
 what's available from Spotify.
 */
- (void)updateMetadata {
  self.audioHijackSpotifySession.titleTag = self.spotifyApp.currentTrack.name;
  self.audioHijackSpotifySession.artistTag = self.spotifyApp.currentTrack.artist;
  self.audioHijackSpotifySession.albumArtistTag = self.spotifyApp.currentTrack.albumArtist;
  self.audioHijackSpotifySession.albumTag = self.spotifyApp.currentTrack.album;
  self.audioHijackSpotifySession.trackNumberTag = [NSString stringWithFormat:@"%lu", self.spotifyApp.currentTrack.trackNumber];
  self.audioHijackSpotifySession.discNumberTag = [NSString stringWithFormat:@"%lu", self.spotifyApp.currentTrack.discNumber];
}

@end
