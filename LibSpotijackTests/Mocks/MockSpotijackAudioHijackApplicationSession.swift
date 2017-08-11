//
//  MockSpotijackAudioHijackApplicationSession.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 10/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation
import ScriptingBridge
import LibSpotijack

// swiftlint:disable:next type_name
internal class MockSpotijackAudioHijackApplicationSession: NSObject {
    weak var parentApplication: MockAudioHijackApplication?

    var _hijacked = false
    var _recording = false {
        willSet {
            if _recording == true,
                newValue == false {
                parentApplication?._recordings.append(MockAudioHijackAudioRecording(name: _titleTag, path: "C://FAKE"))
            }
        }
    }
    var _speakerMuted = false
    var _paused = false

    var _name: String

    var _albumTag = ""
    var _artistTag = ""
    var _albumArtistTag = ""
    var _trackNumberTag = ""
    var _titleTag = ""
    var _discNumberTag = ""

    init(name: String) {
        _name = name

        super.init()
    }
}

// MARK: - SBObjectProtocol
extension MockSpotijackAudioHijackApplicationSession: SBObjectProtocol {
    func get() -> Any! {
        fatalError("Not implemented")
    }
}

// MARK: - AudioHijackApplicationSession Conformance
extension MockSpotijackAudioHijackApplicationSession: AudioHijackApplicationSession {
    var hijacked: Bool { return _hijacked }
    var recording: Bool { return _recording }
    var speakerMuted: Bool { return _speakerMuted }
    var paused: Bool { return _paused }
    var name: String { return _name }

    var albumTag: String { return _albumTag }
    var artistTag: String { return _artistTag }
    var albumArtistTag: String { return _albumArtistTag }
    var trackNumberTag: String { return _trackNumberTag }
    var titleTag: String { return _titleTag }
    var discNumberTag: String { return _discNumberTag }

    func startHijackingRelaunch(_ relaunch: AudioHijackRelaunchOptions) {
        _hijacked = true
    }

    func stopHijacking() {
        _hijacked = false
    }

    func startRecording() {
        _recording = true
    }

    func stopRecording() {
        _recording = false
    }

    func pauseRecording() {
        _paused = true
    }

    func unpauseRecording() {
        _paused = false
    }

    func setSpeakerMuted(_ speakerMuted: Bool) {
        _speakerMuted = speakerMuted
    }

    func setName(_ name: String!) {
        _name = name
    }

    func setAlbumTag(_ albumTag: String!) {
        _albumTag = albumTag
    }

    func setArtistTag(_ artistTag: String!) {
        _artistTag = artistTag
    }

    func setAlbumArtistTag(_ albumArtistTag: String!) {
        _albumArtistTag = albumArtistTag
    }

    func setTrackNumberTag(_ trackNumberTag: String!) {
        _trackNumberTag = trackNumberTag
    }

    func setTitleTag(_ titleTag: String!) {
        _titleTag = titleTag
    }

    func setDiscNumberTag(_ discNumberTag: String!) {
        _discNumberTag = discNumberTag
    }
}
