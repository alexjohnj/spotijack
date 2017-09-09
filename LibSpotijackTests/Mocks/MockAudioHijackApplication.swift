//
//  MockAudioHijackApplication.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 10/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation
import ScriptingBridge
import LibSpotijack

internal class MockAudioHijackApplication: NSObject {
    var _activated: Bool = false
    var _sessions: [MockSpotijackAudioHijackApplicationSession] {
        didSet {
            _sessions.forEach { $0.parentApplication = self }
        }
    }
    var _recordings: [MockAudioHijackAudioRecording] = []

    init(sessions: [MockSpotijackAudioHijackApplicationSession]) {
        _sessions = sessions

        super.init()

        _sessions.forEach { $0.parentApplication = self }
    }
}

// MARK: - SBApplicationProtocol Conformance
extension MockAudioHijackApplication: SBApplicationProtocol {
    func activate() {
        _activated = true
    }

    var delegate: SBApplicationDelegate! {
        get {
            fatalError("Not implemented")
        }
        set(newValue) {
            fatalError("Not implemented")
        }
    }

    var isRunning: Bool {
        return true
    }

    func get() -> Any! {
        fatalError("Not implemented")
    }
}

// MARK: - AudioHijackApplication Conformance
extension MockAudioHijackApplication: AudioHijackApplication {
    func sessions() -> [AudioHijackApplicationSession] {
        return _sessions
    }
}

// MARK: - Factory Method
extension MockAudioHijackApplication {
    /// Returns a MockAudioHijackApplication with two sessions named "Spotijack" and "Not-Spotijack" respectively.
    static func makeStandardApplication() -> MockAudioHijackApplication {
        let audioHijackPro = MockAudioHijackApplication(
            sessions: [MockSpotijackAudioHijackApplicationSession(name: "Spotijack"),
                       MockSpotijackAudioHijackApplicationSession(name: "Not-Spotijack")])

        return audioHijackPro
    }
}
