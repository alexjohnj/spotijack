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

public struct SpotijackSessionManager {
    public static let shared = SpotijackSessionManager()
    
    private typealias BundleInfo = (name: String, identifier: String)
    private struct Bundles {
        static let spotify: BundleInfo = ("Spotify", "com.spotify.client")
        static let audioHijack: BundleInfo = ("Audio Hijack Pro", "com.rogueamoeba.AudioHijackPro2")
    }
    
    enum SpotijackSessionError: Error {
        /// The Spotify bundle could not be found or the application failed to
        /// start for some exceptional reason.
        case cantStartApplication(name: String)
        /// Could not get an SBApplication reference to the application. Maybe
        /// it no longer supports AppleScript?
        case noScriptingInterface(appName: String)
    }
    
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
}
