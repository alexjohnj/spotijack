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

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  if ([[SPJSessionController sharedController] playingMusic]) {
    return NO;
  }
  return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  if ([[SPJSessionController sharedController] playingMusic]) {
    NSAlert *sessionQuitAlert = [[NSAlert alloc] init];
    sessionQuitAlert.messageText = @"Recording in Process";
    sessionQuitAlert.informativeText = @"Are you sure you want to quit?";
    [sessionQuitAlert addButtonWithTitle:@"Cancel"];
    [sessionQuitAlert addButtonWithTitle:@"OK"];
    
    [sessionQuitAlert beginSheetModalForWindow:self.mainWindowController.window
                             completionHandler:^(NSModalResponse returnCode) {
                               if (returnCode == NSAlertFirstButtonReturn){
                                 [NSApp replyToApplicationShouldTerminate:NO];
                               } else {
                                 [NSApp replyToApplicationShouldTerminate:YES];
                               }
                             }];
    return NSTerminateLater;
  }
  return NSTerminateNow;
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
