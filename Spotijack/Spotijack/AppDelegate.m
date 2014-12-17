//
//  AppDelegate.m
//  Spotijack
//
//  Created by Alex Jackson on 17/12/2014.
//  Copyright (c) 2014 Alex Jackson. All rights reserved.
//

#import "AppDelegate.h"
#import "AudioHijack.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (id)init {
  self = [super init];
  
  if (self) {
    _mainWindowController = [[SPJMainWindowController alloc] initWithWindowNibName:@"SPJMainWindow"];
  }
  return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
  // Initialise Audio Hijack Pro
  AudioHijackApplication *ahApp = [SBApplication applicationWithBundleIdentifier:@"com.rogueamoeba.AudioHijackPro2"];
  [ahApp activate];
  AudioHijackApplicationSession *spotifySession = nil;
  for (AudioHijackApplicationSession *session in ahApp.sessions) {
    if ([session.name isEqualToString:@"Spotify"]) {
      spotifySession = session;
      break;
    }
  }
  
  [spotifySession startHijackingRelaunch:AudioHijackRelaunchOptionsYes];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self applicationShouldHandleReopen:nil hasVisibleWindows:NO]; // Display the main window
  [self.mainWindowController.statusLabel setStringValue:@"Ready to Record"];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Insert code here to tear down your application
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
  if (!flag) {
    [self.mainWindowController showWindow:self];
    return NO;
  }
  return YES;
}

@end
