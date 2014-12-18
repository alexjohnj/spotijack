//
//  SPJSessionController.m
//  Spotijack
//
//  Created by Alex Jackson on 17/12/2014.
//  Copyright (c) 2014 Alex Jackson. All rights reserved.
//

#import "SPJSessionController.h"

NSString * const SPJTrackDidChangeNotification = @"SPJTrackChanged";

static NSString * const SPJAudioHijackIdentifier = @"com.rogueamoeba.AudioHijackPro2";
static NSString * const SPJSpotifyIdentifier = @"com.spotify.client";

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
    sharedController.playingMusic = NO;
    
    sharedController.audioHijackApp = [SBApplication applicationWithBundleIdentifier:SPJAudioHijackIdentifier];
    if (!sharedController.audioHijackApp) {
      NSLog(@"Unable to open Audio Hijack Pro for Scripting! Prepare to crash...");
    }
    
    sharedController.spotifyApp = [SBApplication applicationWithBundleIdentifier:SPJSpotifyIdentifier];
    if (!sharedController.spotifyApp) {
      NSLog(@"Unable to open Spotify for Scripting!");
    }
  });
  return sharedController;
}

#pragma mark - Session Recording
/**
 Initializes AH by selecting the first recording session who's name is Spotify.
 */
- (void)initializeAudioHijackPro {
  [self.audioHijackApp activate];
  for (AudioHijackSession *session in self.audioHijackApp.sessions) {
    if ([session.name isEqualToString:@"Spotify"]) {
      self.audioHijackSpotifySession = session;
      break;
    }
  }
  [self.audioHijackSpotifySession startHijackingRelaunch:AudioHijackRelaunchOptionsYes];
}

- (BOOL)startRecordingSession {
  if (self.playingMusic) {
    NSLog(@"Attempted to start new recording session while previous session was active. Aborting.");
    return NO;
  }
  
  if (!self.spotifyApp.currentTrack.id) { // Have to check against ID as currentTrack will never be nil
    NSAlert *noTrackAlert = [[NSAlert alloc] init];
    noTrackAlert.messageText = @"No Track Playing";
    noTrackAlert.informativeText = @"Please start a track in Spotify";
    [noTrackAlert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:NULL];
    return NO; // TODO: Make this continously prompt to start a track
  }
  
  // See if we need to/should disable shuffling
  if (self.spotifyApp.shuffling) {
    NSAlert *shufflingAlert = [[NSAlert alloc] init];
    shufflingAlert.messageText = @"Disable Shuffling?";
    [shufflingAlert addButtonWithTitle:@"Yes"];
    [shufflingAlert addButtonWithTitle:@"No"];
    
    [shufflingAlert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse returnCode) {
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
  
  [self.spotifyApp setPlayerPosition:0.0];
  [self.spotifyApp play];
  self.playingMusic = YES;
  return YES;
}

- (void)stopRecordingSession {
  [self.spotifyApp pause];
  [self.audioHijackSpotifySession stopRecording];
  self.playingMusic = NO;
  [self.spotifyPollingTimer invalidate];
  [[NSProcessInfo processInfo] endActivity:self.recordingActivityToken];
}

#pragma mark Private Methods

/**
 Polls Spotify, comparing the stored track ID with the current track's ID. Posts a track change notification if the IDs
 are different and sets up the next recording session for AH.
 */
- (void)pollSpotify {
  SpotifyTrack *suspectTrack = self.spotifyApp.currentTrack;
  if (!suspectTrack) {
    [self stopRecordingSession];
  }
  
  if (![self.currentTrackID isEqualToString:suspectTrack.id]) {
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
 Updates as much metadata as possible for the current AH recording session using what's available from Spotify.
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
