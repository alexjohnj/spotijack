//
//  SpotijackSessionCreator.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 06/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation

internal enum SpotijackSessionCreator {
    static func createSpotijackSession() throws {
        guard let creationScriptPath = Bundle(for: SpotijackSessionManager.self).url(forResource: "ConfigureSpotijackSession", withExtension: "applescript") else {
            preconditionFailure("Spotijack session configuration script could not be loaded from the framework bundle.")
        }
        var errorInfo: NSDictionary? = [:]

        guard let script = NSAppleScript(contentsOf: creationScriptPath, error: &errorInfo) else {
            let failureReason = errorInfo?[NSAppleScript.errorMessage] as? String ?? "Failed to load Spotijack session configuration script."
            throw SpotijackSessionError.couldNotCreateSpotijackSession(reason: failureReason)
        }

        // No idea if this actually works. The docs say this method call should
        // return nil if there's a problem but the method signature says different.
        let _ = script.executeAndReturnError(&errorInfo)
        if let failureReason = errorInfo?[NSAppleScript.errorMessage] as? String {
            throw SpotijackSessionError.couldNotCreateSpotijackSession(reason: failureReason)
        }
    }
}
