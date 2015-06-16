/*
 * AudioHijack.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class AudioHijackApplication, AudioHijackDocument, AudioHijackWindow, AudioHijackApplication, AudioHijackBrowserWindow, AudioHijackSession, AudioHijackApplicationSession, AudioHijackAudioDeviceSession, AudioHijackRadioDeviceSession, AudioHijackSystemAudioSession, AudioHijackTimer, AudioHijackAudioDevice, AudioHijackAudioInput, AudioHijackAudioOutput, AudioHijackAudioRecording;

enum AudioHijackSaveOptions {
	AudioHijackSaveOptionsYes = 'yes ' /* Save the file. */,
	AudioHijackSaveOptionsNo = 'no  ' /* Do not save the file. */,
	AudioHijackSaveOptionsAsk = 'ask ' /* Ask the user whether or not to save the file. */
};
typedef enum AudioHijackSaveOptions AudioHijackSaveOptions;

enum AudioHijackPrintingErrorHandling {
	AudioHijackPrintingErrorHandlingStandard = 'lwst' /* Standard PostScript error handling */,
	AudioHijackPrintingErrorHandlingDetailed = 'lwdt' /* print a detailed report of PostScript errors */
};
typedef enum AudioHijackPrintingErrorHandling AudioHijackPrintingErrorHandling;

enum AudioHijackRelaunchOptions {
	AudioHijackRelaunchOptionsYes = 'yes ' /* Relaunch the application being hijacked. */,
	AudioHijackRelaunchOptionsNo = 'no  ' /* Do not relaunch the application being hijacked. */,
	AudioHijackRelaunchOptionsAsk = 'ask ' /* Ask the user whether or not to relaunch the application being hijacked. */
};
typedef enum AudioHijackRelaunchOptions AudioHijackRelaunchOptions;

enum AudioHijackSilenceMonitorActions {
	AudioHijackSilenceMonitorActionsDoNothing = 'SMof' /*  */,
	AudioHijackSilenceMonitorActionsRemove = 'SMra' /*  */,
	AudioHijackSilenceMonitorActionsStop = 'SMsp' /*  */,
	AudioHijackSilenceMonitorActionsStartNewFile = 'SMsn' /*  */
};
typedef enum AudioHijackSilenceMonitorActions AudioHijackSilenceMonitorActions;

enum AudioHijackFileAndRecordingLimitUnits {
	AudioHijackFileAndRecordingLimitUnitsGB = 'GB  ' /*  */,
	AudioHijackFileAndRecordingLimitUnitsMB = 'MB  ' /*  */,
	AudioHijackFileAndRecordingLimitUnitsHr = 'Hour' /*  */,
	AudioHijackFileAndRecordingLimitUnitsMin = 'Min ' /*  */
};
typedef enum AudioHijackFileAndRecordingLimitUnits AudioHijackFileAndRecordingLimitUnits;

enum AudioHijackAudioEncodings {
	AudioHijackAudioEncodingsMP3 = 'MP3 ' /*  */,
	AudioHijackAudioEncodingsAAC = 'AAC ' /*  */,
	AudioHijackAudioEncodingsAppleLossless = 'ALAC' /*  */,
	AudioHijackAudioEncodingsAIFF = 'AIFF' /*  */,
	AudioHijackAudioEncodingsWAV = 'WAV ' /*  */
};
typedef enum AudioHijackAudioEncodings AudioHijackAudioEncodings;

enum AudioHijackEncodingStyles {
	AudioHijackEncodingStylesCBR = 'CBR ' /*  */,
	AudioHijackEncodingStylesVBR = 'VBR ' /*  */,
	AudioHijackEncodingStylesABR = 'ABR ' /*  */,
	AudioHijackEncodingStylesNormal = 'Norm' /*  */,
	AudioHijackEncodingStylesBookmarkable = 'Book' /*  */,
	AudioHijackEncodingStylesSixteenBit = '16bt' /*  */,
	AudioHijackEncodingStylesTwentyFourBit = '24bt' /*  */
};
typedef enum AudioHijackEncodingStyles AudioHijackEncodingStyles;

enum AudioHijackAudioChannels {
	AudioHijackAudioChannelsStereo = 'Ster' /*  */,
	AudioHijackAudioChannelsJointStereo = 'JSte' /*  */,
	AudioHijackAudioChannelsMono = 'Mono' /*  */,
	AudioHijackAudioChannelsLeftMono = 'MonL' /*  */,
	AudioHijackAudioChannelsRightMono = 'MonR' /*  */
};
typedef enum AudioHijackAudioChannels AudioHijackAudioChannels;

enum AudioHijackTimerActions {
	AudioHijackTimerActionsActionRecord = 'Reco' /*  */,
	AudioHijackTimerActionsActionMute = 'Mute' /*  */,
	AudioHijackTimerActionsActionQuit = 'Quit' /*  */
};
typedef enum AudioHijackTimerActions AudioHijackTimerActions;



/*
 * Standard Suite
 */

// The application's top-level scripting object.
@interface AudioHijackApplication : SBApplication

- (SBElementArray *) documents;
- (SBElementArray *) windows;

@property (copy, readonly) NSString *name;  // The name of the application.
@property (readonly) BOOL frontmost;  // Is this the active application?
@property (copy, readonly) NSString *version;  // The version number of the application.

- (id) open:(id)x;  // Open a document.
- (void) print:(id)x withProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) quitSaving:(AudioHijackSaveOptions)saving;  // Quit the application.
- (BOOL) exists:(id)x;  // Verify that an object exists.

@end

// A document.
@interface AudioHijackDocument : SBObject

@property (copy, readonly) NSString *name;  // Its name.
@property (readonly) BOOL modified;  // Has it been modified since the last save?
@property (copy, readonly) NSURL *file;  // Its location on disk, if it has one.

- (void) closeSaving:(AudioHijackSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(id)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.

@end

// A window.
@interface AudioHijackWindow : SBObject

@property (copy, readonly) NSString *name;  // The title of the window.
- (NSInteger) id;  // The unique identifier of the window.
@property NSInteger index;  // The index of the window, ordered front to back.
@property NSRect bounds;  // The bounding rectangle of the window.
@property (readonly) BOOL closeable;  // Does the window have a close button?
@property (readonly) BOOL miniaturizable;  // Does the window have a minimize button?
@property BOOL miniaturized;  // Is the window minimized right now?
@property (readonly) BOOL resizable;  // Can the window be resized?
@property BOOL visible;  // Is the window visible right now?
@property (readonly) BOOL zoomable;  // Does the window have a zoom button?
@property BOOL zoomed;  // Is the window zoomed right now?
@property (copy, readonly) AudioHijackDocument *document;  // The document whose contents are displayed in the window.

- (void) closeSaving:(AudioHijackSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(id)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.

@end



/*
 * Audio Hijack Pro Suite
 */

// Audio Hijack Pro's top level scripting object
@interface AudioHijackApplication (AudioHijackProSuite)

- (SBElementArray *) browserWindows;
- (SBElementArray *) audioInputs;
- (SBElementArray *) audioOutputs;
- (SBElementArray *) sessions;
- (SBElementArray *) audioRecordings;

@end

// A browser window
@interface AudioHijackBrowserWindow : AudioHijackWindow

@property (copy) AudioHijackSession *selection;  // The selected session


@end

// A hijack session
@interface AudioHijackSession : SBObject

- (SBElementArray *) timers;

@property (readonly) BOOL hijacked;  // is the session currently hijacking the audio?
@property (readonly) double currentHijackingTime;  // current number of seconds of hijacked audio
@property (readonly) double currentRecordingTime;  // current number of seconds of recorded audio
@property (readonly) BOOL recording;  // is the session currently recording the audio?
@property BOOL speakerMuted;  // has the audio sent to the speaker been muted?
@property (readonly) BOOL paused;  // is recording currently paused?
- (NSString *) id;  // Unique ID for the object
@property (copy) NSString *name;  // Name of the session
@property (copy) NSString *albumTag;  // Album name with which to tag recordings
@property (copy) NSString *artistTag;  // Artist name with which to tag recordings
@property (copy) NSString *albumArtistTag;  // Album Artist with which to tag recordings
@property (copy) NSString *composerTag;  // Composer with which to tag recordings
@property (copy) NSString *commentTag;  // Comment with which to tag recordings
@property (copy) NSString *genreTag;  // Genre with which to tag recordings
@property (copy) NSString *trackNumberTag;  // Track number with which to tag recordings
@property (copy) NSString *trackCountTag;  // Track number count with which to tag recordings
@property (copy) NSString *titleTag;  // Title with which to tag recordings
@property (copy) NSString *yearTag;  // Year of recording with which to tag recordings
@property (copy) NSString *lyricsTag;  // Lyrics or Notes with which to tag recordings
@property (copy) NSString *groupingTag;  // Grouping identifier with which to tag recordings
@property (copy) NSString *discNumberTag;  // Disc number with which to tag recordings
@property (copy) NSString *discCountTag;  // Disc number count with which to tag recordings
@property (copy) NSString *bpmTag;  // BPM count with which to tag recordings
@property BOOL partOfCompilationTag;  // Tag for if the recording is part of a compilation
@property (copy) NSString *outputNameFormat;  // Format with which the output file should be saved
@property (copy) NSString *outputFolder;  // POSIX path to where to save recorded files
@property (copy) NSString *postRecordingScript;  // POSIX path to an applescript file to run once the recording has completed
@property (copy) NSDictionary *silenceMonitorAction;  // The action taken by the session when it detects silence
@property (copy) NSDictionary *fileSizeLimit;  // The maximum file size of a recording
@property (copy) NSDictionary *recordingTimeLimit;  // The total length of the recording
@property (copy) NSDictionary *recordingFormat;  // The recording format to use when hijacking and saving to a file

- (void) closeSaving:(AudioHijackSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(id)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.
- (void) startHijackingRelaunch:(AudioHijackRelaunchOptions)relaunch;  // Hijack the audio source associated with a session
- (void) stopHijacking;  // Stop the hijacking of the audio source associated with a session
- (void) startRecording;  // Begin recording the audio source
- (void) stopRecording;  // Stop recording the audio source
- (void) pauseRecording;  // Pause recording the audio source
- (void) unpauseRecording;  // Un-pause recording the audio source
- (void) splitRecording;  // Split the audio recording into a new file

@end

// A session hijacking an application's audio output
@interface AudioHijackApplicationSession : AudioHijackSession

@property (copy) NSString *targetedApplication;  // POSIX path to the application to use
@property (copy) NSString *launchArgument;  // POSIX path to a file or URL of a network resource to pass to the application when launched


@end

// A session using a specific audio device
@interface AudioHijackAudioDeviceSession : AudioHijackSession

@property (copy) AudioHijackAudioInput *inputDevice;  // The audio input
@property (copy) AudioHijackAudioOutput *outputDevice;  // The audio output


@end

// A session using a specific radio device
@interface AudioHijackRadioDeviceSession : AudioHijackSession

@property NSInteger frequency;  // The frequency tuned to, measured in Hertz. (Ex: 770 AM is 770000, 89.9 FM is 89900000)
@property (copy) AudioHijackAudioOutput *outputDevice;  // The audio output


@end

// A session using a system audio device
@interface AudioHijackSystemAudioSession : AudioHijackSession


@end

// A timer object
@interface AudioHijackTimer : SBObject

- (NSString *) id;  // Unique ID for the object
@property (readonly) BOOL active;  // is the timer currently running?
@property (readonly) BOOL scheduled;  // is the timer valid and scheduled to run?
@property BOOL enabled;  // is the timer scheduled to run?
@property (copy, readonly) NSDate *nextRunDate;  // The date and time the timer is next scheduled to run
@property (copy) NSDate *startTime;  // Date and time to start recording.
@property NSInteger duration;  // Number of seconds to record
@property BOOL runsSunday;  // The timer should run every Sunday of the week
@property BOOL runsMonday;  // The timer should run every Monday of the week
@property BOOL runsTuesday;  // The timer should run every Tuesday of the week
@property BOOL runsWednesday;  // The timer should run every Wednesday of the week
@property BOOL runsThursday;  // The timer should run every Thursday of the week
@property BOOL runsFriday;  // The timer should run every Friday of the week
@property BOOL runsSaturday;  // The timer should run every Saturday of the week
@property (copy) NSArray *actions;  // The list of actions to perform (record, mute, quit)

- (void) closeSaving:(AudioHijackSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(id)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.

@end

// An audio device connected to the machine
@interface AudioHijackAudioDevice : SBObject

@property (copy, readonly) NSString *name;  // The name of the audio device
- (NSString *) id;  // Unique ID for the object

- (void) closeSaving:(AudioHijackSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(id)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.

@end

// An audio input (i.e. line-in, microphone)
@interface AudioHijackAudioInput : AudioHijackAudioDevice


@end

// An audio output (i.e. line-out, speakers)
@interface AudioHijackAudioOutput : AudioHijackAudioDevice


@end

// A recorded sound file
@interface AudioHijackAudioRecording : SBObject

@property (copy, readonly) NSString *name;  // The name of the recording
@property (copy, readonly) NSString *path;  // The the POSIX path of the recording on disk.

- (void) closeSaving:(AudioHijackSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(id)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.

@end

