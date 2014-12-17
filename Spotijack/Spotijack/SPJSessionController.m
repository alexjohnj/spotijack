//
//  SPJSessionController.m
//  Spotijack
//
//  Created by Alex Jackson on 17/12/2014.
//  Copyright (c) 2014 Alex Jackson. All rights reserved.
//

#import "SPJSessionController.h"

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

@end
