//
//  MockSpotijackSessionDelegate.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 10/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation
@testable import LibSpotijack

internal class MockSpotijackSessionDelegate: SpotijackSessionDelegate {
    var onSessionDidChangeToTrack: ((SpotijackSession, StaticSpotifyTrack?) -> Void)?
    var onSessionDidMute: ((SpotijackSession, Bool) -> Void)?
    var onSessionDidChangeRecordingState: ((SpotijackSession, Bool) -> Void)?
    var onSessionDidEncounterError: ((SpotijackSession, Error) -> Void)?
    var onSessionDidReachEndOfPlaybackQueue: ((SpotijackSession) -> Void)?

    func session(_ session: SpotijackSession, didChangeToTrack track: StaticSpotifyTrack?) {
        onSessionDidChangeToTrack?(session, track)
    }

    func session(_ session: SpotijackSession, didMute isMuted: Bool) {
        onSessionDidMute?(session, isMuted)
    }

    func session(_ session: SpotijackSession, didChangeRecordingState isRecording: Bool) {
        onSessionDidChangeRecordingState?(session, isRecording)
    }

    func session(_ session: SpotijackSession, didEncounterError error: Error) {
        onSessionDidEncounterError?(session, error)
    }

    func sessionDidReachEndOfPlaybackQueue(_ session: SpotijackSession) {
        onSessionDidReachEndOfPlaybackQueue?(session)
    }
}
