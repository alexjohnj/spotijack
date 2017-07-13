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

    /// Queries Audio Hijack Pro to determine if the Spotijack session is
    /// currently recording. Returns false and posts a `DidEncounterError`
    /// notification if Audio Hijack Pro can not be queried.
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
