//
//  AppDelegate.m
//  Spotijack
//
//  Created by Alex Jackson on 17/12/2014.
//  Copyright (c) 2014 Alex Jackson. All rights reserved.
//

#import "AppDelegate.h"

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
  [[SPJSessionController sharedController] initializeAudioHijackPro];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self applicationShouldHandleReopen:nil hasVisibleWindows:NO]; // Display the main window
  [self.mainWindowController.statusLabel setStringValue:@"Ready to Record"];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  [[[SPJSessionController sharedController] audioHijackSpotifySession] stopHijacking];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
  if (!flag) {
    [self.mainWindowController showWindow:self];
    return NO;
  }
  return YES;
}

@end
