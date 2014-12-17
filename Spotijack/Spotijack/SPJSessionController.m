//
//  SPJSessionController.m
//  Spotijack
//
//  Created by Alex Jackson on 17/12/2014.
//  Copyright (c) 2014 Alex Jackson. All rights reserved.
//

#import "SPJSessionController.h"

@interface SPJSessionController ()

@property (copy) NSString *currentTrackID;

@end

@implementation SPJSessionController

+ (SPJSessionController *)sharedController {
  static dispatch_once_t onceToken;
  __strong static SPJSessionController *sharedController;
  dispatch_once(&onceToken, ^{
    sharedController = [[self alloc] init];
    sharedController.playingMusic = NO;
    
    sharedController.audioHijackApp = [SBApplication applicationWithBundleIdentifier:@"com.rogueamoeba.AudioHijackPro2"];
    if (!sharedController.audioHijackApp) {
      NSLog(@"Unable to open Audio Hijack Pro for Scripting! Prepare to crash...");
    }
    
    sharedController.spotifyApp = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
    if (!sharedController.spotifyApp) {
      NSLog(@"Unable to open Spotify for Scripting!");
    }
  });
  return sharedController;
}

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

#pragma mark - Session Recording
- (void)startRecordingSession {
  // Just in case we were recording
  [self stopRecordingSession];
  
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
  
  if (!self.spotifyApp.currentTrack) {
    NSAlert *noTrackAlert = [[NSAlert alloc] init];
    noTrackAlert.messageText = @"Please start a track in Spotify";
    [noTrackAlert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:NULL];
    return; // TODO: Make this continously prompt to start a track
  }
  
  // TODO: Somewhere around here we need to tell OSX to disable AppNap for Spotijack otherwise the timer could be
  // delayed a significant amount
  if (!self.spotifyPollingTimer) {
    self.spotifyPollingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                target:self
                                                              selector:@selector(pollSpotify)
                                                              userInfo:nil
                                                               repeats:TRUE];
  }
  
  [self.audioHijackSpotifySession startHijackingRelaunch:AudioHijackRelaunchOptionsYes];
  [self.audioHijackSpotifySession startRecording];
  
  [self.spotifyApp setPlayerPosition:0.0];
  [self.spotifyApp play];
  self.playingMusic = YES;
}

- (void)stopRecordingSession {
  [self.spotifyApp pause];
  [self.audioHijackSpotifySession stopRecording];
  self.playingMusic = NO;
  [self.spotifyPollingTimer invalidate];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SPJTrackChanged"
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
