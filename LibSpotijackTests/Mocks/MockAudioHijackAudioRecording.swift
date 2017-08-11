//
//  MockAudioHijackAudioRecording.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 11/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation
import LibSpotijack

internal class MockAudioHijackAudioRecording: NSObject {
    var _name: String
    var _path: String

    init(name: String, path: String) {
        _name = name
        _path = path

        super.init()
    }
}

// MARK: - SBObjectProtocol Conformance
extension MockAudioHijackAudioRecording: SBObjectProtocol {
    func get() -> Any! {
        fatalError("Not implemented")
    }
}

// MARK: - AudioHijackAudioRecording Protocol Conformance
extension MockAudioHijackAudioRecording: AudioHijackAudioRecording {
    var name: String { return _name }
    var path: String { return _path }
}
