//
// AppDelegate.m
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

#import "AppDelegate.h"

@implementation AppDelegate

#pragma mark - Object Lifecycle
- (id)init {
  self = [super init];
  
  if (self) {
    _mainWindowController = [[SPJMainWindowController alloc]
                             initWithWindowNibName:@"SPJMainWindow"];
  }
  return self;
}

+ (void)initialize
{
  if (self == [AppDelegate class]) {
    NSDictionary *userDefaultsDict = @{SPJMuteSpotifyForSessionKey:@NO};
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsDict];
  }
}

#pragma mark - NSApplicationDelegate Protocol

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [DDLog addLogger:[DDASLLogger sharedInstance]];
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
  
  [self applicationShouldHandleReopen:nil hasVisibleWindows:NO]; // Display the main window
  // Initialise and handle any errors
  NSError *error;
  BOOL success = [[SPJSessionController sharedController]
                  initializeRecordingSessions:&error];
  if (!success) {
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert beginSheetModalForWindow:[self.mainWindowController window]
                  completionHandler:^(NSModalResponse returnCode) {
                    if (error.recoveryAttempter) {
                      [error.recoveryAttempter attemptRecoveryFromError:error
                                                            optionIndex:returnCode];
                    }
                  }];
    [[self.mainWindowController recordingButton] setEnabled:NO];
    [self.mainWindowController.statusLabel
     setStringValue:NSLocalizedString(@"Not ready to record", nil)];
  } else {
    [self.mainWindowController.statusLabel
     setStringValue:NSLocalizedString(@"Ready to Record", nil)];
  }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  if ([SPJSessionController sharedController].isRecording) {
    return NO;
  }
  return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  if ([SPJSessionController sharedController].isRecording) {
    NSAlert *sessionQuitAlert = [[NSAlert alloc] init];
    sessionQuitAlert.messageText = NSLocalizedString(@"Recording in Progress", nil);
    sessionQuitAlert.informativeText = NSLocalizedString(@"Are you sure you want to quit?", nil);
    [sessionQuitAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [sessionQuitAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    
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
  if ([SPJSessionController sharedController].isRecording) {
    [[SPJSessionController sharedController] stopRecordingSession];
  }
  [[[SPJSessionController sharedController] audioHijackSpotifySession]
   stopHijacking];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender
                    hasVisibleWindows:(BOOL)flag {
  if (!flag) {
    [self.mainWindowController showWindow:self];
    return NO;
  }
  return YES;
}

#pragma mark - IBActions

- (IBAction)openPreferencesWindow:(id)sender {
  if (!self.preferencesWindowController) {
    self.preferencesWindowController = [[SPJPreferencesWindowController alloc]
                                        initWithWindowNibName:@"SPJPreferencesWindow"];
  }
  [self.preferencesWindowController showWindow:self];
}

@end
