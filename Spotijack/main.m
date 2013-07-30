//
//  main.m
//  Spotijack
//
//  Created by Alex Jackson on 29/07/2013.
//  Copyright (c) 2013 Alex Jackson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <AppleScriptObjC/AppleScriptObjC.h>

int main(int argc, char *argv[])
{
    [[NSBundle mainBundle] loadAppleScriptObjectiveCScripts];
    return NSApplicationMain(argc, (const char **)argv);
}
