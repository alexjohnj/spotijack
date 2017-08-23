//
//  SpotijackSessionCreator.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 06/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation

public enum SpotijackSessionCreator {
    public static func createSpotijackSession() throws {
        guard let creationScriptPath = Constants.libSpotijackBundle.url(forResource: "ConfigureSpotijackSession",
                                                                        withExtension: "applescript") else {
            preconditionFailure("Spotijack session configuration script could not be loaded from the framework bundle.")
        }
        var errorInfo: NSDictionary? = [:]

        guard let script = NSAppleScript(contentsOf: creationScriptPath, error: &errorInfo) else {
            let failureReason = errorInfo?[NSAppleScript.errorMessage] as? String
                ?? "Failed to load Spotijack session configuration script."
            throw SpotijackError.CouldNotCreateSpotijackSession(reason: failureReason)
        }

        // No idea if this actually works. The docs say this method call should
        // return nil if there's a problem but the method signature says different.
        _ = script.executeAndReturnError(&errorInfo)
        if let failureReason = errorInfo?[NSAppleScript.errorMessage] as? String {
            throw SpotijackError.CouldNotCreateSpotijackSession(reason: failureReason)
        }
    }
}
