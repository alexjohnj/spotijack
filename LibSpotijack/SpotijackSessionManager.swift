//
//  SpotijackSessionManager.swift
//  Spotijack
//
//  Created by Alex Jackson on 28/06/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation
import Result

public final class SpotijackSessionManager: NSObject {
    //MARK: Singleton Setup
    private static let shared = SpotijackSessionManager()
    private override init() { }

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

    //MARK: Access Control
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
    public static func establishSession(_ then: (Result<SpotijackSession>) -> ()) {
        // TODO
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
                // Update internal state
                sessionManager.pollSpotify()
                sessionManager.pollAudioHijackPro()

                completionHandler(.ok(sessionManager))
            }

            return
        }
    }
}
