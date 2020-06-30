//
//  SpotijackSession.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 2017-08-02.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Cocoa
import ScriptingBridge
import TypedNotification
import os.signpost

private let log = OSLog(subsystem: "org.alexj.Spotijack", category: "Session Manager")

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
///
public final class SpotijackSessionManager {

    // MARK: - Singleton Access

    private static var _shared: SpotijackSessionManager!

    /// The shared session manager instance. Will attempt to launch Spotify and Audio Hijack Pro if they haven't been
    /// launched. Will throw if the applications can not be launched or a scripting bridge can't be established.
    ///
    public static func shared() throws -> SpotijackSessionManager {
        if _shared == nil {
            _shared = try SpotijackSessionManager()
        }

        return _shared
    }

    // MARK: - Public Properties

    public let notificationCenter: TypedNotificationCenter

    /// The currently playing track in Spotify or `nil` if no track is playing.
    ///
    public var currentTrack: StaticSpotifyTrack? {
        return spotifyBridge.currentTrack.map(StaticSpotifyTrack.init(from:))
    }

    /// Queries AHP to determine if the Spotijack session is recording. Returns false and posts a `DidEncounterError`
    /// message if AHP can not be queried.
    ///
    public var isRecording: Bool {
        recorder.isRecording
    }

    /// Returns `true` if SpotijackSessionManager is actively controlling recording.
    ///
    public private(set) var isSpotijacking: Bool = false

    /// Returns `true` if SpotijackSessionManager is polling Spotify and AHP.
    ///
    public var isPolling: Bool { return _applicationPollingTimer?.isValid ?? false }

    // MARK: - Private Properties

    internal let spotifyBridge: SpotifyApplication
    private let recorder = AudioRecorder()

    // MARK: - Private Properties - State

    // Internal mute state used to track changes. Does not affect the actual mute state in AHP.
    ///
    private var _isMuted: Bool = false {
        didSet {
            if _isMuted != oldValue {
                notificationCenter.post(MuteStateDidChange(object: self, newMuteState: _isMuted))
            }
        }
    }

    internal var _applicationPollingTimer: Timer?

    private var activityToken: NSObjectProtocol?

    /// The recording configuration used for the current Spotijack session or `nil` if not Spotijacking
    internal var _currentRecordingConfiguration: RecordingConfiguration?

    /// Interval we were polling applications at _before_ starting Spotijacking.
    private var _pastPollingInterval: TimeInterval?

    // MARK: - Initializers

    internal init(spotifyBridge: SpotifyApplication, notificationCenter: TypedNotificationCenter = NotificationCenter.default) {
        self.spotifyBridge = spotifyBridge
        self.notificationCenter = notificationCenter
    }

    private convenience init() throws {
        let isSpotifyLaunched = NSWorkspace.shared.launchApplication(
            withBundleIdentifier: Constants.spotifyBundle.identifier,
            options: [.withoutActivation, .andHide],
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil
        )

        guard isSpotifyLaunched == true else {
            throw SpotijackError.CantStartApplication(appName: Constants.spotifyBundle.name)
        }

        guard let spotifyBridge = SBApplication(bundleIdentifier: Constants.spotifyBundle.identifier) else {
            throw SpotijackError.NoScriptingInterface(appName: Constants.spotifyBundle.name)
        }

        self.init(spotifyBridge: spotifyBridge)
    }

    // MARK: - Public Methods

    /// Start a Spotijack recording session. Calling this method when a recording session is already in progress has no
    /// effect. Polling will be restarted at the interval specified in `config`.
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

    /// Stops a Spotijack recording session. Calling this method when no recording session is in progress has no
    /// effect. If we were polling when Spotijacking started, we'll resume polling at that interval.
    public func stopSpotijacking() {
        guard isSpotijacking == true else {
            return
        }

        isSpotijacking = false
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

        notificationCenter.post(DidEndSpotijacking(object: self))
    }

    /// Starts polling Spotify and AHP for changes. Polling is stopped when `stopPolling()` is called or if
    /// `SpotijackSessionManager` encounters an error.
    ///
    /// Calling this method when `SpotijackSessionManager` is already polling will have no effect.
    ///
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
    /// Calling this method when `SpotijackSessionManager` isn't already polling will have no effect.
    public func stopPolling() {
        guard isPolling == true else {
            return
        }

        _applicationPollingTimer?.invalidate()
        _applicationPollingTimer = nil
    }

    // MARK: - Private Methods

    @objc private func applicationPollingTimerFired(timer: Timer) {
        os_signpost(.begin, log: log, name: "Poll Applications")
        pollSpotify()
        os_signpost(.end, log: log, name: "Poll Applications")
    }

    /// ID of the track playing in Spotify when it was last polled.
    private var _lastSpotifyTrackId: String?

    // Synchronise the internal Spotify state
    internal func pollSpotify() {
        os_signpost(.begin, log: log, name: "Poll Spotify")
        // Accessing properties on an SBObject is expensive so the state checks in this method are ordered to minimise
        // the number of SBObject properties queried.

        // At a minimum, the track ID has to be queried so this SBObject method call is unavoidable.
        let currentTrackId = spotifyBridge.currentTrack?.id!()

        // Nothing needs to be done if the track id hasn't changed.
        guard currentTrackId != _lastSpotifyTrackId else {
            os_signpost(.end, log: log, name: "Poll Spotify", "Track not changed")
            return
        }

        defer {
            _lastSpotifyTrackId = currentTrackId

            // This is the most expensive call because building a `StaticSpotifyTrack` involves accessing lots of
            // SBObject properties.
            notificationCenter.post(TrackDidChange(object: self, newTrack: currentTrack))
            os_signpost(.end, log: log, name: "Poll Spotify", "Track changed")
        }

        // Further checks are only needed if Spotijack is controlling the recording session.
        guard isSpotijacking else {
            return
        }

        // End Spotijacking if Spotify is at the end of its playback queue. This is not a foolproof check.
        if spotifyBridge.playerState == .paused,
            spotifyBridge.playerPosition == 0 {
            stopSpotijacking()
            notificationCenter.post(DidReachEndOfPlaybackQueue(object: self))
        } else { // Otherwise start a new recording
            do {
                try startNewRecording()
            } catch {
                notificationCenter.post(DidEncounterError(object: self, error: error))
            }
        }
    }

    /// Starts a new recording in AHP and resets Spotify's play position. If there is no new track, ends the current
    /// Spotijack session.
    private func startNewRecording() throws {
        os_signpost(.begin, log: log, name: "Start New Recording")

        // End the session if there are no more tracks
        guard let currentTrack = currentTrack else {
            stopSpotijacking()
            os_signpost(.end, log: log, name: "Start New Recording", "no more tracks")
            return
        }

        os_signpost(.event, log: log, name: "Loaded Spotify track")

        // Start a new recording
        spotifyBridge.pause!()
        spotifyBridge.setPlayerPosition!(0.0)

        os_signpost(.event, log: log, name: "Updated Audio Hijack Pro metadata")

        guard let delay = _currentRecordingConfiguration?.recordingStartDelay else {
            preconditionFailure("Current recording configuration not set for a Spotijack session")
        }

        let newRecordingBlock = {
            self.spotifyBridge.play!()
            os_signpost(.end, log: log, name: "Start New Recording", "started recording")
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

    struct RecordingConfiguration {
        /// Should the Spotijack session be muted when starting Spotijacking?
        public let muteSpotify: Bool

        /// Should shuffling be disabled in Spotify when starting Spotijacking?
        public let disableShuffling: Bool

        /// Should repeat be disabled in Spotify when starting Spotijacking?
        public let disableRepeat: Bool

        /// Frequency we should poll Spotify and AHP when Spotijacking.
        public let pollingInterval: TimeInterval

        /// The pause Spotijack should make between a track ending and starting a new recording. Introducing this pause
        /// reduces the likelihood of the end of one track overlapping the start of the next but adds a short gap to
        /// the start of the recording. I recommend keeping this value around 0.1 seconds.
        public let recordingStartDelay: TimeInterval

        public init(muteSpotify: Bool = false, disableShuffling: Bool = false, disableRepeat: Bool = false,
                    pollingInterval: TimeInterval = 0.1, recordingStartDelay: TimeInterval = 0) {
            self.muteSpotify = muteSpotify
            self.disableShuffling = disableShuffling
            self.disableRepeat = disableRepeat
            self.pollingInterval = pollingInterval
            self.recordingStartDelay = recordingStartDelay
        }
    }

}
