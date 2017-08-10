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
    var _isActivated = false

    private var _hijacked = false
    private var _recording = false
    private var _speakerMuted = false
    private var _paused = false

    private var _name: String

    private var _albumTag = ""
    private var _artistTag = ""
    private var _albumArtistTag = ""
    private var _trackNumberTag = ""
    private var _titleTag = ""
    private var _discNumberTag = ""

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
        _albumArtistTag = albumTag
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
