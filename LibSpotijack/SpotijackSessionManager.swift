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

public class SpotijackSessionManager: NSObject {
    //MARK: Properties - General
    private static let shared = SpotijackSessionManager()
    private let notiCenter = NotificationCenter.default
    private var context = 0

    //MARK: Properties - Application Bridges
    private var spotifyBridge: Result<SpotifyApplication> = .fail(SpotijackSessionError.applicationNotLaunched(name: Bundles.spotify.name))
    private var spotifyApplication: NSRunningApplication? = nil {
        willSet {
            spotifyApplication?.removeObserver(self, forKeyPath: #keyPath(NSRunningApplication.isTerminated))
        }

        didSet {
            if let spotifyApplication = spotifyApplication {
                spotifyBridge = establishScriptingBridge(forBundle: Bundles.spotify).map({ $0 as SpotifyApplication })
                spotifyApplication.addObserver(self, forKeyPath: #keyPath(NSRunningApplication.isTerminated), options: [.new], context: &context)
            } else {
                spotifyBridge = .fail(SpotijackSessionError.applicationNotLaunched(name: Bundles.spotify.name))
            }
        }
    }

    private var audioHijackBridge: Result<AudioHijackApplication> = .fail(SpotijackSessionError.applicationNotLaunched(name: Bundles.audioHijack.name))
    private var audioHijackApplication: NSRunningApplication? = nil {
        willSet {
            audioHijackApplication?.removeObserver(self, forKeyPath: #keyPath(NSRunningApplication.isTerminated))
        }

        didSet {
            if let audioHijackApplication = audioHijackApplication {
                audioHijackBridge = establishScriptingBridge(forBundle: Bundles.audioHijack).map({ $0 as AudioHijackApplication })
                audioHijackApplication.addObserver(self, forKeyPath: #keyPath(NSRunningApplication.isTerminated), options: [.new], context: &context)
            }
            else {
                audioHijackBridge = .fail(SpotijackSessionError.applicationNotLaunched(name: Bundles.audioHijack.name))
            }
        }
    }

    /// A scripting bridge interface to the Spotijack session in Audio Hijack Pro.
    /// Accessing this property will make Audio Hijack Pro start hijacking Spotify.
    private var spotijackSessionBridge: Result<AudioHijackSession> {
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
        let track = spotifyBridge.map { $0.currentTrack }
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
    private override init() {
        super.init()
        _errorObserver = notiCenter.addObserver(forType: DidEncounterError.self, object: self, queue: nil) { [weak self] (noti) in
            self?.didEncounterError(noti.error)
        }
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

    //MARK: Application Intialisation
    private typealias BundleInfo = (name: String, identifier: String)
    private struct Bundles {
        static let spotify: BundleInfo = ("Spotify", "com.spotify.client")
        static let audioHijack: BundleInfo = ("Audio Hijack Pro", "com.rogueamoeba.AudioHijackPro2")
    }

    private static func startApplication(fromBundle bundle: BundleInfo,
                                         options: NSWorkspace.LaunchOptions = [.withoutActivation, .andHide]) -> Result<NSRunningApplication> {
        let appLaunched = NSWorkspace.shared.launchApplication(withBundleIdentifier: bundle.identifier,
                                                               options: options,
                                                               additionalEventParamDescriptor: nil,
                                                               launchIdentifier: nil)

        guard appLaunched == true else {
            return .fail(SpotijackSessionError.cantStartApplication(name: bundle.name))
        }

        let applicationHandle = NSRunningApplication.runningApplications(withBundleIdentifier: bundle.identifier).first

        if let applicationHandle = applicationHandle {
            return .ok(applicationHandle)
        } else {
            return .fail(SpotijackSessionError.noRunningInstanceFound(appName: bundle.name))
        }
    }

    private func establishScriptingBridge(forBundle bundle: BundleInfo) -> Result<SBApplication> {
        let bridge = SBApplication(bundleIdentifier: bundle.identifier)

        if let bridge = bridge {
            return .ok(bridge)
        } else {
            return .fail(SpotijackSessionError.noScriptingInterface(appName: bundle.name))
        }
    }

    /// Attempts to start Audio Hijack Pro, Spotify and the Spotijack session.
    /// The behaviour of SpotijackSessionManager is undefined if this function
    /// is not called at least once.

    /// Establishes a Spotijack session, launching Audio Hijack Pro and Spotify
    /// if they aren't already launched.
    ///
    /// - parameter completionHandler: A function accepting a
    ///             `Result<SpotijackSessionManager>` to execute. Execution will
    ///              be delayed until the applications have been launched. The
    ///              completion handler will be called on the main queue.
    ///
    /// - note: Spotify's scripting interface doesn't activate until after the
    ///         application is launched. If Spotify needs to be launched, the
    ///         completion handler won't be activated until 0.7 seconds after
    ///         Spotify has been launched. This still mightn't be enough time for
    ///         Spotify to activate the scripting interface in which case what happens
    ///         is pretty much unknown.
    public static func establishSession(then completionHandler: @escaping ((Result<SpotijackSessionManager>) -> ())) {
        // Call the completion handler if everything's already running.
        let sessionManager = SpotijackSessionManager.shared
        guard sessionManager.spotifyApplication == nil || sessionManager.audioHijackApplication == nil else {
            DispatchQueue.main.async {
                completionHandler(.ok(.shared))
            }
            return
        }

        switch (startApplication(fromBundle: Bundles.spotify), startApplication(fromBundle: Bundles.audioHijack)) {
        case (.fail(let error), _):
            completionHandler(.fail(error))
            return
        case (_, .fail(let error)):
            completionHandler(.fail(error))
            return
        case (.ok(let spotifyApp), .ok(let audioHijackApp)):
            sessionManager.spotifyApplication = spotifyApp
            sessionManager.audioHijackApplication = audioHijackApp
            // Wait a little bit for Spotify's scripting interface to come
            // online after launching. I know, this is Yucky, but Spotify marks
            // itself as having finished launching before scripting works
            // so observing NSRunningApplication's isFinishedLaunching property
            // is no use.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.7) {
                completionHandler(.ok(sessionManager))
            }

            return
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

    // Called when a `DidEncounterError` notification is posted. Ends polling and
    // any Spotijack controlled recording sessions that were running.
    private func didEncounterError(_ error: Error) {
        stopPolling()
    }
}

//MARK: Errors
public extension SpotijackSessionManager {
    public enum SpotijackSessionError: Error {
        /// The application it not launched or a launch attempt has not been
        /// made yet.
        case applicationNotLaunched(name: String)

        /// The Spotify bundle could not be found or the application failed to
        /// start for some exceptional reason.
        case cantStartApplication(name: String)
        
        /// Could not get an SBApplication reference to the application. Maybe
        /// it no longer supports AppleScript?
        case noScriptingInterface(appName: String)

        /// Could not find a running instance of the application after trying
        /// to start the application.
        case noRunningInstanceFound(appName: String)

        /// Could not find a Spotijack session in AHP
        case spotijackSessionNotFound
    }
}
