//
//  SPJMainWindowController.h
//  Spotijack
//
//  Created by Alex Jackson on 17/12/2014.
//  Copyright (c) 2014 Alex Jackson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SPJSessionController.h"

@interface SPJMainWindowController : NSWindowController

@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSTextField *artistLabel;
@property (weak) IBOutlet NSButton *recordingButton;

- (IBAction)recordButtonPressed:(id)sender;

@end
