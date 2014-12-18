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
                                            forKeyPath:@"playingMusic"
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(trackChanged:)
                                               name:SPJTrackDidChangeNotification
                                             object:nil];
}

#pragma mark - IBActions

- (IBAction)recordButtonPressed:(id)sender {
  if ([[SPJSessionController sharedController] playingMusic]) {
    [[SPJSessionController sharedController] stopRecordingSession];
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
  if ([keyPath isEqualToString:@"playingMusic"]) {
    if ([change[NSKeyValueChangeNewKey] isEqualTo:@YES]) {
      self.recordingButton.title = @"Recording";
    } else {
      self.recordingButton.title = @"Record";
    }
  }
}

#pragma mark - Object Lifecycle

- (void)dealloc {
  [[SPJSessionController sharedController] removeObserver:self forKeyPath:@"playingMusic"];
  [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:SPJTrackDidChangeNotification];
}

@end
