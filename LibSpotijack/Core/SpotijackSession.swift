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

public final class SpotijackSession {
    //MARK: Properties - General
    private weak var manager: SpotijackSessionManager?
    
    //MARK: Properties - Application Bridges
    internal var spotifyBridge: SpotifyApplication
    internal var audioHijackBridge: AudioHijackApplication

    /// A scripting bridge interface to the Spotijack session in Audio Hijack Pro.
    /// Accessing this property will make Audio Hijack Pro start hijacking Spotify.
    internal var spotijackSessionBridge: Result<AudioHijackApplicationSession> {
        switch getFirstSpotijackSession() {
        case .ok(let session):
            session.startHijackingRelaunch!(.yes)
            return .ok(session)
        case .fail(let error):
            // Try and create a new session if one doesn't exist
            switch error {
            case is SpotijackError.SpotijackSessionNotFound:
                do {
                    try SpotijackSessionCreator.createSpotijackSession()
                    switch getFirstSpotijackSession() {
                    case .ok(let session):
                        session.startHijackingRelaunch!(.yes)
                        return .ok(session)
                    case .fail(let reacquireError):
                        return .fail(reacquireError)
                    }
                } catch (let creationError) {
                    return .fail(creationError)
                }
            default:
                return .fail(error)
            }
        }
    }

    /// Gets the first session called "Spotijack" reported by Audio Hijack Pro.
    private func getFirstSpotijackSession() -> Result<AudioHijackApplicationSession> {
        let sessions = audioHijackBridge.sessions!() as! [AudioHijackApplicationSession] // Should never fail

        if let session = sessions.first(where: { $0.name == "Spotijack" }) {
            return .ok(session)
        } else {
            return .fail(SpotijackError.SpotijackSessionNotFound())
        }
    }

    //MARK: Properties - State
    // Internal mute state used to track changes. Does not affect the actual mute
    // state in AHP.
    private var _isMuted: Bool = false {
        didSet {
            if _isMuted != oldValue {
                manager?.muteStateDidChange(newMuteState: _isMuted)
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
                manager?.sessionDidEncounterError(error)
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
                manager?.sessionDidEncounterError(error)
            }
        }
    }

    private var _isRecording = false {
        didSet {
            if _isRecording != oldValue {
                manager?.recordingStateDidChange(isRecording: _isRecording)
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
                manager?.sessionDidEncounterError(error)
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
                manager?.sessionDidEncounterError(error)
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

                stopSpotijackSession()
                manager?.trackDidChange(newTrack: _currentTrack)
                manager?.didReachEndOfPlaybackQueue()

                return
            }

            if _currentTrack != oldValue {
                manager?.trackDidChange(newTrack: _currentTrack)
            }

            // Start a new recording if Spotijack is controlling the current
            // recording session.
            if _currentTrack != oldValue,
                isSpotijacking == true
            {
                do {
                    try startNewRecording()
                } catch (let error) {
                    manager?.sessionDidEncounterError(error)
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

    internal var _applicationPollingTimer: Timer? = nil
    private var activityToken: NSObjectProtocol? = nil

    /// Returns `true` if SpotijackSessionManager is polling Spotify and AHP.
    public var isPolling: Bool { return _applicationPollingTimer?.isValid ?? false }

    /// Returns `true` if SpotijackSessionManager is actively controlling recording.
    public private(set) var isSpotijacking: Bool = false

    /// Interval we were polling applications at _before_ starting Spotijacking.
    private var _pastPollingInterval: TimeInterval? = nil

    //MARK: Lifecycle
    internal init(spotifyBridge: SpotifyApplication, audioHijackBridge: AudioHijackApplication, manager: SpotijackSessionManager) {
        self.spotifyBridge = spotifyBridge
        self.audioHijackBridge = audioHijackBridge

        self.manager = manager
    }

    //MARK: Application Polling
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

    //MARK: Spotijacking
    /// Start a Spotijack recording session. Calling this method when a recording
    /// session is already in progress has no effect. Polling will be restarted
    /// at the interval specified in `config`.
    public func startSpotijackSession(config: RecordingConfiguration) throws {
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
        try startNewRecording()
    }

    /// Stops a Spotijack recording session. Calling this method when no recording
    /// session is in progress has no effect. If we were polling when Spotijacking
    /// started, we'll resume polling at that interval.
    public func stopSpotijackSession() {
        guard isSpotijacking == true else {
            return
        }

        isRecording = false
        isSpotijacking = false
        if let activityToken = activityToken {
            ProcessInfo.processInfo.endActivity(activityToken)
            self.activityToken = nil
        }

        if let pastPollingInterval = _pastPollingInterval {
            stopPolling()
            startPolling(every: pastPollingInterval)
        }
    }

    /// Starts a new recording in AHP and resets Spotify's play position.
    /// If there is no new track, ends the cu rrent Spotijack session.
    private func startNewRecording() throws {
        // Check we can still communicate with the recording session
        let spotijackSessionBridge = try self.spotijackSessionBridge.dematerialize()

        // End the session if there are no more tracks
        guard let currentTrack = currentTrack else {
            stopSpotijackSession()
            return
        }

        // Start a new recording
        isRecording = false
        spotifyBridge.pause!()
        spotifyBridge.setPlayerPosition!(0.0)
        spotijackSessionBridge.setMetadata(from: currentTrack)

        // Wait a very short period before starting the recording to account
        // for Spotify's slow response to AppleScript events. Hopefully, this
        // will reduce the chance of the starts/ends of songs overlapping.
        //
        // I'm sure there's a load of multithreading bugs possible doing this
        // but ¯\_(ツ)_/¯
        //
        // The choice of 0.10 seconds is based on my observations of how much
        // songs tend to overlap.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { [weak self] in
            spotijackSessionBridge.startRecording!()
            self?.spotifyBridge.play!()
        }
    }

    // Called when a `DidEncounterError` notification is posted. Ends polling and
    // any Spotijack controlled recording sessions that were running.
    private func didEncounterError(_ error: Error) {
        stopSpotijackSession()
        stopPolling()
    }
}

//MARK: RecordingConfiguration
public extension SpotijackSession {
    public struct RecordingConfiguration {
        /// Should the Spotijack session be muted when starting Spotijacking?
        public let muteSpotify: Bool
        /// Should shuffling be disabled in Spotify when starting Spotijacking?
        public let disableShuffling: Bool
        /// Should repeat be disabled in Spotify when starting Spotijacking?
        public let disableRepeat: Bool
        /// Frequency we should poll Spotify and AHP when Spotijacking.
        public let pollingInterval: TimeInterval

        public init(muteSpotify: Bool = false, disableShuffling: Bool = false, disableRepeat: Bool = false, pollingInterval: TimeInterval = 0.1) {
            self.muteSpotify = muteSpotify
            self.disableShuffling = disableShuffling
            self.disableRepeat = disableRepeat
            self.pollingInterval = pollingInterval
        }
    }
}

