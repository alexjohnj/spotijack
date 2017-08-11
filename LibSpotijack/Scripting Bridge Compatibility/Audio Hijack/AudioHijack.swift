import AppKit
import ScriptingBridge

// MARK: AudioHijackSaveOptions
@objc public enum AudioHijackSaveOptions : AEKeyword {
    case yes = 0x79657320 /* 'yes ' */
    case no = 0x6e6f2020 /* 'no  ' */
    case ask = 0x61736b20 /* 'ask ' */
}

// MARK: AudioHijackPrintingErrorHandling
@objc public enum AudioHijackPrintingErrorHandling : AEKeyword {
    case standard = 0x6c777374 /* 'lwst' */
    case detailed = 0x6c776474 /* 'lwdt' */
}

// MARK: AudioHijackRelaunchOptions
@objc public enum AudioHijackRelaunchOptions : AEKeyword {
    case yes = 0x79657320 /* 'yes ' */
    case no = 0x6e6f2020 /* 'no  ' */
    case ask = 0x61736b20 /* 'ask ' */
}

// MARK: AudioHijackSilenceMonitorActions
@objc public enum AudioHijackSilenceMonitorActions : AEKeyword {
    case doNothing = 0x534d6f66 /* 'SMof' */
    case remove = 0x534d7261 /* 'SMra' */
    case stop = 0x534d7370 /* 'SMsp' */
    case startNewFile = 0x534d736e /* 'SMsn' */
}

// MARK: AudioHijackFileAndRecordingLimitUnits
@objc public enum AudioHijackFileAndRecordingLimitUnits : AEKeyword {
    case gb = 0x47422020 /* 'GB  ' */
    case mb = 0x4d422020 /* 'MB  ' */
    case hr = 0x486f7572 /* 'Hour' */
    case min = 0x4d696e20 /* 'Min ' */
}

// MARK: AudioHijackAudioEncodings
@objc public enum AudioHijackAudioEncodings : AEKeyword {
    case mp3 = 0x4d503320 /* 'MP3 ' */
    case aac = 0x41414320 /* 'AAC ' */
    case appleLossless = 0x414c4143 /* 'ALAC' */
    case aiff = 0x41494646 /* 'AIFF' */
    case wav = 0x57415620 /* 'WAV ' */
}

// MARK: AudioHijackEncodingStyles
@objc public enum AudioHijackEncodingStyles : AEKeyword {
    case cbr = 0x43425220 /* 'CBR ' */
    case vbr = 0x56425220 /* 'VBR ' */
    case abr = 0x41425220 /* 'ABR ' */
    case normal = 0x4e6f726d /* 'Norm' */
    case bookmarkable = 0x426f6f6b /* 'Book' */
    case sixteenBit = 0x31366274 /* '16bt' */
    case twentyFourBit = 0x32346274 /* '24bt' */
}

// MARK: AudioHijackAudioChannels
@objc public enum AudioHijackAudioChannels : AEKeyword {
    case stereo = 0x53746572 /* 'Ster' */
    case jointStereo = 0x4a537465 /* 'JSte' */
    case mono = 0x4d6f6e6f /* 'Mono' */
    case leftMono = 0x4d6f6e4c /* 'MonL' */
    case rightMono = 0x4d6f6e52 /* 'MonR' */
}

// MARK: AudioHijackTimerActions
@objc public enum AudioHijackTimerActions : AEKeyword {
    case actionRecord = 0x5265636f /* 'Reco' */
    case actionMute = 0x4d757465 /* 'Mute' */
    case actionQuit = 0x51756974 /* 'Quit' */
}

// MARK: AudioHijackGenericMethods
@objc public protocol AudioHijackGenericMethods {
    @objc optional func closeSaving(_ saving: AudioHijackSaveOptions, savingIn: URL!) // Close a document.
    @objc optional func saveIn(_ in_: URL!, as: Any!) // Save a document.
    @objc optional func printWithProperties(_ withProperties: [AnyHashable : Any]!, printDialog: Bool) // Print a document.
    @objc optional func delete() // Delete an object.
    @objc optional func duplicateTo(_ to: SBObject!, withProperties: [AnyHashable : Any]!) // Copy an object.
    @objc optional func moveTo(_ to: SBObject!) // Move an object to a new location.
}

// MARK: AudioHijackApplication
@objc public protocol AudioHijackApplication: SBApplicationProtocol {
    @objc optional func documents() -> SBElementArray
    @objc optional func windows() -> SBElementArray
    @objc optional var name: String { get } // The name of the application.
    @objc optional var frontmost: Bool { get } // Is this the active application?
    @objc optional var version: String { get } // The version number of the application.
    @objc optional func `open`(_ x: Any!) -> Any // Open a document.
    @objc optional func print(_ x: Any!, withProperties: [AnyHashable : Any]!, printDialog: Bool) // Print a document.
    @objc optional func quitSaving(_ saving: AudioHijackSaveOptions) // Quit the application.
    @objc optional func exists(_ x: Any!) -> Bool // Verify that an object exists.
    @objc optional func browserWindows() -> SBElementArray
    @objc optional func audioInputs() -> SBElementArray
    @objc optional func audioOutputs() -> SBElementArray
    @objc optional func sessions() -> [AudioHijackApplicationSession]
    @objc optional func audioRecordings() -> [AudioHijackAudioRecording]
}
extension SBApplication: AudioHijackApplication {}

// MARK: AudioHijackDocument
@objc public protocol AudioHijackDocument: SBObjectProtocol, AudioHijackGenericMethods {
    @objc optional var name: String { get } // Its name.
    @objc optional var modified: Bool { get } // Has it been modified since the last save?
    @objc optional var file: URL { get } // Its location on disk, if it has one.
}
extension SBObject: AudioHijackDocument {}

// MARK: AudioHijackWindow
@objc public protocol AudioHijackWindow: SBObjectProtocol, AudioHijackGenericMethods {
    @objc optional var name: String { get } // The title of the window.
    @objc optional func id() -> Int // The unique identifier of the window.
    @objc optional var index: Int { get } // The index of the window, ordered front to back.
    @objc optional var bounds: NSRect { get } // The bounding rectangle of the window.
    @objc optional var closeable: Bool { get } // Does the window have a close button?
    @objc optional var miniaturizable: Bool { get } // Does the window have a minimize button?
    @objc optional var miniaturized: Bool { get } // Is the window minimized right now?
    @objc optional var resizable: Bool { get } // Can the window be resized?
    @objc optional var visible: Bool { get } // Is the window visible right now?
    @objc optional var zoomable: Bool { get } // Does the window have a zoom button?
    @objc optional var zoomed: Bool { get } // Is the window zoomed right now?
    @objc optional var document: AudioHijackDocument { get } // The document whose contents are displayed in the window.
    @objc optional func setIndex(_ index: Int) // The index of the window, ordered front to back.
    @objc optional func setBounds(_ bounds: NSRect) // The bounding rectangle of the window.
    @objc optional func setMiniaturized(_ miniaturized: Bool) // Is the window minimized right now?
    @objc optional func setVisible(_ visible: Bool) // Is the window visible right now?
    @objc optional func setZoomed(_ zoomed: Bool) // Is the window zoomed right now?
}
extension SBObject: AudioHijackWindow {}

// MARK: AudioHijackBrowserWindow
@objc public protocol AudioHijackBrowserWindow: AudioHijackWindow {
    @objc optional var selection: AudioHijackSession { get } // The selected session
    @objc optional func setSelection(_ selection: AudioHijackSession!) // The selected session
}
extension SBObject: AudioHijackBrowserWindow {}

// MARK: AudioHijackSession
@objc public protocol AudioHijackSession: SBObjectProtocol, AudioHijackGenericMethods {
    @objc optional func timers() -> SBElementArray
    @objc optional var hijacked: Bool { get } // is the session currently hijacking the audio?
    @objc optional var currentHijackingTime: Double { get } // current number of seconds of hijacked audio
    @objc optional var currentRecordingTime: Double { get } // current number of seconds of recorded audio
    @objc optional var recording: Bool { get } // is the session currently recording the audio?
    @objc optional var speakerMuted: Bool { get } // has the audio sent to the speaker been muted?
    @objc optional var paused: Bool { get } // is recording currently paused?
    @objc optional func id() -> String // Unique ID for the object
    @objc optional var name: String { get } // Name of the session
    @objc optional var albumTag: String { get } // Album name with which to tag recordings
    @objc optional var artistTag: String { get } // Artist name with which to tag recordings
    @objc optional var albumArtistTag: String { get } // Album Artist with which to tag recordings
    @objc optional var composerTag: String { get } // Composer with which to tag recordings
    @objc optional var commentTag: String { get } // Comment with which to tag recordings
    @objc optional var genreTag: String { get } // Genre with which to tag recordings
    @objc optional var trackNumberTag: String { get } // Track number with which to tag recordings
    @objc optional var trackCountTag: String { get } // Track number count with which to tag recordings
    @objc optional var titleTag: String { get } // Title with which to tag recordings
    @objc optional var yearTag: String { get } // Year of recording with which to tag recordings
    @objc optional var lyricsTag: String { get } // Lyrics or Notes with which to tag recordings
    @objc optional var groupingTag: String { get } // Grouping identifier with which to tag recordings
    @objc optional var discNumberTag: String { get } // Disc number with which to tag recordings
    @objc optional var discCountTag: String { get } // Disc number count with which to tag recordings
    @objc optional var bpmTag: String { get } // BPM count with which to tag recordings
    @objc optional var partOfCompilationTag: Bool { get } // Tag for if the recording is part of a compilation
    @objc optional var outputNameFormat: String { get } // Format with which the output file should be saved
    @objc optional var outputFolder: String { get } // POSIX path to where to save recorded files
    @objc optional var postRecordingScript: String { get } // POSIX path to an applescript file to run once the recording has completed
    @objc optional var silenceMonitorAction: [AnyHashable : Any] { get } // The action taken by the session when it detects silence
    @objc optional var fileSizeLimit: [AnyHashable : Any] { get } // The maximum file size of a recording
    @objc optional var recordingTimeLimit: [AnyHashable : Any] { get } // The total length of the recording
    @objc optional var recordingFormat: [AnyHashable : Any] { get } // The recording format to use when hijacking and saving to a file
    @objc optional func startHijackingRelaunch(_ relaunch: AudioHijackRelaunchOptions) // Hijack the audio source associated with a session
    @objc optional func stopHijacking() // Stop the hijacking of the audio source associated with a session
    @objc optional func startRecording() // Begin recording the audio source
    @objc optional func stopRecording() // Stop recording the audio source
    @objc optional func pauseRecording() // Pause recording the audio source
    @objc optional func unpauseRecording() // Un-pause recording the audio source
    @objc optional func splitRecording() // Split the audio recording into a new file
    @objc optional func setSpeakerMuted(_ speakerMuted: Bool) // has the audio sent to the speaker been muted?
    @objc optional func setName(_ name: String!) // Name of the session
    @objc optional func setAlbumTag(_ albumTag: String!) // Album name with which to tag recordings
    @objc optional func setArtistTag(_ artistTag: String!) // Artist name with which to tag recordings
    @objc optional func setAlbumArtistTag(_ albumArtistTag: String!) // Album Artist with which to tag recordings
    @objc optional func setComposerTag(_ composerTag: String!) // Composer with which to tag recordings
    @objc optional func setCommentTag(_ commentTag: String!) // Comment with which to tag recordings
    @objc optional func setGenreTag(_ genreTag: String!) // Genre with which to tag recordings
    @objc optional func setTrackNumberTag(_ trackNumberTag: String!) // Track number with which to tag recordings
    @objc optional func setTrackCountTag(_ trackCountTag: String!) // Track number count with which to tag recordings
    @objc optional func setTitleTag(_ titleTag: String!) // Title with which to tag recordings
    @objc optional func setYearTag(_ yearTag: String!) // Year of recording with which to tag recordings
    @objc optional func setLyricsTag(_ lyricsTag: String!) // Lyrics or Notes with which to tag recordings
    @objc optional func setGroupingTag(_ groupingTag: String!) // Grouping identifier with which to tag recordings
    @objc optional func setDiscNumberTag(_ discNumberTag: String!) // Disc number with which to tag recordings
    @objc optional func setDiscCountTag(_ discCountTag: String!) // Disc number count with which to tag recordings
    @objc optional func setBpmTag(_ bpmTag: String!) // BPM count with which to tag recordings
    @objc optional func setPartOfCompilationTag(_ partOfCompilationTag: Bool) // Tag for if the recording is part of a compilation
    @objc optional func setOutputNameFormat(_ outputNameFormat: String!) // Format with which the output file should be saved
    @objc optional func setOutputFolder(_ outputFolder: String!) // POSIX path to where to save recorded files
    @objc optional func setPostRecordingScript(_ postRecordingScript: String!) // POSIX path to an applescript file to run once the recording has completed
    @objc optional func setSilenceMonitorAction(_ silenceMonitorAction: [AnyHashable : Any]!) // The action taken by the session when it detects silence
    @objc optional func setFileSizeLimit(_ fileSizeLimit: [AnyHashable : Any]!) // The maximum file size of a recording
    @objc optional func setRecordingTimeLimit(_ recordingTimeLimit: [AnyHashable : Any]!) // The total length of the recording
    @objc optional func setRecordingFormat(_ recordingFormat: [AnyHashable : Any]!) // The recording format to use when hijacking and saving to a file
}
extension SBObject: AudioHijackSession {}

// MARK: AudioHijackApplicationSession
@objc public protocol AudioHijackApplicationSession: AudioHijackSession {
    @objc optional var targetedApplication: String { get } // POSIX path to the application to use
    @objc optional var launchArgument: String { get } // POSIX path to a file or URL of a network resource to pass to the application when launched
    @objc optional func setTargetedApplication(_ targetedApplication: String!) // POSIX path to the application to use
    @objc optional func setLaunchArgument(_ launchArgument: String!) // POSIX path to a file or URL of a network resource to pass to the application when launched
}
extension SBObject: AudioHijackApplicationSession {}

// MARK: AudioHijackAudioDeviceSession
@objc public protocol AudioHijackAudioDeviceSession: AudioHijackSession {
    @objc optional var inputDevice: AudioHijackAudioInput { get } // The audio input
    @objc optional var outputDevice: AudioHijackAudioOutput { get } // The audio output
    @objc optional func setInputDevice(_ inputDevice: AudioHijackAudioInput!) // The audio input
    @objc optional func setOutputDevice(_ outputDevice: AudioHijackAudioOutput!) // The audio output
}
extension SBObject: AudioHijackAudioDeviceSession {}

// MARK: AudioHijackRadioDeviceSession
@objc public protocol AudioHijackRadioDeviceSession: AudioHijackSession {
    @objc optional var frequency: Int { get } // The frequency tuned to, measured in Hertz. (Ex: 770 AM is 770000, 89.9 FM is 89900000)
    @objc optional var outputDevice: AudioHijackAudioOutput { get } // The audio output
    @objc optional func setFrequency(_ frequency: Int) // The frequency tuned to, measured in Hertz. (Ex: 770 AM is 770000, 89.9 FM is 89900000)
    @objc optional func setOutputDevice(_ outputDevice: AudioHijackAudioOutput!) // The audio output
}
extension SBObject: AudioHijackRadioDeviceSession {}

// MARK: AudioHijackSystemAudioSession
@objc public protocol AudioHijackSystemAudioSession: AudioHijackSession {
}
extension SBObject: AudioHijackSystemAudioSession {}

// MARK: AudioHijackTimer
@objc public protocol AudioHijackTimer: SBObjectProtocol, AudioHijackGenericMethods {
    @objc optional func id() -> String // Unique ID for the object
    @objc optional var active: Bool { get } // is the timer currently running?
    @objc optional var scheduled: Bool { get } // is the timer valid and scheduled to run?
    @objc optional var enabled: Bool { get } // is the timer scheduled to run?
    @objc optional var nextRunDate: Date { get } // The date and time the timer is next scheduled to run
    @objc optional var startTime: Date { get } // Date and time to start recording.
    @objc optional var duration: Int { get } // Number of seconds to record
    @objc optional var runsSunday: Bool { get } // The timer should run every Sunday of the week
    @objc optional var runsMonday: Bool { get } // The timer should run every Monday of the week
    @objc optional var runsTuesday: Bool { get } // The timer should run every Tuesday of the week
    @objc optional var runsWednesday: Bool { get } // The timer should run every Wednesday of the week
    @objc optional var runsThursday: Bool { get } // The timer should run every Thursday of the week
    @objc optional var runsFriday: Bool { get } // The timer should run every Friday of the week
    @objc optional var runsSaturday: Bool { get } // The timer should run every Saturday of the week
    @objc optional var actions: [NSAppleEventDescriptor] { get } // The list of actions to perform (record, mute, quit)
    @objc optional func setEnabled(_ enabled: Bool) // is the timer scheduled to run?
    @objc optional func setStartTime(_ startTime: Date!) // Date and time to start recording.
    @objc optional func setDuration(_ duration: Int) // Number of seconds to record
    @objc optional func setRunsSunday(_ runsSunday: Bool) // The timer should run every Sunday of the week
    @objc optional func setRunsMonday(_ runsMonday: Bool) // The timer should run every Monday of the week
    @objc optional func setRunsTuesday(_ runsTuesday: Bool) // The timer should run every Tuesday of the week
    @objc optional func setRunsWednesday(_ runsWednesday: Bool) // The timer should run every Wednesday of the week
    @objc optional func setRunsThursday(_ runsThursday: Bool) // The timer should run every Thursday of the week
    @objc optional func setRunsFriday(_ runsFriday: Bool) // The timer should run every Friday of the week
    @objc optional func setRunsSaturday(_ runsSaturday: Bool) // The timer should run every Saturday of the week
    @objc optional func setActions(_ actions: [NSAppleEventDescriptor]!) // The list of actions to perform (record, mute, quit)
}
extension SBObject: AudioHijackTimer {}

// MARK: AudioHijackAudioDevice
@objc public protocol AudioHijackAudioDevice: SBObjectProtocol, AudioHijackGenericMethods {
    @objc optional var name: String { get } // The name of the audio device
    @objc optional func id() -> String // Unique ID for the object
}
extension SBObject: AudioHijackAudioDevice {}

// MARK: AudioHijackAudioInput
@objc public protocol AudioHijackAudioInput: AudioHijackAudioDevice {
}
extension SBObject: AudioHijackAudioInput {}

// MARK: AudioHijackAudioOutput
@objc public protocol AudioHijackAudioOutput: AudioHijackAudioDevice {
}
extension SBObject: AudioHijackAudioOutput {}

// MARK: AudioHijackAudioRecording
@objc public protocol AudioHijackAudioRecording: SBObjectProtocol, AudioHijackGenericMethods {
    @objc optional var name: String { get } // The name of the recording
    @objc optional var path: String { get } // The the POSIX path of the recording on disk.
}
extension SBObject: AudioHijackAudioRecording {}

