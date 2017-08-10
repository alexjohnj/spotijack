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
    // MARK: - Singleton Things
    public static let shared = SpotijackSessionManager()
    private init() { }

    public let notiCenter: NotificationCenter = NotificationCenter.default

    // MARK: - Spotijack Session
    internal var spotijackSession: SpotijackSession? // Internal for testing

    // MARK: Session State
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

// MARK: Session Initialisation & Access
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
    public func establishSession(_ then: @escaping (Result<SpotijackSession>) -> Void) {
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
            let session = SpotijackSession(spotifyBridge: spotifyBridge, audioHijackBridge: audioHijackBridge)
            session.delegate = self

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

// MARK: - SpotijackSessionDelegate
extension SpotijackSessionManager: SpotijackSessionDelegate {
    func session(_ session: SpotijackSession, didChangeToTrack track: StaticSpotifyTrack?) {
        notiCenter.post(TrackDidChange(sender: self, newTrack: track))
    }

    func session(_ session: SpotijackSession, didMute isMuted: Bool) {
        notiCenter.post(MuteStateDidChange(sender: self, newMuteState: isMuted))
    }

    func session(_ session: SpotijackSession, didChangeRecordingState isRecording: Bool) {
        notiCenter.post(RecordingStateDidChange(sender: self, isRecording: isRecording))
    }

    func session(_ session: SpotijackSession, didEncounterError error: Error) {
        self.spotijackSession = nil
        notiCenter.post(DidEncounterError(sender: self, error: error))
    }

    func sessionDidReachEndOfPlaybackQueue(_ session: SpotijackSession) {
        notiCenter.post(DidReachEndOfPlaybackQueue(sender: self))
    }

}
