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
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)recordButtonPressed:(id)sender {
  [[SPJSessionController sharedController] startRecordingSession];
}

@end
