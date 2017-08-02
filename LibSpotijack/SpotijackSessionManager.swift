//
//  SpotijackSessionManager.swift
//  Spotijack
//
//  Created by Alex Jackson on 28/06/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation
import ScriptingBridge
import Result

public final class SpotijackSessionManager: NSObject {
    //MARK: Singleton Setup
    private static let shared = SpotijackSessionManager()
    private override init() { }

    private let notiCenter: NotificationCenter = NotificationCenter.default

    //MARK: Current Session
    private static var spotijackSession: SpotijackSession? = nil {
        willSet {
            // TODO Set up KVO notifications for applications
        }
    }

    //MARK: State Properties
    public static var isMuted: Bool {
        return spotijackSession?.isMuted ?? false
    }

    public static var isRecording: Bool {
        return spotijackSession?.isRecording ?? false
    }

    public static var isSpotijacking: Bool {
        return spotijackSession?.isSpotijacking ?? false
    }

    //MARK: KVO
    private var context = 0
}

//MARK: Session Initialisation & Access
extension SpotijackSessionManager {
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
    public static func establishSession(_ then: @escaping (Result<SpotijackSession>) -> ()) {
        guard spotijackSession == nil else {
            DispatchQueue.main.async {
                then(.ok(spotijackSession!))
            }
            return
        }

        let spotifyApplication = startApplication(fromBundle: Bundles.spotify)
        let spotifyBridge = establishScriptingBridge(forBundle: Bundles.spotify)

        let audioHijackApplication = startApplication(fromBundle: Bundles.audioHijack)
        let audioHijackBridge = establishScriptingBridge(forBundle: Bundles.audioHijack)

        switch (spotifyApplication, spotifyBridge, audioHijackApplication, audioHijackBridge) {
        case (.fail(let error), _, _, _):
            then(.fail(error))
        case (_, .fail(let error), _, _):
            then(.fail(error))
        case (_, _, .fail(let error), _):
            then(.fail(error))
        case (_, _, _, .fail(let error)):
            then(.fail(error))
        case (.ok(let spotifyApplication), .ok(let spotifyBridge), .ok(let audioHijackApplication), .ok(let audioHijackBridge)):
            let spotijackSession = SpotijackSession(spotify: (spotifyApplication, spotifyBridge),
                                                    audioHijack: (audioHijackApplication, audioHijackBridge),
                                                    manager: shared)
            self.spotijackSession = spotijackSession

            // Wait a little bit for Spotify's scripting interface to come
            // online after launching. I know, this is Yucky, but Spotify marks
            // itself as having finished launching before scripting works
            // so observing NSRunningApplication's isFinishedLaunching property
            // is no use.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.7) {
                self.spotijackSession?.pollSpotify()
                self.spotijackSession?.pollAudioHijackPro()

                then(.ok(spotijackSession))
            }
        }
    }

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

    private static func establishScriptingBridge(forBundle bundle: BundleInfo) -> Result<SBApplication> {
        let bridge = SBApplication(bundleIdentifier: bundle.identifier)

        if let bridge = bridge {
            return .ok(bridge)
        } else {
            return .fail(SpotijackSessionError.noScriptingInterface(appName: bundle.name))
        }
    }
}

//MARK: Session Back-Communication
extension SpotijackSessionManager {
    func trackDidChange(newTrack: StaticSpotifyTrack?) {
        notiCenter.post(TrackDidChange(sender: self, newTrack: newTrack))
    }

    func muteStateDidChange(newMuteState: Bool) {
        notiCenter.post(MuteStateDidChange(sender: self, newMuteState: newMuteState))
    }

    func recordingStateDidChange(isRecording: Bool) {
        notiCenter.post(RecordingStateDidChange(sender: self, isRecording: isRecording))
    }

    func sessionDidEncounterError(_ error: Error) {
        notiCenter.post(DidEncounterError(sender: self, error: error))
    }
}









