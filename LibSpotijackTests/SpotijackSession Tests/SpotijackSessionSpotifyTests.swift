//
//  SpotijackSessionSpotifyTests.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 10/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import XCTest
@testable import LibSpotijack

/// Tests how SpotijackSession controls Spotify's state
internal class SpotijackSessionSpotifyTests: XCTestCase {
    func testGetCurrentTrack() {
        let expectedTrack = TestTrack.LetTheFlamesBegin._backingTrack
        let (session, _, _) = SpotijackSession.makeStandardApplications()

        XCTAssertNotNil(session.currentTrack)
        XCTAssertEqual(session.currentTrack, expectedTrack)
    }

    func testChangeTrackNotifiesDelegate() {
        let expectedTrack = TestTrack.FakeHappy._backingTrack
        var receivedTrack: StaticSpotifyTrack?
        let delegate = MockSpotijackSessionDelegate()
        delegate.onSessionDidChangeToTrack = { (_, newTrack) in receivedTrack = newTrack }

        let (session, spotify, _) = SpotijackSession.makeStandardApplications()
        session.delegate = delegate

        spotify.nextTrack()

        // Simulate a polling
        session.pollSpotify()
        session.pollAudioHijackPro()

        XCTAssertNotNil(receivedTrack)
        XCTAssertEqual(receivedTrack, expectedTrack)
    }
}
