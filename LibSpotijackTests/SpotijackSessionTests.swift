//
//  SpotijackSessionTests.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 10/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import XCTest
@testable import LibSpotijack

extension SpotijackSession {
    /// Makes standard mock Spotify and AHP applications and configures a new SpotijackSession to use them.
    // swiftlint:disable:next large_tuple
    static func makeStandardApplications() -> (SpotijackSession, MockSpotifyApplication, MockAudioHijackApplication) {
        let spotify = MockSpotifyApplication.makeStandardApplication()
        let ahp = MockAudioHijackApplication.makeStandardApplication()
        let session = SpotijackSession(spotifyBridge: spotify, audioHijackBridge: ahp)

        return (session, spotify, ahp)
    }
}

internal class SpotijackSessionTests: XCTestCase {
    // MARK: - Mute Tests
    func testGetSessionMuteState() {
        let expectedMuteState = true

        let (session, _, ahp) = SpotijackSession.makeStandardApplications()
        ahp._sessions.first(where: { $0._name == "Spotijack" })?._speakerMuted = expectedMuteState

        XCTAssertEqual(session.isMuted, expectedMuteState)
    }

    func testSetSessionMuteState() {
        let expectedMuteState = true
        let (session, _, ahp) = SpotijackSession.makeStandardApplications()
        let spotijackAHPSession = ahp._sessions.first(where: { $0._name == "Spotijack" })!

        session.isMuted = expectedMuteState

        XCTAssertEqual(spotijackAHPSession._speakerMuted, expectedMuteState)
    }

    func testChangeMuteStateNotifiesDelegate() {
        let expectedMuteState = true
        var receivedMuteState: Bool?

        let mockDelegate = MockSpotijackSessionDelegate()
        mockDelegate.onSessionDidMute = { (_, isMuted) in receivedMuteState = isMuted }

        let (session, _, _) = SpotijackSession.makeStandardApplications()
        session.delegate = mockDelegate

        session.isMuted = expectedMuteState

        XCTAssertEqual(expectedMuteState, receivedMuteState)
    }
}
