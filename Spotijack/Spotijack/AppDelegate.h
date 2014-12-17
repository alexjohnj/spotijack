//
//  AppDelegate.h
//  Spotijack
//
//  Created by Alex Jackson on 17/12/2014.
//  Copyright (c) 2014 Alex Jackson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SPJSessionController.h"
#import "SPJMainWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong) SPJMainWindowController *mainWindowController;

@end

