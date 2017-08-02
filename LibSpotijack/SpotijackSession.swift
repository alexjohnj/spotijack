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

typealias SBRunningApplicationPair<T: SBApplicationProtocol> = (app: NSRunningApplication, bridge: T)

public final class SpotijackSession {
    //MARK: Properties - Application Bridges
    // Access level is internal for testing purposes.
    internal var spotifyBridge: SpotifyApplication
    internal var spotifyApplication: NSRunningApplication

    internal var audioHijackBridge: AudioHijackApplication
    internal var audioHijackApplication: NSRunningApplication

    /// A scripting bridge interface to the Spotijack session in Audio Hijack Pro.
    /// Accessing this property will make Audio Hijack Pro start hijacking Spotify.
    internal var spotijackSessionBridge: Result<AudioHijackSession> {
        return audioHijackBridge.flatMap { ah in
            let sessions = ah.sessions!() as! [AudioHijackSession] // Should never fail

            if let session = sessions.first(where: { $0.name == "Spotijack" }) {
                session.startHijackingRelaunch!(.yes)
                return .ok(session)
            } else {
                return .fail(SpotijackSessionError.spotijackSessionNotFound)
            }
        }
    }

    //MARK: Properties - State
    // Internal mute state used to track changes. Does not affect the actual mute
    // state in AHP.
    private var _isMuted: Bool = false {
        didSet {
            if _isMuted != oldValue {
                notiCenter.post(MuteStateDidChange(sender: self, newMuteState: _isMuted))
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
                notiCenter.post(DidEncounterError(sender: self, error: error))
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
                notiCenter.post(DidEncounterError(sender: self, error: error))
            }
        }
    }

    private var _isRecording = false {
        didSet {
            if _isRecording != oldValue {
                notiCenter.post(RecordingStateDidChange(sender: self, isRecording: _isRecording))
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
                notiCenter.post(DidEncounterError(sender: self, error: error))
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
                notiCenter.post(DidEncounterError(sender: self, error: error))
            }
        }
    }

    private var _currentTrack: StaticSpotifyTrack? = nil {
        didSet {
            if _currentTrack != oldValue {
                notiCenter.post(TrackDidChange(sender: self, newTrack: _currentTrack))
            }

            // Start a new recording if Spotijack is controlling the current
            // recording session.
            if _currentTrack != oldValue,
                isSpotijacking == true
            {
                startNewRecording()
            }
        }
    }

    /// Returns the currently playing track in Spotify. Can return `nil` if no
    /// track is playing or if Spotify can not be accessed. For the latter, a
    /// `DidEncounterError` notification is also posted.
    public var currentTrack: StaticSpotifyTrack? {
        let track = spotifyBridge.map { (spotify) -> StaticSpotifyTrack? in
            if let currentTrack = spotify.currentTrack {
                return StaticSpotifyTrack(from: currentTrack)
            } else {
                return nil
            }
        }

        switch track {
        case .ok(let value):
            return value
        case .fail(let error):
            notiCenter.post(DidEncounterError(sender: self, error: error))
            return nil
        }
    }

    private var _applicationPollingTimer: Timer? = nil
    /// Returns `true` if SpotijackSessionManager is polling Spotify and AHP.
    public var isPolling: Bool { return _applicationPollingTimer?.isValid ?? false }

    /// Returns `true` if SpotijackSessionManager is actively controlling recording.
    public private(set) var isSpotijacking: Bool = false

    //MARK: Lifecycle
    internal init(spotify: SBRunningApplicationPair<SpotifyApplication>, audioHijack: SBRunningApplicationPair<AudioHijackApplication>) {
        self.spotifyApplication = spotify.app
        self.spotifyBridge = spotify.bridge
        self.audioHijackApplication = audioHijack.app
        self.audioHijackBridge = audioHijack.bridge
    }

    deinit {
        // Trigger KVO observer removal for NSRunningApplication instances
        spotifyApplication = nil
        audioHijackApplication = nil
    }

    //MARK: KVO Methods
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &self.context,
            let keyPath = keyPath,
            let object = object,
            let change = change
            else {
                return
        }

        // Handle termination of an application
        if keyPath == #keyPath(NSRunningApplication.isTerminated),
            let object = object as? NSRunningApplication,
            let isTerminated = change[.newKey] as? Bool,
            isTerminated == true
        {
            if let spotifyApplication = spotifyApplication,
                object == spotifyApplication {
                self.spotifyApplication = nil
                return
            }

            if let audioHijackApplication = audioHijackApplication,
                object == audioHijackApplication {
                self.audioHijackApplication = nil
                return
            }
        }
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
    private func pollSpotify() {
        _currentTrack = currentTrack
    }

    // Synchronise the internal AHP state
    private func pollAudioHijackPro() {
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
        do {
            if config.disableRepeat {
                try spotifyBridge.dematerialize().setRepeating!(false)
            }

            if config.disableShuffling {
                try spotifyBridge.dematerialize().setShuffling!(false)
            }

            if config.muteSpotify {
                try spotijackSessionBridge.dematerialize().setSpeakerMuted!(true)
            }
        } catch (let error) {
            throw error
        }

        if isPolling { stopPolling() }
        startPolling(every: config.pollingInterval)
        isSpotijacking = true
        startNewRecording()
    }

    /// Stops a Spotijack recording session. Calling this method when no recording
    /// session is in progress has no effect. This method does not end polling.
    public func stopSpotijackSession() {
        guard isSpotijacking == true else {
            return
        }

        isRecording = false
        isSpotijacking = false
    }

    /// Starts a new recording in AHP and resets Spotify's play position.
    /// If there is no new track, ends the current Spotijack session.
    private func startNewRecording() {
        switch (spotifyBridge, spotijackSessionBridge, currentTrack) {
        case (.ok(let spotify), .ok(let spotijackSession), .some(let currentTrack)):
            isRecording = false
            spotify.pause!()
            spotify.setPlayerPosition!(0.0)
            spotijackSession.setMetadata(from: currentTrack)
            spotijackSession.startRecording!()
            spotify.play!()
        case (.ok, .ok, .none):
            stopSpotijackSession()
        case (.fail(let error), _, _):
            notiCenter.post(DidEncounterError(sender: self, error: error))
        case (_, .fail(let error), _):
            notiCenter.post(DidEncounterError(sender: self, error: error))
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

        public init(muteSpotify: Bool = false, disableShuffling: Bool = false, disableRepeat: Bool = false, pollingInterval: TimeInterval = 0.1) {
            self.muteSpotify = muteSpotify
            self.disableShuffling = disableShuffling
            self.disableRepeat = disableRepeat
            self.pollingInterval = pollingInterval
        }
    }
}

