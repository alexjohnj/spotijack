//
//  MockSpotifyApplication.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 10/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation
import ScriptingBridge
import LibSpotijack

internal class MockSpotifyApplication: NSObject {
    var _playbackQueue: [MockSpotifyTrack]
    var _playedQueue: [MockSpotifyTrack] = []

    // Backing Properties for SpotifyApplication protocol
    var _playerState: SpotifyEPlS = .paused
    var _playerPosition: Double = 0.0
    var _repeating: Bool = false
    var _shuffling: Bool = false

    var _activated: Bool = false
    var _isRunning: Bool = true

    init(playbackQueue: [MockSpotifyTrack]) {
        self._playbackQueue = playbackQueue

        super.init()
    }
}

// MARK: - SBApplication Protocol Conformance
extension MockSpotifyApplication: SBApplicationProtocol {
    var delegate: SBApplicationDelegate! {
        get {
            fatalError("Not implemented")
        }

        set { // swiftlint:disable:this unused_setter_value
            fatalError("Not implemented")
        }
    }

    func activate() {
        _activated = true
    }

    var isRunning: Bool {
        return true
    }

    func get() -> Any! {
        return self
    }
}

// MARK: - SpotifyApplication Protocol Conformance
extension MockSpotifyApplication: SpotifySBApplication {
    // MARK: Implemented
    // There is always a current track. When the playback queue is exhausted, we drain the played queue into it.
    var currentTrack: SpotifyTrackSBObject { return _playbackQueue[0] }
    var playerState: SpotifyEPlS { return _playerState }
    var playerPosition: Double { return _playerPosition }
    var repeating: Bool { return _repeating }
    var shuffling: Bool { return _shuffling }

    func nextTrack() {
        _playedQueue.append(_playbackQueue.removeFirst())
        _playerPosition = 0.0

        // When Spotify exhausts the playback queue, it pauses playback and swaps the played queue and the playback
        // queue.
        if _playbackQueue.isEmpty {
            _playbackQueue = _playedQueue
            _playedQueue = []
            _playerState = .paused
        }
    }

    func playpause() {
        switch playerState {
        case .paused, .stopped:
            play()
        case .playing:
            pause()
        }
    }

    func pause() {
        _playerState = .paused
    }

    func play() {
        _playerState = .playing
    }

    func setPlayerPosition(_ playerPosition: Double) {
        _playerPosition = playerPosition
    }

    func setRepeating(_ repeating: Bool) {
        _repeating = repeating
    }

    func setShuffling(_ shuffling: Bool) {
        _shuffling = shuffling
    }

    // MARK: Not implemented
    var soundVolume: Int { fatalError("Not implemented") }
    var repeatingEnabled: Bool { fatalError("Not implemented") }
    var shufflingEnabled: Bool { fatalError("Not implemented") }

    func previousTrack() {
        fatalError("Not implemented")
    }

    // swiftlint:disable:next identifier_name
    func playTrack(_ x: String!, inContext: String!) {
        fatalError("Not implemented")
    }

    func setSoundVolume(_ soundVolume: Int) {
        fatalError("Not implemented")
    }
}

// MARK: - Factory Method
extension MockSpotifyApplication {
    // Creates a `MockSpotifyApplication` with three tracks in the playback queue and the player state set to paused.
    // Shuffling and repeat are disabled.
    // The three tracks (from active to last) are "Let the Flames Begin", "Fake Happy", "Outro"
    static func makeStandardApplication() -> MockSpotifyApplication {
        let spotify = MockSpotifyApplication(playbackQueue: [TestTrack.LetTheFlamesBegin,
                                                             TestTrack.FakeHappy,
                                                             TestTrack.BabesNeverDieOutro])
        spotify._playerState = .paused
        spotify._repeating = false
        spotify._shuffling = false

        return spotify
    }
}
