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
    //MARK: Properties
    public static let shared = SpotijackSessionManager()

    public var isMuted: Bool {
        get {
            do {
                return try spotijackSession.dematerialize().speakerMuted!
            } catch (let error) {
                NotificationCenter.default.post(name: NotificationKeys.didEncounterError,
                                                object: self,
                                                userInfo: ["error": error])
                return false
            }
        }

        set {
            do {
                let oldValue = isMuted
                try spotijackSession.dematerialize().setSpeakerMuted!(newValue)
                if newValue != oldValue {
                    NotificationCenter.default.post(name: NotificationKeys.muteStateDidChange,
                                                    object: self,
                                                    userInfo: ["newValue": newValue])
                }
            } catch (let error) {
                NotificationCenter.default.post(name: NotificationKeys.didEncounterError,
                                                object: self,
                                                userInfo: ["error": error])
            }
        }
    }

    //MARK: Types
    private typealias BundleInfo = (name: String, identifier: String)
    private struct Bundles {
        static let spotify: BundleInfo = ("Spotify", "com.spotify.client")
        static let audioHijack: BundleInfo = ("Audio Hijack Pro", "com.rogueamoeba.AudioHijackPro2")
    }

    public struct NotificationKeys {
        /// Posted when an error occurs outside of a throwing a function.
        /// For example, accessing the muted state of Spotify when a
        /// scripting interface can't be obtained. The attatched userInfo
        /// dictionary includes the key "error" mapping onto an Error object.
        public static let didEncounterError = Notification.Name("SpotijackSessionManager.DidEncounterError")
        /// Posted when the mute state of Spotify changes. The attatched userInfo
        /// dictionary contains the key "newValue" mapping onto a boolean
        /// representation of the new mute state.
        public static let muteStateDidChange = Notification.Name("SpotijackSessionManager.MuteStateDidChange")
    }

    enum SpotijackSessionError: Error {
        /// The Spotify bundle could not be found or the application failed to
        /// start for some exceptional reason.
        case cantStartApplication(name: String)
        /// Could not get an SBApplication reference to the application. Maybe
        /// it no longer supports AppleScript?
        case noScriptingInterface(appName: String)
        /// Could not find a Spotijack session in AHP
        case spotijackSessionNotFound
    }

    //MARK: Application Intialisation
    /// Launches the application with the identifier `bundle.identifier` and
    /// tries to establish a scripting interface with the application.
    /// Throws if either of these fails.
    private func startApplication(fromBundle bundle: BundleInfo,
                                  options: NSWorkspaceLaunchOptions = [.withoutActivation, .andHide]) -> Result<SBApplication> {
        let appLaunched = NSWorkspace.shared().launchApplication(withBundleIdentifier: bundle.identifier,
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

    /// Attempts to start Audio Hijack Pro, Spotify and the Spotijack session.
    /// The behaviour of SpotijackSessionManager is undefined if this function
    /// is not called at least once.
    public func establishSession() throws {
        let _ = try spotify.dematerialize()
        let _ = try audioHijack.dematerialize()
        let _ = try spotijackSession.dematerialize()
    }
}
