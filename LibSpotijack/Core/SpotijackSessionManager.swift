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
import TypedNotification

public final class SpotijackSessionManager {
    //MARK: Singleton Setup
    public static let shared = SpotijackSessionManager()
    private init() { }

    public let notiCenter: NotificationCenter = NotificationCenter.default

    //MARK: Current Session
    internal var spotijackSession: SpotijackSession? // Internal for testing

    //MARK: State Properties
    public var isMuted: Bool {
        return spotijackSession?.isMuted ?? false
    }

    public var isRecording: Bool {
        return spotijackSession?.isRecording ?? false
    }

    public var isSpotijacking: Bool {
        return spotijackSession?.isSpotijacking ?? false
    }
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
    public func establishSession(_ then: @escaping (Result<SpotijackSession>) -> ()) {
        guard spotijackSession == nil else {
            let session = spotijackSession!
            DispatchQueue.main.async {
                then(.ok(session))
            }
            return
        }

        let spotifyBridge = establishScriptingBridge(forBundle: Constants.spotifyBundle)
        let audioHijackBridge = establishScriptingBridge(forBundle: Constants.audioHijackBundle)

        switch (spotifyBridge, audioHijackBridge) {
        case (.fail(let error), _):
            then(.fail(error))
        case (_, .fail(let error)):
            then(.fail(error))
        case (.ok(let spotifyBridge), .ok(let audioHijackBridge)):
            let session = SpotijackSession(spotifyBridge: spotifyBridge, audioHijackBridge: audioHijackBridge, manager: self)
            self.spotijackSession = session

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.7) {
                self.spotijackSession?.pollSpotify()
                self.spotijackSession?.pollAudioHijackPro()

                then(.ok(session))
            }
        }
    }

    private func launchApplication(fromBundle bundle: Constants.BundleInfo) -> Bool {
        return NSWorkspace.shared.launchApplication(
            withBundleIdentifier: bundle.identifier,
            options: [.withoutActivation, .andHide],
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil)
    }

    private func establishScriptingBridge(forBundle bundle: Constants.BundleInfo) -> Result<SBApplication> {
        guard launchApplication(fromBundle: bundle) == true else {
            return.fail(SpotijackError.CantStartApplication(appName: bundle.name))
        }
        
        let bridge = SBApplication(bundleIdentifier: bundle.identifier)

        if let bridge = bridge {
            return .ok(bridge)
        } else {
            return .fail(SpotijackError.NoScriptingInterface(appName: bundle.name))
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
        spotijackSession = nil
        notiCenter.post(DidEncounterError(sender: self, error: error))
    }

    func didReachEndOfPlaybackQueue() {
        notiCenter.post(DidReachEndOfPlaybackQueue(sender: self))
    }
}
