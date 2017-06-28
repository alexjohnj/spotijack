//
//  SpotijackSessionManager.swift
//  Spotijack
//
//  Created by Alex Jackson on 28/06/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Cocoa
import ScriptingBridge

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
                                  options: NSWorkspaceLaunchOptions = [.withoutActivation, .andHide]) throws -> SBApplication {
        let appLaunched = NSWorkspace.shared().launchApplication(withBundleIdentifier: bundle.identifier,
                                                                 options: options,
                                                                 additionalEventParamDescriptor: nil,
                                                                 launchIdentifier: nil)
        guard appLaunched == true else {
            throw SpotijackSessionError.cantStartApplication(name: bundle.name)
        }
        
        if let sbInterface = SBApplication(bundleIdentifier: bundle.identifier) {
            return sbInterface
        } else {
            throw SpotijackSessionError.noScriptingInterface(appName: bundle.name)
        }
        
    }
    
    /// Launches Spotify and enables scripting in the application
    private func spotify() throws -> SpotifyApplication {
        return try startApplication(fromBundle: Bundles.spotify)
    }
    
    public func audioHijack() throws -> AudioHijackApplication {
        return try startApplication(fromBundle: Bundles.audioHijack)
    }
    
    
}
