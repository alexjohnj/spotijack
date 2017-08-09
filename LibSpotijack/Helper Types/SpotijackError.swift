//
//  SpotijackError.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 07/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation

public enum SpotijackError {
    static let bundle = Constants.libSpotijackBundle

    /// The application is not launched or a launch attempt has not been made
    /// yet.
    public struct ApplicationNotLaunched: LocalizedError {
        /// Human name of the application that hasn't been launched
        public let appName: String

        public var errorDescription: String? {
            return String(format: NSLocalizedString("ERROR_APP_NOT_LAUNCHED_DESC", bundle: bundle,
                                                    comment: "{AppName} has not been launched"),
                          appName)
        }

        public var recoverySuggestion: String? {
            return String(format: NSLocalizedString("ERROR_APP_NOT_LAUNCHED_SUGG", bundle: bundle,
                                                    comment: "Try manually starting {AppName}"),
                          appName)
        }
    }

    /// The application bundle could not be found.
    public struct CantStartApplication: LocalizedError {
        /// Human name of the application that can't be launched
        public let appName: String

        public var errorDescription: String? {
            return String(format: NSLocalizedString("ERROR_CANT_START_APP_DESC", bundle: bundle,
                                                    comment: "Can't start {AppName}"),
                          appName)
        }

        public var recoverySuggestion: String? {
            return String(format: NSLocalizedString("ERROR_CANT_START_APP_SUGG", bundle: bundle,
                                                    comment: "Check {AppName} is installed"),
                          appName)
        }
    }

    /// Could not get an SBApplication reference to the application. Maybe
    /// it no longer supports AppleScript?
    public struct NoScriptingInterface: LocalizedError {
        /// Human name of the targeted application
        public let appName: String

        public var errorDescription: String? {
            return String(format: NSLocalizedString("ERROR_NO_SCRIPTING_INT_DESC", bundle: bundle,
                                                    comment: "No scripting interface for {AppName}"),
                          appName)
        }

        public var recoverySuggestion: String? {
            return String(format: NSLocalizedString("ERROR_NO_SCRIPTING_INT_SUGG", bundle: bundle,
                                                    comment: ("Check using a version of {AppName} that supports " +
                                                        "AppleScript")),
                          appName)
        }
    }

    /// Could not find a running instance of the application after trying
    /// to start the application.
    public struct NoRunningInstanceFound: LocalizedError {
        /// Human name of the targeted application
        public let appName: String

        public var errorDescription: String? {
            return String(format: NSLocalizedString("ERROR_NO_RUNNING_INSTANCE_DESC", bundle: bundle,
                                                    comment: "No running instance of {AppName} found."),
                          appName)
        }

        public var recoverySuggestion: String? {
            return NSLocalizedString("ERROR_NO_RUNNING_INSTANCE_SUGG", bundle: bundle, comment: "table-flip")
        }
    }

    /// A session named Spotijack could not be created in AHP using AppleScript.
    public struct CouldNotCreateSpotijackSession: LocalizedError {
        /// Error message returned by NSAppleScript when creating the session.
        public let reason: String

        public var errorDescription: String? {
            return NSLocalizedString("ERROR_CREATE_SPOTIJACK_DESC", bundle: bundle,
                                     comment: "Couldn't create Spotijack session.")
        }

        public var recoverySuggestion: String? {
            return String(format: NSLocalizedString("ERROR_CREATE_SPOTIJACK_SUGG", bundle: bundle,
                                                    comment: "This might be helpful {reason}"),
                          reason)
        }
    }

    /// Could not find a Spotijack session in AHP
    public struct SpotijackSessionNotFound: LocalizedError {
        public var errorDescription: String? {
            return NSLocalizedString("ERROR_NO_SPOTIJACK_FOUND_DESC", bundle: bundle,
                                     comment: "No Spotijack session found.")
        }

        public var recoverySuggestion: String? {
            return NSLocalizedString("ERROR_NO_SPOTIJACK_FOUND_SUGG", bundle: bundle,
                                     comment: "Try manually creating a session.")
        }
    }
}
