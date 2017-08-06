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

extension SpotijackSessionError: LocalizedError {
    public var errorDescription: String? {
        let bundle = Constants.libSpotijackBundle

        switch self {
        case .applicationNotLaunched(let appName):
            return String(format: NSLocalizedString("ERROR_APP_NOT_LAUNCHED_DESC", bundle: bundle, comment: "{AppName} has not been launched"),
                          appName)

        case .cantStartApplication(let appName):
            return String(format: NSLocalizedString("ERROR_CANT_START_APP_DESC", bundle: bundle, comment: "Can't start {AppName}"),
                          appName)

        case .noScriptingInterface(let appName):
            return String(format: NSLocalizedString("ERROR_NO_SCRIPTING_INT_DESC", bundle: bundle, comment: "No scripting interface for {AppName}"),
                          appName)

        case .noRunningInstanceFound(let appName):
            return String(format: NSLocalizedString("ERROR_NO_RUNNING_INSTANCE_DESC", bundle: bundle, comment: "No running instance of {AppName} found."),
                          appName)

        case .couldNotCreateSpotijackSession:
            return NSLocalizedString("ERROR_CREATE_SPOTIJACK_DESC", bundle: bundle, comment: "Couldn't create Spotijack session.")

        case .spotijackSessionNotFound:
            return NSLocalizedString("ERROR_NO_SPOTIJACK_FOUND_DESC", bundle: bundle, comment: "No Spotijack session found.")
        }
    }

    public var recoverySuggestion: String? {
        let bundle = Constants.libSpotijackBundle

        switch self {
        case .applicationNotLaunched(let appName):
            return String(format: NSLocalizedString("ERROR_APP_NOT_LAUNCHED_SUGG", bundle: bundle, comment: "Try manually starting {AppName}"),
                          appName)

        case .cantStartApplication(let appName):
            return String(format: NSLocalizedString("ERROR_CANT_START_APP_SUGG", bundle: bundle, comment: "Check {AppName} is installed"),
                          appName)

        case .noScriptingInterface(let appName):
            return String(format: NSLocalizedString("ERROR_NO_SCRIPTING_INT_SUGG", bundle: bundle, comment: "Check using a version of {AppName} that supports AppleScript"),
                          appName)

        case .noRunningInstanceFound:
            return NSLocalizedString("ERROR_NO_RUNNING_INSTANCE_SUGG", bundle: bundle, comment: "table-flip")

        case .couldNotCreateSpotijackSession(let reason):
            return String(format: NSLocalizedString("ERROR_CREATE_SPOTIJACK_SUGG", bundle: bundle, comment: "This might be helpful {reason}"),
                          reason)

        case .spotijackSessionNotFound:
            return NSLocalizedString("ERROR_NO_SPOTIJACK_FOUND_SUGG", bundle: bundle, comment: "Try manually creating a session.")
        }
    }
}
