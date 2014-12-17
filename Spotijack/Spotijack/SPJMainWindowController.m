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

- (void)windowDidLoad {
  [super windowDidLoad];
  [[SPJSessionController sharedController] addObserver:self
                                            forKeyPath:@"playingMusic"
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(trackChanged:)
                                               name:@"SPJTrackChanged"
                                             object:nil];
  // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)recordButtonPressed:(id)sender {
  if ([[SPJSessionController sharedController] playingMusic]) {
    [[SPJSessionController sharedController] stopRecordingSession];
  } else {
    [[SPJSessionController sharedController] startRecordingSession];
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqualToString:@"playingMusic"]) {
    if ([change[NSKeyValueChangeNewKey] isEqualTo:@YES]) {
      self.recordingButton.title = @"Recording";
    } else {
      self.recordingButton.title = @"Record";
    }
  }
}

- (void)trackChanged:(NSNotification *)notification {
  self.statusLabel.stringValue = notification.userInfo[@"TrackTitle"];
  self.artistLabel.stringValue = notification.userInfo[@"TrackArtist"];
}

@end
