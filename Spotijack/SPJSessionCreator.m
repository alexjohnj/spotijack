// SPJSessionCreator.m
//
// Copyright (c) 2015 Alex Jackson
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

#import "SPJSessionCreator.h"

@implementation SPJSessionCreator

- (BOOL)attemptRecoveryFromError:(NSError *)error
                     optionIndex:(NSUInteger)recoveryOptionIndex {
  // Let's talk about what's going on here, 'cause it's kind'a weird. We create
  // a new AudioHijackApplicationSession as normal using the ScriptingBridge
  // framework. We're able to set the name of the session and the target
  // application using the ScriptingBridge framework BUT, after five hours of
  // fiddling, I have been unable to get the damn recordingProperties of the
  // session to update using the ScriptingBridge. I have tried:
  //  - Constructing a dictionary using the AppleScript names (with spaces) as
  //    per Audio Hijack's manual.
  //  - Constructing a dictionary using the AppleScript names converted to
  //    camelCase.
  //  - Constructing a dictionary using the AppleScript names with the values of
  //    the AudioHijackEncodingStyles, AudioHijackAudioChannels and
  //    AudioHijackAudioEncodings properties set using the enums in
  //    AudioHijack.h and an NSAppleEventDescriptor
  //
  // NONE of these worked. In the end, I've written a four line AppleScript
  // script and just executed that using the NSAppleScript API. If anyone knows
  // how to do this using ScriptingBridge, I'd LOVE to know.
  if (error.code == SPJAudioHijackSessionError && recoveryOptionIndex == NSAlertFirstButtonReturn) {
    NSURL *spotifyPath = [[NSWorkspace sharedWorkspace]
                          URLForApplicationWithBundleIdentifier:SPJSpotifyIdentifier];
    NSDictionary *sessionProperties = @{
                                        @"name": @"Spotijack",
                                        @"targetedApplication": spotifyPath.path
                                        };
    AudioHijackApplication *ahp = [[SPJSessionController sharedController] audioHijackApp];
    AudioHijackApplicationSession *newSession = [[[ahp classForScriptingClass:@"application session"]
                                                  alloc]
                                                 initWithProperties:sessionProperties];
    [ahp.sessions insertObject:newSession atIndex:0];
    
    NSDictionary *appleScriptInitError; // WHY does this API use dictionaries for errors?
    NSAppleScript *configScript = [[NSAppleScript alloc]
                                   initWithContentsOfURL:[[NSBundle mainBundle]
                                                          URLForResource:@"ConfigureSpotijackSession"
                                                          withExtension:@"applescript"]
                                   error:&appleScriptInitError];
    if (!configScript) {
      DDLogError(@"%@", appleScriptInitError);
    } else {
      NSDictionary *appleScriptExecuteError;
      NSAppleEventDescriptor *scriptResult = [configScript
                                              executeAndReturnError:&appleScriptExecuteError];
      if (!scriptResult) {
        DDLogError(@"%@", appleScriptExecuteError);
      }
    }
    
    NSError *newAttemptError;
    BOOL success = [[SPJSessionController sharedController]
                    initializeRecordingSession:&newAttemptError];
    if (!success) {
      DDLogError(@"%@", newAttemptError.localizedDescription);
    } else {
      [[NSNotificationCenter defaultCenter]
       postNotificationName:SPJSessionCreatedNotification object:self];
    }
    return success;
  }
  return NO;
}

@end
