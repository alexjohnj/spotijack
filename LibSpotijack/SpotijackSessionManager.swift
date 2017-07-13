//
//  SpotijackSessionManager.swift
//  Spotijack
//
//  Created by Alex Jackson on 28/06/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Cocoa
import ScriptingBridge
import Result
import TypedNotification

public class SpotijackSessionManager {
    //MARK: Properties - General
    public static let shared = SpotijackSessionManager()
    private let notiCenter = NotificationCenter.default

    //MARK: Properties - Application Bridges
    private var spotify: Result<SpotifyApplication> {
        return startApplication(fromBundle: Bundles.spotify).flatMap {
            .ok($0 as SpotifyApplication) // Always succeeds
        }
    }

    private var audioHijack: Result<AudioHijackApplication> {
        return startApplication(fromBundle: Bundles.audioHijack).flatMap {
            .ok($0 as AudioHijackApplication) // Always succeeds
        }
    }

    private var spotijackSession: Result<AudioHijackSession> {
        return audioHijack.flatMap { ah in
            let sessions = ah.sessions!() as! [AudioHijackSession] // Should never fail

            if let session = sessions.first(where: { $0.name == "Spotijack" }) {
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
            switch spotijackSession.map({ $0.speakerMuted! }) {
            case .ok(let status):
                return status
            case .fail(let error):
                notiCenter.post(DidEncounterError(sender: self, error: error))
                return false
            }
        }

        set {
            switch spotijackSession.map({ $0.setSpeakerMuted!(newValue) }) {
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
            switch spotijackSession.map({ $0.recording! }) {
            case .ok(let status):
                return status
            case .fail(let error):
                notiCenter.post(DidEncounterError(sender: self, error: error))
                return false
            }
        }

        set {
            let result = spotijackSession.map {
                newValue ? $0.startRecording!() : $0.stopRecording!()
            }

            switch result {
            case .ok:
                _isRecording = newValue
            case .fail(let error):
                notiCenter.post(DidEncounterError(sender: self, error: error))
            }
        }
    }

    private var _currentTrack: SpotifyTrack? = nil {
        didSet {
            if _currentTrack?.id?() != oldValue?.id?() {
                notiCenter.post(TrackDidChange(sender: self, newTrack: _currentTrack))
            }
            //TODO: Handle starting a new recording here if currently Spotijacking
        }
    }
    /// Returns the currently playing track in Spotify. Can return `nil` if no
    /// track is playing or if Spotify can not be accessed. For the latter, a
    /// `DidEncounterError` notification is also posted.
    public var currentTrack: SpotifyTrack? {
        let track = spotify.map { $0.currentTrack }
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
    private var _errorObserver: NotificationObserver? = nil

    //MARK: Lifecycle
    private init() {
        _errorObserver = notiCenter.addObserver(forType: DidEncounterError.self, object: self, queue: nil) { [weak self] (noti) in
            self?.didEncounterError(noti.error)
        }
    }

    //MARK: Application Intialisation
    private typealias BundleInfo = (name: String, identifier: String)
    private struct Bundles {
        static let spotify: BundleInfo = ("Spotify", "com.spotify.client")
        static let audioHijack: BundleInfo = ("Audio Hijack Pro", "com.rogueamoeba.AudioHijackPro2")
    }

    /// Launches the application with the identifier `bundle.identifier` and
    /// tries to establish a scripting interface with the application.
    /// Throws if either of these fails.
    private func startApplication(fromBundle bundle: BundleInfo,
                                  options: NSWorkspace.LaunchOptions = [.withoutActivation, .andHide]) -> Result<SBApplication> {
        let appLaunched = NSWorkspace.shared.launchApplication(withBundleIdentifier: bundle.identifier,
                                                               options: options,
                                                               additionalEventParamDescriptor: nil,
                                                               launchIdentifier: nil)
        guard appLaunched == true else {
            return .fail(SpotijackSessionError.cantStartApplication(name: bundle.name))
        }

        if let sbInterface = SBApplication(bundleIdentifier: bundle.identifier) {
            return .ok(sbInterface)
        } else {
            return .fail(SpotijackSessionError.noScriptingInterface(appName: bundle.name))
        }
    }

    /// Attempts to start Audio Hijack Pro, Spotify and the Spotijack session.
    /// The behaviour of SpotijackSessionManager is undefined if this function
    /// is not called at least once.
    public func establishSession() throws {
        let _ = try spotify.dematerialize()
        let _ = try audioHijack.dematerialize()
        let _ = try spotijackSession.dematerialize()
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

    // Called when a `DidEncounterError` notification is posted. Ends polling and
    // any Spotijack controlled recording sessions that were running.
    private func didEncounterError(_ error: Error) {
        stopPolling()
    }
}

//MARK: Errors
public extension SpotijackSessionManager {
    public enum SpotijackSessionError: Error {
        /// The Spotify bundle could not be found or the application failed to
        /// start for some exceptional reason.
        case cantStartApplication(name: String)
        /// Could not get an SBApplication reference to the application. Maybe
        /// it no longer supports AppleScript?
        case noScriptingInterface(appName: String)
        /// Could not find a Spotijack session in AHP
        case spotijackSessionNotFound
    }
}
