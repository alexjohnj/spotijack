//
//  ScriptingBridgeProtocol.swift
//  Spotijack
//
//  Created by Alex Jackson on 28/06/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation
import ScriptingBridge

@objc public protocol SBObjectProtocol: NSObjectProtocol {
    func get() -> Any!
}

@objc public protocol SBApplicationProtocol: SBObjectProtocol {
    func activate()
    var delegate: SBApplicationDelegate! { get set }
    var running: Bool { @objc(isRunning) get }
}

