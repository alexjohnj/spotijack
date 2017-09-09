//
//  FatalError+RecoverableError.swift
//  Spotijack
//
//  Created by Alex Jackson on 07/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation
import LibSpotijack

// An Error from which the application can not continue and must terminate
internal protocol FatalError: RecoverableError { }

extension FatalError {
    public var recoveryOptions: [String] {
        return [NSLocalizedString("Quit", comment: "Terminate the application")]
    }

    public func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool {
        NSApp.terminate(self)
        return false
    }
}

extension SpotijackError.ApplicationNotLaunched: FatalError { }
extension SpotijackError.CantStartApplication: FatalError { }
extension SpotijackError.NoScriptingInterface: FatalError { }
extension SpotijackError.NoRunningInstanceFound: FatalError { }
extension SpotijackError.CouldNotCreateSpotijackSession: FatalError { }
