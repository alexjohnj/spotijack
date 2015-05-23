//
// SPJMainWindowController.m
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

#import "SPJMainWindowController.h"

@interface SPJMainWindowController ()

@end

@implementation SPJMainWindowController

#pragma mark - NSWindowController

- (void)windowDidLoad {
  [super windowDidLoad];
  [[SPJSessionController sharedController] addObserver:self
                                            forKeyPath:@"isRecording"
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(trackChanged:)
                                               name:SPJTrackDidChangeNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(recordingSessionEnded:)
                                               name:SPJRecordingSessionFinishedNotificaiton
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserverForName:SPJSessionCreatedNotification
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification *note) {
                                                  self.statusLabel.stringValue = NSLocalizedString(@"Ready to Record", nil);
                                                  self.artistLabel.stringValue = @"";
                                                  self.recordingButton.enabled = YES;
                                                }];
}

#pragma mark - IBActions

- (IBAction)recordButtonPressed:(id)sender {
  if ([SPJSessionController sharedController].isRecording) {
    [[SPJSessionController sharedController] stopRecordingSession];
    self.statusLabel.stringValue = NSLocalizedString(@"Ready to Record", nil);
    self.artistLabel.stringValue = @"";
  } else {
    NSError *recordingInitError;
    BOOL success = [[SPJSessionController sharedController]
                    startRecordingSession:&recordingInitError];
    if (!success) {
      NSAlert *recordingFailAlert = [NSAlert alertWithError:recordingInitError];
      [recordingFailAlert beginSheetModalForWindow:self.window
                                 completionHandler:nil];
      return;
    }
    
    // Offer to disable shuffling if it's enabled
    BOOL shufflingEnabled = [[[SPJSessionController sharedController]
                              spotifyApp]
                             shuffling];
    if (shufflingEnabled) {
      NSAlert *shufflingAlert = [[NSAlert alloc] init];
      shufflingAlert.messageText = NSLocalizedString(@"Disable Shuffling?", nil);
      [shufflingAlert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
      [shufflingAlert addButtonWithTitle:NSLocalizedString(@"No", nil)];
      [shufflingAlert beginSheetModalForWindow:self.window
                             completionHandler:^(NSModalResponse returnCode) {
                               if (returnCode == NSAlertFirstButtonReturn) {
                                 [[[SPJSessionController sharedController]
                                   spotifyApp]
                                  setShuffling:NO];
                               }
                             }];
    }
  }
}

#pragma mark - Private Methods

- (void)trackChanged:(NSNotification *)notification {
  self.statusLabel.stringValue = notification.userInfo[@"TrackTitle"];
  self.artistLabel.stringValue = notification.userInfo[@"TrackArtist"];
}

- (void)recordingSessionEnded:(NSNotification *)notification {
  if (![[NSUserDefaults standardUserDefaults] boolForKey:SPJNotifyWhenRecordingFinishesKey]) {
    return;
  }
  NSUserNotification *endNoti = [[NSUserNotification alloc] init];
  endNoti.title = NSLocalizedString(@"SESSION_END_NOTI", nil);
  endNoti.subtitle = NSLocalizedString(@"SESSION_END_NOTI_SUBT", nil);
  endNoti.hasActionButton = NO;
  [[NSUserNotificationCenter defaultUserNotificationCenter]
   deliverNotification:endNoti];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqualToString:@"isRecording"]) {
    if ([change[NSKeyValueChangeNewKey] isEqualTo:@YES]) {
      self.recordingButton.title = NSLocalizedString(@"Recording", nil);
      self.recordingButton.state = NSOnState;
    } else {
      self.recordingButton.title = NSLocalizedString(@"Record", nil);
      self.recordingButton.state = NSOffState;
      self.statusLabel.stringValue = NSLocalizedString(@"Ready to Record", nil);
      self.artistLabel.stringValue = @"";
    }
  }
}

#pragma mark - Object Lifecycle

- (void)dealloc {
  [[SPJSessionController sharedController] removeObserver:self
                                               forKeyPath:@"recording"];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
