//
//  Errors.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 2017-08-02.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation

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

    /// A session named Spotijack could not be created in AHP using AppleScript.
    case couldNotCreateSpotijackSession(reason: String)
    /// Could not find a Spotijack session in AHP
    case spotijackSessionNotFound
}
