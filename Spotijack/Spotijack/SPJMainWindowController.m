//
//  SPJMainWindowController.m
//  Spotijack
//
//  Created by Alex Jackson on 17/12/2014.
//  Copyright (c) 2014 Alex Jackson. All rights reserved.
//

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
}

#pragma mark - IBActions

- (IBAction)recordButtonPressed:(id)sender {
  if ([SPJSessionController sharedController].isRecording) {
    [[SPJSessionController sharedController] stopRecordingSession];
    self.statusLabel.stringValue = @"Ready to Record";
    self.artistLabel.stringValue = @"";
  } else {
    self.recordingButton.state = [[SPJSessionController sharedController] startRecordingSession];
  }
}

#pragma mark - Private Methods

- (void)trackChanged:(NSNotification *)notification {
  self.statusLabel.stringValue = notification.userInfo[@"TrackTitle"];
  self.artistLabel.stringValue = notification.userInfo[@"TrackArtist"];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqualToString:@"isRecording"]) {
    if ([change[NSKeyValueChangeNewKey] isEqualTo:@YES]) {
      self.recordingButton.title = @"Recording";
    } else {
      self.recordingButton.title = @"Record";
    }
  }
}

#pragma mark - Object Lifecycle

- (void)dealloc {
  [[SPJSessionController sharedController] removeObserver:self forKeyPath:@"recording"];
  [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:SPJTrackDidChangeNotification];
}

@end
