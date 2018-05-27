//swiftlint:disable file_length
//
//  SpotijackSession.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 2017-08-02.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Cocoa
import ScriptingBridge
import Result
import TypedNotification

//swiftlint:disable type_body_length
/// `SpotijackSessionManager` coordinates a Spotijack recording session. It maintains a scripting bridge to Spotify,
/// Audio Hijack Pro and a recording session named "Spotijack" in Audio Hijack Pro. The session manager is responsible
/// for polling the applications and starting new recordings when the track changes in Spotify.
///
/// # Creation
///
/// `SpotijackSessionManager` can be used as a singleton (recommended) or an instance. The singleton is accessed via
/// the throwing `shared()` method which will launch and establish a scripting interface to Spotify and Audio Hijack
/// Pro. A new instance is created using the `init(spotifyBridge:audioHijackBridge:notificationCenter:)` method which
/// takes pre-established scripting interfaces as its arguments. This method is provided for the rare case where there
/// are multiple instances of Spotify and Audio Hijack Pro launched (and tests).
///
/// # Usage
///
/// For a new instance of `SpotijackSessionManager`, polling will be disabled. Use `startPolling(every:)` to start
/// polling at a given interval. Add observers to the manager's `notificationCenter` property to be notified of when
/// various aspects of the applications change.
///
/// When polling is enabled, changing the track in Spotify **will not** start a new recording. You must start
/// _Spotijacking_ using the `startSpotijacking(config:)` method do this. This method takes a
/// `SpotijackSessionManager.RecordingConfiguration` object which, amongst things, tells the session manager how
/// frequently to poll while Spotijacking. You can end Spotijacking using the `stopSpotijacking()` method.
///
/// ## Automatic Spotijacking Ending
///
/// Spotijacking will be automatically ended under a few circumstances:
///
/// - When the session manager encounters an error.
/// - When there are no more songs to play in Spotify.
/// - If the recording is ended by Audio Hijack Pro.
///
/// ## Errors
///
/// Most errors should be caught when using the throwing `shared()` method. However, an error could be encountered
/// while polling. Users should observe for the `DidEncounterError` notification which is posted if an error is
/// encoutered when polling.
public final class SpotijackSessionManager {
    // MARK: - Singleton
    private static var _shared: SpotijackSessionManager!
    /// The shared session manager instance. Will attempt to launch Spotify and Audio Hijack Pro if they haven't been
    /// launched. Will throw if the applications can not be launched or a scripting bridge can't be established.
    public static func shared() throws -> SpotijackSessionManager {
        if _shared == nil {
            _shared = try SpotijackSessionManager()
        }

        return _shared
    }

    // MARK: - Properties General
    public var notificationCenter: TypedNotificationCenter

    // MARK: - Properties - Application Bridges
    internal let spotifyBridge: SpotifyApplication
    internal let audioHijackBridge: AudioHijackApplication

    /// A scripting bridge interface to the Spotijack session in Audio Hijack Pro.
    /// Accessing this property will make Audio Hijack Pro start hijacking Spotify.
    internal var spotijackSessionBridge: Result<AudioHijackApplicationSession> {
        switch getFirstSpotijackSession() {
        case .ok(let session):
            session.startHijackingRelaunch!(.yes)
            return .ok(session)
        case .fail(let error):
            notificationCenter.post(DidEncounterError(sender: self, error: error))
            return .fail(error)
        }
    }

    /// Gets the first session called "Spotijack" reported by Audio Hijack Pro.
    private func getFirstSpotijackSession() -> Result<AudioHijackApplicationSession> {
        let sessions = audioHijackBridge.sessions!()

        if let session = sessions.first(where: { $0.name == "Spotijack" }) {
            return .ok(session)
        } else {
            return .fail(SpotijackError.SpotijackSessionNotFound())
        }
    }

    // MARK: - Properties - State
    // Internal mute state used to track changes. Does not affect the actual mute
    // state in AHP.
    private var _isMuted: Bool = false {
        didSet {
            if _isMuted != oldValue {
                notificationCenter.post(MuteStateDidChange(sender: self, newMuteState: _isMuted))
            }
        }
    }

    /// Queries Audio Hijack Pro to determine if the Spotijack session is muted.
    /// Returns false and posts a `DidEncounterError` notification if Audio
    /// Hijack Pro can not be queried.
    public var isMuted: Bool {
        // Setting this property updates the internal mute state and AHP.
        // Accessing it does not change the internal mute state.
        get {
            switch spotijackSessionBridge.map({ $0.speakerMuted! }) {
            case .ok(let status):
                return status
            case .fail(let error):
                notificationCenter.post(DidEncounterError(sender: self, error: error))
                return false
            }
        }

        set {
            let result = spotijackSessionBridge.map { session in
                session.setSpeakerMuted!(newValue)
            }

            switch result {
            case .ok:
                _isMuted = newValue
            case .fail(let error):
                notificationCenter.post(DidEncounterError(sender: self, error: error))
            }
        }
    }

    /// Is recording temporarily disabled by Spotijack while starting a new recording?
    private var _isRecordingTempDisabled = false

    private var _isRecording = false {
        didSet {
            if _isRecording != oldValue {
                notificationCenter.post(RecordingStateDidChange(sender: self, isRecording: _isRecording))
            }

            // Test if recording was ended via AHP while Spotijacking
            if  isSpotijacking == true,
                _isRecording == false,
                _isRecordingTempDisabled == false {
                stopSpotijacking()
            }
        }
    }
    /// Queries AHP to determine if the Spotijack session is recording. Returns
    /// false and posts a `DidEncounterError` message if AHP can not be queried.
    public var isRecording: Bool {
        get {
            switch spotijackSessionBridge.map({ $0.recording! }) {
            case .ok(let status):
                return status
            case .fail(let error):
                notificationCenter.post(DidEncounterError(sender: self, error: error))
                return false
            }
        }

        set {
            let result = spotijackSessionBridge.map { session in
                newValue ? session.startRecording!() : session.stopRecording!()
            }

            switch result {
            case .ok:
                _isRecording = newValue
            case .fail(let error):
                notificationCenter.post(DidEncounterError(sender: self, error: error))
            }
        }
    }

    private var _currentTrack: StaticSpotifyTrack? = nil {
        didSet {
            // First see if we've reached the end of Spotify's playback queue.
            // This isn't a definitive way of checking the queue but it should
            // work most of the time.
            if  _currentTrack != oldValue,
                isSpotijacking == true,
                case .paused = spotifyBridge.playerState!,
                spotifyBridge.playerPosition == 0.0 {

                stopSpotijacking()
                notificationCenter.post(TrackDidChange(sender: self, newTrack: _currentTrack))
                notificationCenter.post(DidReachEndOfPlaybackQueue(sender: self))

                return
            }

            if _currentTrack != oldValue {
                notificationCenter.post(TrackDidChange(sender: self, newTrack: _currentTrack))
            }

            // Start a new recording if Spotijack is controlling the current
            // recording session.
            if _currentTrack != oldValue,
                isSpotijacking == true {
                do {
                    try startNewRecording()
                } catch {
                    notificationCenter.post(DidEncounterError(sender: self, error: error))
                }
            }
        }
    }

    /// Returns the currently playing track in Spotify. Can return `nil` if no
    /// track is playing or if Spotify can not be accessed. For the latter, a
    /// `DidEncounterError` notification is also posted.
    public var currentTrack: StaticSpotifyTrack? {
        if let track = spotifyBridge.currentTrack {
            return StaticSpotifyTrack(from: track)
        } else {
            return nil
        }
    }

    internal var _applicationPollingTimer: Timer?
    private var activityToken: NSObjectProtocol?
    /// The recording configuration used for the current Spotijack session or `nil` if not Spotijacking
    internal var _currentRecordingConfiguration: RecordingConfiguration?

    /// Returns `true` if SpotijackSessionManager is polling Spotify and AHP.
    public var isPolling: Bool { return _applicationPollingTimer?.isValid ?? false }

    /// Returns `true` if SpotijackSessionManager is actively controlling recording.
    public private(set) var isSpotijacking: Bool = false

    /// Interval we were polling applications at _before_ starting Spotijacking.
    private var _pastPollingInterval: TimeInterval?

    // MARK: - Lifecycle
    public init(spotifyBridge: SpotifyApplication, audioHijackBridge: AudioHijackApplication,
                notificationCenter: TypedNotificationCenter = NotificationCenter.default) {
        self.spotifyBridge = spotifyBridge
        self.audioHijackBridge = audioHijackBridge
        self.notificationCenter = notificationCenter
    }

    private convenience init() throws {
        let launchOptions: NSWorkspace.LaunchOptions = [.withoutActivation, .andHide]
        let isAHPLaunched = NSWorkspace.shared.launchApplication(
            withBundleIdentifier: Constants.audioHijackBundle.identifier,
            options: launchOptions,
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil
        )

        let isSpotifyLaunched = NSWorkspace.shared.launchApplication(
            withBundleIdentifier: Constants.spotifyBundle.identifier,
            options: launchOptions,
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil
        )

        guard isAHPLaunched == true else {
            throw SpotijackError.CantStartApplication(appName: Constants.spotifyBundle.name)
        }

        guard isSpotifyLaunched == true else {
            throw SpotijackError.CantStartApplication(appName: Constants.audioHijackBundle.name)
        }

        guard let ahpBridge = SBApplication(bundleIdentifier: Constants.audioHijackBundle.identifier) else {
            throw SpotijackError.NoScriptingInterface(appName: Constants.audioHijackBundle.name)
        }

        guard let spotifyBridge = SBApplication(bundleIdentifier: Constants.spotifyBundle.identifier) else {
            throw SpotijackError.NoScriptingInterface(appName: Constants.spotifyBundle.name)
        }

        self.init(spotifyBridge: spotifyBridge, audioHijackBridge: ahpBridge)
    }

    // MARK: - Application Polling
    /// Starts polling Spotify and AHP for changes. Polling is stopped when
    /// `stopPolling()` is called or if `SpotijackSessionManager` encounters an
    /// error.
    ///
    /// Calling this method when `SpotijackSessionManager` is already polling will
    /// have no effect.
    public func startPolling(every interval: TimeInterval) {
        guard isPolling == false else {
            return
        }

        _applicationPollingTimer = Timer.scheduledTimer(timeInterval: interval, target: self,
                                                        selector: #selector(applicationPollingTimerFired(timer:)),
                                                        userInfo: nil,
                                                        repeats: true)
        _applicationPollingTimer?.fire()
    }

    /// Stops polling Spotify and AHP for changes.
    ///
    /// Calling this method when `SpotijackSessionManager` isn't already polling
    /// will have no effect.
    public func stopPolling() {
        guard isPolling == true else {
            return
        }

        _applicationPollingTimer?.invalidate()
        _applicationPollingTimer = nil
    }

    @objc private func applicationPollingTimerFired(timer: Timer) {
        pollSpotify()
        pollAudioHijackPro()
    }

    // Synchronise the internal Spotify state
    internal func pollSpotify() {
        _currentTrack = currentTrack
    }

    // Synchronise the internal AHP state
    internal func pollAudioHijackPro() {
        _isRecording = isRecording
        _isMuted = isMuted
    }

    // MARK: - Spotijacking
    /// Start a Spotijack recording session. Calling this method when a recording
    /// session is already in progress has no effect. Polling will be restarted
    /// at the interval specified in `config`.
    public func startSpotijacking(config: RecordingConfiguration) throws {
        guard isSpotijacking == false else {
            return
        }

        // Set up recording configuration
        if config.disableRepeat {
            spotifyBridge.setRepeating!(false)
        }

        if config.disableShuffling {
            spotifyBridge.setShuffling!(false)
        }

        if config.muteSpotify {
            try spotijackSessionBridge.dematerialize().setSpeakerMuted!(true)
        }

        if isPolling {
            _pastPollingInterval = _applicationPollingTimer?.timeInterval
            stopPolling()
        }

        startPolling(every: config.pollingInterval)
        isSpotijacking = true
        activityToken = ProcessInfo.processInfo.beginActivity(options: [.userInitiated, .idleSystemSleepDisabled],
                                                              reason: "Spotijacking")
        _currentRecordingConfiguration = config

        do {
            try startNewRecording()
        } catch {
            stopSpotijacking()
            throw error
        }
    }

    /// Stops a Spotijack recording session. Calling this method when no recording
    /// session is in progress has no effect. If we were polling when Spotijacking
    /// started, we'll resume polling at that interval.
    public func stopSpotijacking() {
        guard isSpotijacking == true else {
            return
        }

        isSpotijacking = false

        _isRecordingTempDisabled = false
        isRecording = false
        _currentRecordingConfiguration = nil

        if let activityToken = activityToken {
            ProcessInfo.processInfo.endActivity(activityToken)
            self.activityToken = nil
        }

        if let pastPollingInterval = _pastPollingInterval {
            stopPolling()
            startPolling(every: pastPollingInterval)
        } else {
            stopPolling()
        }

        notificationCenter.post(DidEndSpotijacking(sender: self))
    }

    /// Starts a new recording in AHP and resets Spotify's play position.
    /// If there is no new track, ends the current Spotijack session.
    private func startNewRecording() throws {
        // Check we can still communicate with the recording session
        let spotijackSessionBridge = try self.spotijackSessionBridge.dematerialize()

        // End the session if there are no more tracks
        guard let currentTrack = currentTrack else {
            stopSpotijacking()
            return
        }

        // Start a new recording
        _isRecordingTempDisabled = true
        isRecording = false
        spotifyBridge.pause!()
        spotifyBridge.setPlayerPosition!(0.0)
        spotijackSessionBridge.setMetadata(from: currentTrack)

        guard let delay = _currentRecordingConfiguration?.recordingStartDelay else {
            preconditionFailure("Current recording configuration not set for a Spotijack session")
        }

        let newRecordingBlock = { [weak self] in
            self?._isRecordingTempDisabled = false
            self?.isRecording = true
            self?.spotifyBridge.play!()
        }

        if delay == 0 {
            newRecordingBlock()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newRecordingBlock)
            return
        }
    }

    // Called when a `DidEncounterError` notification is posted. Ends polling and
    // any Spotijack controlled recording sessions that were running.
    private func didEncounterError(_ error: Error) {
        stopSpotijacking()
        stopPolling()
    }
}

// MARK: - RecordingConfiguration
public extension SpotijackSessionManager {
    public struct RecordingConfiguration {
        /// Should the Spotijack session be muted when starting Spotijacking?
        public let muteSpotify: Bool
        /// Should shuffling be disabled in Spotify when starting Spotijacking?
        public let disableShuffling: Bool
        /// Should repeat be disabled in Spotify when starting Spotijacking?
        public let disableRepeat: Bool
        /// Frequency we should poll Spotify and AHP when Spotijacking.
        public let pollingInterval: TimeInterval
        /// The pause Spotijack should make between a track ending and starting a new recording. Introducing this pause
        /// reduces the likelihood of the end of one track overlapping the start of the next but adds a short gap to the
        /// start of the recording. I recommend keeping this value around 0.1 seconds.
        public let recordingStartDelay: TimeInterval

        public init(muteSpotify: Bool = false, disableShuffling: Bool = false, disableRepeat: Bool = false,
                    pollingInterval: TimeInterval = 0.1, recordingStartDelay: TimeInterval = 0.1) {
            self.muteSpotify = muteSpotify
            self.disableShuffling = disableShuffling
            self.disableRepeat = disableRepeat
            self.pollingInterval = pollingInterval
            self.recordingStartDelay = recordingStartDelay
        }
    }
}
